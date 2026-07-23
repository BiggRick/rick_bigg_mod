# Installing a WeiDU Component: Process Guide

## Overview
This guide documents the process for installing a WeiDU component from a WeiDU mod installer (e.g., `setup-rick_bigg_mod.exe`).

## Prerequisites
- WeiDU installer executable (`setup-{modname}.exe`)
- Game installation directory containing:
  - `chitin.key` (game key file)
  - `weidu.log` (WeiDU installation log)
  - `dialog.tlk` (dialogue file)
  - `override/` directory (where mod files get copied)

## Installation Process

### Step 1: Identify the Component Number
- Open the installer or check the `.tp2` file to find the component number
- Component numbers are defined as `BEGIN` blocks in the `.tp2` file
- Example: Component 300 = `BEGIN ~Test Weapon Rules~`

### Step 2: Run the Installer with Component Flag
```powershell
cd "path\to\game\installation"
.\setup-{modname}.exe --force-install {component_number}
```

**Parameters:**
- `--force-install {number}`: Forces installation of a specific component without prompts
- `{component_number}`: Integer identifier of the component to install

### Step 3: Monitor Installation Output
The installer will output:
- **File operations:** Number of files being copied/patched
- **Progress:** Files copied count
- **Status:** SUCCESS or ERROR messages
- **Exit code:** 0 (success) or non-zero (failure)

### Step 4: Check Results
```powershell
echo "Exit Code: $LASTEXITCODE"
```

**Expected on Success:**
- Exit Code: 0
- Message: `SUCCESSFULLY INSTALLED {Component Name}`
- Files copied to `override/` directory

**Expected on Failure:**
- Exit Code: 2
- ERROR message with details (patching failure, missing dependencies, regex errors, etc.)
- Automatic rollback of partially installed files
- Previous state restored

## Example Output

### ✅ Successful Installation
```
Installing [Component Name] [version]
Copying and patching X files ...
SUCCESSFULLY INSTALLED Component Name
Exit Code: 0
```

### ❌ Failed Installation
```
Installing [Component Name] [version]
Copying and patching X files ...
ERROR: [FILE.ITM] -> [override/FILE.ITM] Patching Failed (COPY) (Failure("..."))
Stopping installation because of error.
ERROR Installing [Component Name], rolling back to previous state
Will uninstall X files...
Uninstalled X files...
NOT INSTALLED DUE TO ERRORS Component Name
Exit Code: 2
```

## Troubleshooting Failed Installations

When an installation fails (Exit Code: 2):

1. **Check the error message** - identifies which file and operation failed
2. **Review SETUP-{MODNAME}.DEBUG** - WeiDU debug log with detailed error information
3. **Common error types:**
   - **Patching regex errors:** Unmatched parentheses or invalid regex patterns
   - **File not found:** COPY source file doesn't exist
   - **Dependency error:** Required mod not installed
   - **Uninstall errors:** Can't overwrite existing installation

4. **Resolution:** Fix the underlying issue in the mod code (`.tpa` or `.tp2` files), then retry installation

## WeiDU Component Anatomy

A typical WeiDU component in `rick_bigg_mod.tp2`:
```
BEGIN ~Component Display Name~
  LABEL ~unique_label~
  
  // Uninstall existing version
  ACTION_UNINSTALL_PATCH
  
  // Include modular .tpa files
  INCLUDE ~%MOD_FOLDER%/lib/rick_bigg_mod.tpa~
  
  // Copy and patch game files
  COPY ~copy/file.itm~ ~override/file.itm~
    PATCH_IF (1) BEGIN
      // patch logic
    END
```

## Key WeiDU Files for rick_bigg_mod

- **rick_bigg_mod.tp2** - Main installer manifest with component definitions
- **lib/rick_bigg_mod.tpa** - Aggregator that includes all modular .tpa files
- **lib/*.tpa** - Modular include scripts (items.tpa, spells.tpa, armor.tpa, etc.)
- **copy/** - Game asset files to be copied to override/
- **lang/en_us/dialog.tlk** - Translated strings for mod
- **weidu.log** - Installation history log (updated after each install)

## Checking Installation Status

After installation, verify:
```powershell
# Check if mod was installed
Get-Content "weidu.log" | Select-String "rick_bigg_mod"

# Check override folder for copied files
Get-ChildItem "override/" | Measure-Object  # Count files
```

## Summary

| Phase | Task | Command | Success Exit Code |
|-------|------|---------|-------------------|
| Pre-Install | Identify component | Read `.tp2` file | N/A |
| Install | Run installer | `setup-*.exe --force-install {num}` | 0 |
| Verify | Check log | `Get-Content weidu.log` | 0 |
| Debug (if needed) | Review error | Check `SETUP-*.DEBUG` | 2 (error expected) |
