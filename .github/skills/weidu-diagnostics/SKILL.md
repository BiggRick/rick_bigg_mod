---
name: weidu-diagnostics
description: Add temporary, scoped WeiDU PATCH_PRINT diagnostics for an item-description rewrite. Use when diagnosing why an item's description changed during installation.
---

# WeiDU Description Diagnostics

Use this workflow to identify exactly which `REPLACE_TEXTUALLY` operation
changed a description. Limit the install component to the affected file before
adding logs, so the output is readable and no unrelated game assets are
modified.

## Scope the component

Replace a broad item scan such as:

```weidu
COPY_EXISTING_REGEXP ~^.*\.ITM$~ ~override~
```

with the affected item's exact resref:

```weidu
COPY_EXISTING ~PLAT22.ITM~ ~override~
```

Keep the component's existing patch macros beneath that `COPY_EXISTING` block.
Restore the original scope after the diagnosis is complete.

## Log the description buffer

`REPLACE_TEXTUALLY` operates on the current patch buffer. Read the complete
buffer immediately before and after the replacement being investigated, then
print it with a stage label:

```weidu
READ_ASCII 0 buffer_contents (BUFFER_LENGTH)
PATCH_PRINT ~redescribe_armor before equipped-ability section rewrite: %buffer_contents%~

REPLACE_TEXTUALLY ~^Equipped abilities:[%WNL%]*~ ~Equipped abilities:%WNL%%abilities_string%~

READ_ASCII 0 buffer_contents (BUFFER_LENGTH)
PATCH_PRINT ~redescribe_armor after equipped-ability section rewrite: %buffer_contents%~
```

For broader context, also log the buffer at function entry and after a group of
related cleanup replacements:

```weidu
READ_ASCII 0 buffer_contents (BUFFER_LENGTH)
PATCH_PRINT ~redescribe_armor initial buffer: %buffer_contents%~

REPLACE_TEXTUALLY ~^– Physical Resistance:[^%WNL%]*%WNL%~ ~~
REPLACE_TEXTUALLY ~^– Speed Factor:[^%WNL%]*%WNL%~ ~~

READ_ASCII 0 buffer_contents (BUFFER_LENGTH)
PATCH_PRINT ~redescribe_armor after equipped-ability cleanup: %buffer_contents%~
```

Use distinct labels around each suspicious replacement. Inspect the installer
output and compare the before/after buffers to determine the first operation
that removes or alters the missing line. For an existing section, preserve
unmanaged ability lines by replacing only the section header and prepending the
generated lines; do not replace the header and its first list entry. Remove the
diagnostic statements after the cause is fixed.

## Rules to apply
When you edit a TPA file to add or remove diagnostic messages or while trying to fix a problem, do *not* execute the rules:
- powershell/check-duplicates.ps1
- powershell/check-tpa-quotes.ps1

## Validate edited scripts

After editing a `.tpa` file, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\powershell\check-tpa-quotes.ps1 -Files ".\lib\item_rules.tpa", ".\lib\redescribe_armor.tpa"
```

The script verifies that WeiDU can parse the changed files and catches nested
double quotes inside double-quoted `SAY` values.

## Clean up
After you have identified the cause of the problem, remove all diagnostic statements and restore the original scope of the component.