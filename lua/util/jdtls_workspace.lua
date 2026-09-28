-- Ownership guard for jdtls Eclipse workspaces.
--
-- An Eclipse `-data` directory is single-instance by design. Point two jdtls
-- JVMs at the same one and they delete each other's
-- `.metadata/.plugins/org.eclipse.jdt.core/*.index` files mid-write. JDT logs
--
--   Java Index broken - will be automatically deleted to repair: ...index
--   Failed to save JDT index: Index for /<project>
--   java.io.FileNotFoundException: ...index (No such file or directory)
--
-- and the surviving DiskIndex keeps pointing at the deleted file, so the
-- project's type index stays dead for the rest of the session: your own
-- classes vanish from completion, workspace symbols and auto-import, while jar
-- and JDK types — which live in their own index files — keep resolving. Only a
-- fresh server rebuilds it, which is why restarting jdtls "fixes" it.
--
-- Nothing upstream prevents the collision. jdtls runs headless without taking
-- an instance-area lock (there is no `.metadata/.lock`), and Neovim spawns LSP
-- servers detached, so a crashed or SIGKILLed nvim leaks its jdtls and the next
-- nvim starts a second one on the same workspace.
--
-- So we do the locking ourselves. Each workspace dir carries a `.nvim-owner`
-- file naming the nvim that claimed it:
--
--   owner gone   -> orphan: kill the jdtls still holding the dir, take the dir
--   owner is us  -> reuse (same nvim, another java buffer)
--   owner alive  -> peer: take `workspace-<our pid>` instead, so two editors on
--                   one repo each get an index they exclusively own
--
-- Peer workspaces are scratch: released on exit, and garbage-collected on the
-- next start if we died before we could.

local uv = vim.uv

local M = {}

local OWNER_FILE = ".nvim-owner"

---Root of the per-project workspace/config dirs, matching the layout LazyVim's
---java extra uses (`<cache>/jdtls/<project>/{workspace,config}`).
---@param project string
---@return string
local function project_root(project)
  return vim.fn.stdpath("cache") .. "/jdtls/" .. project
end

--------------------------------------------------------------------------------
-- Process probing
--------------------------------------------------------------------------------

