---
name: creature-inventory-report
description: Analyze Baldur's Gate creature resources in Near Infinity XML dumps and produce an Excel workbook listing each creature's inventory, item names, and equipment slots. Use when asked to inspect CRE inventories or create an inventory report.
---

# Creature Inventory Excel Report

Use this skill when the user supplies one or more creature resrefs/files and a
directory containing Near Infinity XML dumps such as `WEREGR01.CRE.xml` and
`RINGWOLF.ITM.xml`.

## Inputs

Collect or infer:

- The directory containing the `.CRE.xml` files.
- The requested creature resrefs or filenames. A trailing destination such as
  `"override"` is not a resource name and can be omitted. Lines like
  `"weregr01.cre" "override"` are accepted as input; the extraction script
  finds the `.CRE` filename.
- The output `.xlsx` path. Use the current repository directory unless the
  user requested another location.

If the resource directory or creature list is unclear, ask the user before
proceeding. Do not silently search unrelated directories.

## Generate the report

Run these scripts from the repository root. They use Windows PowerShell and
only built-in .NET APIs; no Python, Excel installation, or additional module is
required.

```powershell
$creatures = @(
    '"weregr01.cre" "override"',
    '"weregrdr.cre" "override"',
    '"werewogr.cre" "override"',
    '"shwolf.cre" "override"',
    '"wolfgr01.cre" "override"',
    '"wolfwegr.cre" "override"'
)
$rows = & .\.github\skills\creature-inventory-report\Get-CreatureInventory.ps1 `
    -InputDirectory 'C:\path\to\game_objects_new_nomod' `
    -CreatureFiles $creatures
$rows | & .\.github\skills\creature-inventory-report\Export-CreatureInventoryExcel.ps1 `
    -OutputPath '.\creature_inventory_report.xlsx'
```

The extractor reads each requested `.CRE.xml`, correlates item records with
occupied equipment and inventory slots, and looks up identified/general names
in matching `.ITM.xml` files when present. If an item definition is absent,
its resref remains in the report as the item name. Items without a matching
slot are retained and labeled as unassigned inventory; they are not discarded.
Repeated creature filenames are included only once. Missing or malformed
requested creature files stop the report with an error.

The workbook contains:

- `Matrice` (first sheet): one row per creature and one column per distinct
  item resref. A cell lists the occupied slot(s) for that item; a blank cell
  means the creature does not carry it. The creature column and header row
  remain frozen while scrolling.
- `Dettaglio`: one row per item, with creature, item resref, display name, and
  slot.
- `Riepilogo`: one row per creature, listing its items and slots and the item
  count.

The exporter refuses to overwrite an existing output by default. Pass
`-Force` to replace it intentionally. Check the reported output path and open
the workbook to confirm both sheets contain data before reporting completion.

## Scripts

- `Get-CreatureInventory.ps1` extracts and labels items from the XML dumps.
- `Export-CreatureInventoryExcel.ps1` writes the extracted rows into an `.xlsx`
  workbook using Open XML parts and .NET ZIP support.
