# jdtls + java-test: the ASM 9.9 bundle workaround

## What breaks without it

Java test commands silently disappear. `<leader>tr` / `<leader>tt` report:

> No LSP client found that supports resolving possible test cases. Did you add the
> JAR files of vscode-java-test to `config.init_options.bundles`?

and `executeCommandProvider.commands` is missing `vscode.java.test.findTestTypesAndMethods`,
`vscode.java.test.junit.argument`, `vscode.java.test.search.codelens`.

## Cause

An unsatisfiable OSGi version constraint between two Mason packages:

| component | version | ASM |
| --- | --- | --- |
| jdtls | `org.eclipse.jdt.ls.core_1.60.0` | **ships 9.10.1** |
| `com.microsoft.java.test.plugin` | 0.43.1 | `Require-Bundle: org.objectweb.asm;bundle-version="[9.9.0,9.10.0)"` |
| `org.jacoco.core` | 0.8.14 | `Import-Package: org.objectweb.asm{,.commons,.tree};version="[9.9.0,9.10)"` |

9.10.1 is outside both ranges, so `com.microsoft.java.test.plugin` and `org.jacoco.core`
fail to resolve and never register their LSP commands. jacoco needs all three packages
(`asm`, `asm.commons`, `asm.tree`), which is why one jar isn't enough.

## Fix

`lua/plugins/java.lua` (`asm_bundles()`) downloads ASM 9.9 from Maven Central into
`~/.local/share/nvim/jdtls-asm-bundles/` and appends the three jars to
`init_options.bundles`. OSGi hosts 9.9 and 9.10.1 side by side, wiring each consumer to
the version matching its range. No manifest patching is needed.

`bundles()` must also drop `com.microsoft.java.test.runner-jar-with-dependencies.jar` and
`jacocoagent.jar` — neither is a valid OSGi bundle, and including either aborts the entire
bundle load rather than just its own.

## Equinox caches this, in a Mason-owned directory

Adding the jars alone historically did *not* fix it. Equinox persists bundle state,
including failed resolutions, in its **configuration area** — and jdtls's launcher, when
given no `-configuration`, defaults that to the install directory:

```
~/.local/share/nvim/mason/packages/jdtls/configuration/org.eclipse.osgi/
```

Cached bundles start before `init_options.bundles` is processed, so new bundles cannot
rescue an already-poisoned cache.

Since 2026-08-28 java.lua delegates the command line to LazyVim's `lang.java` extra, which
passes a per-project `-configuration ~/.cache/nvim/jdtls/<project>/config`. The OSGi state
is therefore no longer inside a Mason-managed directory, and `:MasonUpdate jdtls` no longer
destroys it. Before that change the fix had to be re-applied by hand after every update.

## Externally-supplied bundles need two starts

Discovered 2026-08-28 while rebuilding the config area from scratch.

On the **first** jdtls start against an empty configuration area, Equinox computes its
resolution snapshot before the jars from `init_options.bundles` are available, so
`com.microsoft.java.test.plugin` and `org.jacoco.core` both fail with
`Could not resolve module`. On the **second** start they resolve cleanly and the
`vscode.java.test.*` commands appear. Verified: cold start -> commands absent; restart ->
commands present; third start -> still present, 0 unresolved modules.

So after any config-area wipe, **quit and reopen nvim once**. A first-run failure is not a
regression.

This also explains why the pre-2026-08-28 setup appeared healthy: it had been restarted
many times against a long-lived config area in the Mason install dir. Its working state was
never reproducible from scratch — it depended on a persisted wiring that any
`:MasonUpdate jdtls` would have destroyed.

It also corrects a note in the original writeup, which dismissed the junit-jupiter 5/6
"uses constraint violation" as a stale-cache red herring. It is not: it is exactly what a
cold start reports, and it clears on the second start like the ASM failure does.

### Do not "fix" it by trimming the JUnit 6 jars

Tempting, since the violation is between `junit-jupiter-api` 5.14.3 and 6.0.1. It does not
work: `com.microsoft.java.test.plugin` has `Require-Bundle: org.eclipse.jdt.junit6.runtime`,
and that bundle in turn requires `junit-jupiter-{api,engine,params}` and
`junit-platform-*` at `[6.0.0,7.0.0)`. Dropping the 6.x jars just moves the failure to
`Unresolved requirement: Require-Bundle: org.eclipse.jdt.junit6.runtime` (verified).

Pass the full 27-jar set that upstream's `package.json` `contributes.javaExtensions`
declares — which is every jar in `server/` except `com.microsoft.java.test.runner-jar-with-dependencies.jar`
and `jacocoagent.jar` — and let the second start sort it out.

## If it regresses anyway

```sh
rm -rf ~/.local/share/nvim/mason/packages/jdtls/configuration/org.eclipse.osgi
rm -rf ~/.cache/nvim/jdtls
```

then reopen a Java file **twice** (see the two-start note above) and confirm:

```vim
:lua =vim.lsp.get_clients({name="jdtls"})[1].server_capabilities.executeCommandProvider.commands
:lua =require("dap").adapters.java   " must be non-nil, or tests find but never launch
```

**Beware a false pass.** Once Equinox has cached ASM 9.9 as a bundle, removing the
workaround and restarting still appears to work — the cached bundle is reused without
consulting `init_options.bundles`. Any test of "do we still need this?" must wipe the
configuration area first.

## Is it still needed?

Re-verified **2026-08-28**: yes. Ranges read from the JAR manifests are unchanged, and the
Mason registry snapshot (`2026-08-28-retail-north`) still resolves
`java-test -> vscode-java-test@0.45.0` and `jdtls -> eclipse.jdt.ls@v1.60.0` — the same
pair. Neither a Mason update nor a version bump removes the need.

Drop `asm_bundles()` once java-test ships a plugin accepting jdtls's ASM version (upstream
`com.microsoft.java.test.plugin` widening its `Require-Bundle` range), or once jdtls ships
ASM 9.9.x again.

---
*Originally debugged 2026-07-07; condensed from JDTLS_TEST_PROBLEM.md on 2026-08-28.*
