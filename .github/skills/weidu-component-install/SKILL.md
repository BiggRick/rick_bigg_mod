---
name: weidu-component-install
description: Install one or more Rick & Bigg Mod components into a Baldur's Gate II game and inspect WeiDU failures. Use when asked to install or test a component.
---

# Install a Mod Component

Install from the game directory, not the mod source directory. Find the parent
folder that contains `chitin.key`; this is the game directory and must also
contain `setup-rick_bigg_mod.exe`.

Run the requested component numbers with one `--force-install` argument per
component:

```powershell
.\setup-rick_bigg_mod.exe --force-install 300 --force-install 100
```

After the command exits, check its return code. In PowerShell, inspect
`$LASTEXITCODE`; zero indicates success and a nonzero code indicates an install
failure.

```powershell
.\setup-rick_bigg_mod.exe --force-install 300 --force-install 100
$LASTEXITCODE
```

Read `setup-rick_bigg_mod.debug` in the same directory as `chitin.key` and the
installer, regardless of whether the return code is zero. For a failed install,
use the final `ERROR`, `WARNING`, and relevant `PATCH_PRINT` entries to locate
the failing patch or unexpected description buffer.

```powershell
Get-Content .\setup-rick_bigg_mod.debug -Tail 200
```

For a diagnostic install, use the smallest component that exercises the
changed script. Component `300` is the focused item-rules test component.