---Is `pid` a live nvim? Signal 0 only proves *something* holds the pid, and pids
---get recycled, so confirm the command name too before treating an owner as
---alive (a false "alive" costs a needless peer workspace; a false "dead" would
---kill a running editor's language server, which is far worse).
---@param pid integer
---@return boolean
local function nvim_alive(pid)
  if not pid or pid <= 0 then
    return false
  end
  if not uv.kill(pid, 0) then
    return false
  end
  local out = vim.system({ "ps", "-p", tostring(pid), "-o", "comm=" }, { text = true }):wait()
  return out.code == 0 and out.stdout:lower():find("nvim", 1, true) ~= nil
end

---Is this command line's argv[0] a JVM?
---
---The decisive guard against killing the wrong process. A shell, grep or editor
---whose *arguments* quote a jdtls command line passes every substring test
---below — but its argv[0] is `/bin/zsh`, not a JVM. Two spellings occur:
---Mason's launcher execs java with the first `-D` flag as argv[0]
---(`-Djdk.xml.maxGeneralEntitySizeLimit=0`), while a plain `java -jar ...`
---leaves the interpreter path there.
---@param cmd string
---@return boolean
local function jvm_argv0(cmd)
  local argv0 = cmd:match("^(%S+)")
  return argv0 ~= nil and (argv0:match("/java$") ~= nil or argv0 == "java" or argv0:sub(1, 2) == "-D")
end

---Every live jdtls JVM, as `{ pid = integer, data = string }`.
---
---`-data` is compared as a whole argument by callers rather than by substring,
---so the primary `.../workspace` never matches a peer's `.../workspace-51773`.
---@return { pid: integer, data: string }[]
local function scan()
  local out = vim.system({ "ps", "-axo", "pid=,command=" }, { text = true }):wait()
  if out.code ~= 0 then
    return {}
  end

  local found = {}
  for line in (out.stdout or ""):gmatch("[^\n]+") do
    local pid, cmd = line:match("^%s*(%d+)%s+(.*)$")
    -- Require the launcher jar *and* the application id, not just the product
    -- string: this list feeds SIGKILL, so a loose match is a foot-gun.
    if
      pid
      and jvm_argv0(cmd)
      and cmd:find("org.eclipse.equinox.launcher", 1, true)
      and cmd:find("org.eclipse.jdt.ls.core.id1", 1, true)
    then
      -- Workspace paths live under stdpath("cache") and contain no spaces, so a
      -- non-greedy token match is enough to isolate the argument.
      found[#found + 1] = { pid = tonumber(pid), data = cmd:match("%-data%s+(%S+)") or "<unknown>" }
    end
  end
  return found
end

---Pids of every jdtls JVM whose `-data` argument is exactly `data_dir`.
---@param data_dir string
---@return integer[]
function M.holders(data_dir)
  local pids = {}
  for _, proc in ipairs(scan()) do
    if proc.data == data_dir then
      pids[#pids + 1] = proc.pid
    end
  end
  return pids
end

---SIGTERM, then SIGKILL whatever is left, for every jdtls holding `data_dir`.
---@param data_dir string
---@return integer count how many processes were reaped
local function reap(data_dir)
  local pids = M.holders(data_dir)
  if #pids == 0 then
    return 0
  end

  for _, pid in ipairs(pids) do
    uv.kill(pid, "sigterm")
  end
  -- Give Equinox room to unwind before resorting to SIGKILL. A hard kill leaves
  -- the workspace dirty, and Eclipse's recovery from that is expensive: the
  -- next start logs "exited with unsaved changes in the previous session", runs
  -- a recovery build that holds the org.eclipse.buildship.core bundle's
  -- state-change lock, and blocks Gradle init behind it in 30-second timeouts —
  -- a server that looks like it never starts. Costs nothing when the process
  -- already exited, which is the normal case.
  vim.wait(5000, function()
    return #M.holders(data_dir) == 0
  end, 100)
  for _, pid in ipairs(M.holders(data_dir)) do
    uv.kill(pid, "sigkill")
  end

  return #pids
end

--------------------------------------------------------------------------------
-- Ownership
--------------------------------------------------------------------------------

---@param dir string
---@return integer|nil pid
local function read_owner(dir)
  local file = io.open(dir .. "/" .. OWNER_FILE, "r")
  if not file then
    return nil
  end
  local body = file:read("*a")
  file:close()
  local ok, decoded = pcall(vim.json.decode, body or "")
  return ok and type(decoded) == "table" and tonumber(decoded.nvim_pid) or nil
end

---@param dir string
local function write_owner(dir)
  vim.fn.mkdir(dir, "p")
  local file = io.open(dir .. "/" .. OWNER_FILE, "w")
  if not file then
    return
  end
  file:write(vim.json.encode({ nvim_pid = vim.fn.getpid(), claimed = os.time() }))
  file:close()
end

---Remove peer workspaces whose owning nvim is gone. Bounded work: one scandir
---of the project root, only on a fresh claim.
---@param project string
local function sweep_peers(project)
  local root = project_root(project)
  local dir = uv.fs_scandir(root)
  while dir do
    local name = uv.fs_scandir_next(dir)
    if not name then
      break
    end
    local pid = name:match("^workspace%-(%d+)$")
    if pid and tonumber(pid) ~= vim.fn.getpid() and not nvim_alive(tonumber(pid)) then
      reap(root .. "/" .. name)
      vim.fn.delete(root .. "/" .. name, "rf")
      vim.fn.delete(root .. "/config-" .. pid, "rf")
    end
  end
end

--------------------------------------------------------------------------------
-- Resolution
--------------------------------------------------------------------------------

---@class util.jdtls_workspace.Claim
---@field workspace string
---@field config string
---@field peer boolean true when we fell back to a per-instance workspace

local claims = {} ---@type table<string, util.jdtls_workspace.Claim>

---Workspace and config dirs this nvim may safely use for `project`.
---
---Memoized: the extra's `full_cmd()` runs on every java buffer, and claiming is
---not something to redo (or re-reap) per buffer.
---@param project string
---@return util.jdtls_workspace.Claim
function M.claim(project)
  if claims[project] then
    return claims[project]
  end

  local root = project_root(project)
  local primary = root .. "/workspace"
  local owner = read_owner(primary)
  local me = vim.fn.getpid()

  local mine = owner == me -- our own server, from a claim this session already made
  local claim ---@type util.jdtls_workspace.Claim
  if owner ~= nil and not mine and nvim_alive(owner) then
    -- Another live nvim owns the shared workspace. Take our own so neither
    -- index gets corrupted; costs one cold index for this instance.
    claim = { workspace = root .. "/workspace-" .. me, config = root .. "/config-" .. me, peer = true }
    vim.notify(
      ("jdtls: %s is in use by nvim %d — using a private workspace for this instance"):format(project, owner),
      vim.log.levels.INFO
    )
  else
    claim = { workspace = primary, config = root .. "/config", peer = false }
  end

  -- Reap before claiming, not just when the owner file names a dead editor.
  -- A missing owner file does NOT mean the dir is free: nvim spawns jdtls
  -- detached, and a server busy indexing can outlive both its editor's exit and
  -- the release() below — leaving a live server with no owner. Whatever still
  -- holds a dir we are entitled to take is by definition an orphan, so kill it
  -- rather than start a second JVM on the same index files.
  if not mine then
    local reaped = reap(claim.workspace)
    if reaped > 0 then
      vim.notify(
        ("jdtls: reaped %d orphaned server(s) holding %s"):format(reaped, vim.fn.fnamemodify(claim.workspace, ":~")),
        vim.log.levels.INFO
      )
    end
  end

  write_owner(claim.workspace)
  sweep_peers(project)

  claims[project] = claim
  return claim
end

---Give up every workspace we claimed. Called from VimLeavePre.
function M.release()
  for _, claim in pairs(claims) do
    -- Reap unconditionally, primary included. The caller has already asked the
    -- clients to stop, but jdtls is detached and a server mid-index can ignore
    -- the stdin EOF and outlive us — which is precisely how a workspace ends up
    -- held by a server no editor owns. No-op (and no wait) when it did exit.
    reap(claim.workspace)
    vim.fn.delete(claim.workspace .. "/" .. OWNER_FILE)
    if claim.peer then
      -- Scratch workspace: nothing in it is worth keeping, and leaving it would
      -- accumulate a stale index per crashed instance.
      vim.fn.delete(claim.workspace, "rf")
      vim.fn.delete(claim.config, "rf")
    end
  end
  claims = {}
end

--------------------------------------------------------------------------------
-- :JdtlsDoctor
--------------------------------------------------------------------------------

---Every live jdtls on this machine, keyed by its `-data` dir.
---@return table<string, integer[]>
local function all_servers()
  local by_data = {} ---@type table<string, integer[]>
  for _, proc in ipairs(scan()) do
    by_data[proc.data] = by_data[proc.data] or {}
    table.insert(by_data[proc.data], proc.pid)
  end
  return by_data
end

---Health counters from a workspace's Eclipse log.
---
---`index` counts the corruption this module exists to prevent. `wedged` counts
---the other failure mode: a workspace left dirty by a hard kill, whose recovery
---build deadlocks Buildship's bundle activation in 30s timeouts and makes the
---server look like it never starts. Both are cured by deleting the workspace.
---@param workspace string
---@return { index: integer, wedged: integer }|nil nil when there is no log yet
local function log_health(workspace)
  local log = workspace .. "/.metadata/.log"
  if not uv.fs_stat(log) then
    return nil
  end
  local health = { index = 0, wedged = 0 }
  for line in io.lines(log) do
    if line:find("Failed to save JDT index", 1, true) or line:find("Java Index broken", 1, true) then
      health.index = health.index + 1
    elseif line:find("timed out waiting", 1, true) or line:find("Unable to acquire the state change lock", 1, true) then
      health.wedged = health.wedged + 1
    end
  end
  return health
end

function M.doctor()
  local lines = { "# jdtls doctor", "" }

  local clients = vim.lsp.get_clients({ name = "jdtls" })
  if #clients == 0 then
    lines[#lines + 1] = "No jdtls client attached to this buffer's session."
  end
  for _, client in ipairs(clients) do
    local cmd = type(client.config.cmd) == "table" and table.concat(client.config.cmd, " ") or "<function>"
    local data = cmd:match("%-data%s+(%S+)")
    lines[#lines + 1] = ("client %d  root_dir=%s"):format(client.id, client.config.root_dir or "?")
    lines[#lines + 1] = ("            -data=%s"):format(data or "?")
    if data then
      local health = log_health(data)
      if not health then
        lines[#lines + 1] = "            .metadata/.log: <none yet>"
      else
        lines[#lines + 1] = ("            index corruption: %d   wedged-startup: %d"):format(
          health.index,
          health.wedged
        )
        if health.index > 0 or health.wedged > 0 then
          lines[#lines + 1] = ("            -> stale workspace; fix with: rm -rf %s"):format(
            vim.fn.fnamemodify(vim.fs.dirname(data), ":~")
          )
        end
      end
    end
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "Live jdtls processes:"
  local any = false
  for data, pids in pairs(all_servers()) do
    any = true
    local flag = #pids > 1 and "  <-- CONFLICT: shared -data, indexes will corrupt" or ""
    lines[#lines + 1] = ("  %s  pid=%s%s"):format(vim.fn.fnamemodify(data, ":~"), table.concat(pids, ","), flag)
  end
  if not any then
    lines[#lines + 1] = "  (none)"
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "jdtls doctor" })
end

return M
