---
name: create-spell-icons
description: Create Baldur's Gate II spell icon BMPs, convert them to BAMs with the repository's Python tools, and copy the generated BAMs into the mod. Use when asked to create spell icons or BAMs for a spell code.
---

# Create Spell Icons

Create the four BMP inputs expected by the Python BAM converters, convert them to BAM files,
and copy the resulting spell BAMs into this mod's `copy` directory.

## Locate the game assets

The repository's `tools\bam_batcher` asset tree is explicitly in scope for this
skill. Do not repeatedly ask for permission before reading, writing, or
running tools against those paths. The BMP-to-BAM conversion is implemented by
the repository scripts
`tools\bam_batcher\make_spell_bam.py` and
`tools\bam_batcher\make_inventory_bam.py`; do not download or install another
converter.

## Collect and validate inputs

The request must provide:

- spell name or visual subject;
- one icon color:
  - `blue` for buffs or healing;
  - `red` for damage or debuffs;
  - `green` for summons;
  - `white` for divination or generalist spells;
- a spell code such as `SPWI112`.

Normalize the spell code to uppercase and reject it unless it matches
`^[A-Z]{4}[0-9]{3}$`. Use the normalized code in every output filename.

Run from the repository root and verify the game directory layout before
changing anything:

```powershell
if (-not (Test-Path '.\tools\bam_batcher' -PathType Container)) {
    throw "Expected .\tools\bam_batcher to be a directory."
}
foreach ($subdir in 'invsmall', 'invlarge', 'spell', 'bam') {
    if (-not (Test-Path ".\tools\bam_batcher\$subdir" -PathType Container)) {
        throw "Missing .\tools\bam_batcher\$subdir directory."
    }
}
$templates = @(
    '.\tools\bam_batcher\invsmall\SPWI110AS.BMP',
    '.\tools\bam_batcher\invlarge\SPWI110AL.BMP',
    '.\tools\bam_batcher\spell\SPWI110B.BMP',
    '.\tools\bam_batcher\spell\SPWI110C.BMP'
)
foreach ($template in $templates) {
    if (-not (Test-Path $template -PathType Leaf)) {
        throw "Missing required SPWI110 source file: $template"
    }
    if (-not ((Get-Item $template).IsReadOnly)) {
        throw "SPWI110 source file must be read-only: $template"
    }
}
$greenExamples = @(
    '.\tools\bam_batcher\invsmall\SPWI423AS.BMP',
    '.\tools\bam_batcher\invlarge\SPWI423AL.BMP',
    '.\tools\bam_batcher\spell\SPWI423B.BMP',
    '.\tools\bam_batcher\spell\SPWI423C.BMP'
)
foreach ($example in $greenExamples) {
    if (-not (Test-Path $example -PathType Leaf)) {
        throw "Missing required green reference file: $example"
    }
}
```

Do not silently create or substitute the required `tools\bam_batcher` directory or
source templates. Do not modify the read-only `SPWI110` source files. Surface
the error if any required path is absent, has the wrong type, or is not
read-only.

## Draw the icon

Create a simple, monochrome pixel-art icon no larger than 32x32 pixels. Use a
clear silhouette, hard-edged pixels, and one shade of the requested color
family, with at most a small number of darker or lighter values only when
needed to make the silhouette legible. Do not attempt detailed or
multicolored artwork: the 32x32 canvas has very limited visual resolution.
The top-left pixel must be exactly `#00ff00`; this is the transparent color
used by the game and must remain unchanged in every icon BMP.

Use an indexed/paletted BMP compatible with the Python BAM converters. Preserve or create a
palette entry for `#00ff00`, and verify the actual pixel at `(0, 0)` after
saving. Do not use antialiasing, smoothing, alpha transparency, or an
uncontrolled true-color export. If a drawing tool is unavailable, use an
existing image tool or a small local script with an installed image library;
do not download assets or contact external services.

## Examples

Use the matching existing spell assets as the visual and palette reference:

| Spell color | Reference files |
|---|---|
| `white` | `tools\bam_batcher\invsmall\SPWI110AS.BMP`, `tools\bam_batcher\invlarge\SPWI110AL.BMP`, `tools\bam_batcher\spell\SPWI110B.BMP`, and `tools\bam_batcher\spell\SPWI110C.BMP` |
| `green` | `tools\bam_batcher\invsmall\SPWI423AS.BMP`, `tools\bam_batcher\invlarge\SPWI423AL.BMP`, `tools\bam_batcher\spell\SPWI423B.BMP`, and `tools\bam_batcher\spell\SPWI423C.BMP` |
| `blue` | `TBD` |
| `red` | `TBD` |

Copy both the reference's visual style and its indexed color palette for the
requested color. The BMP background/transparent area must be exactly
`#00FF00`, including the top-left pixel, but the drawn spell icon itself must
not use `#00FF00`; use the non-transparent colors from the selected reference
palette instead. Do not treat the green reference for summon spells as a
request to draw the icon in the transparent green color.

For green spells, use the `SPWI423*` files as the source for the palette and
canvas style. For white spells, use `SPWI110*`. Keep both sets of source files
unchanged and read-only.

The four required inputs are:

| Destination | File | Content |
|---|---|---|
| `tools\bam_batcher\invsmall` | `<CODE>AS.BMP` | A copy of the existing `SPWI110AS.BMP`; do not redraw it. |
| `tools\bam_batcher\invlarge` | `<CODE>AL.BMP` | The existing `BLANK_SCROLL.BMP` canvas with the image on top; this produces the `A` BAM. |
| `tools\bam_batcher\spell` | `<CODE>C.BMP` | The new spell icon alone. |
| `tools\bam_batcher\spell` | `<CODE>B.BMP` | The spell code rendered or represented with a small amount of gray background, following the existing `SPWI110B.BMP` layout. |

Inspect the example files before editing them so dimensions, indexed palettes,
and canvas bounds are retained. Never overwrite the `SPWI110` source
templates. The `AS` file must be copied byte-for-byte from `SPWI110AS.BMP`.
For `B.BMP`, clear the entire existing gray-area artwork before drawing the
`C.BMP` icon over the gray background. For `AL.BMP`, start from
`BLANK_SCROLL.BMP` and preserve its complete scroll background, then draw the
`C.BMP` icon over it. Do not replace the scroll with a blank transparent
canvas.

Copy the small inventory template explicitly:

```powershell
Copy-Item .\tools\bam_batcher\invsmall\SPWI110AS.BMP `
    .\tools\bam_batcher\invsmall\<CODE>AS.BMP
```

Use the spell name and requested color to choose one clear, recognizable
monochrome silhouette for `C.BMP`. Create `B.BMP` from the selected reference
canvas, remove all existing elements from its gray area, and draw the `C.BMP`
icon on top of that gray area. Create `AL.BMP` from the selected reference
canvas, preserve the scroll background, and draw the same simplified `C.BMP`
icon on top of it. Do not put readable UI text or extra detailed artwork
outside the available bitmap area.

After writing the files, verify all four exist, are BMPs, are at most 32x32
pixels where applicable, and have the required green top-left pixel. If the
scroll template is larger than 32x32, retain its original template dimensions;
the 32x32 limit applies to the drawn spell icon, not the surrounding scroll
asset.

## Convert BMPs to BAMs

```powershell
python .\tools\bam_batcher\make_spell_bam.py `
    --input-dir .\tools\bam_batcher\spell `
    --output-dir .\tools\bam_batcher\bam `
    --template .\tools\bam_batcher\hdr-spl.bam

if ($LASTEXITCODE -ne 0) { throw "Spell BMP-to-BAM conversion failed." }

python .\tools\bam_batcher\make_inventory_bam.py `
    --large-dir .\tools\bam_batcher\invlarge `
    --small-dir .\tools\bam_batcher\invsmall `
    --output-dir .\tools\bam_batcher\bam `
    --template .\tools\bam_batcher\hdr-inv.bam

if ($LASTEXITCODE -ne 0) { throw "Inventory BMP-to-BAM conversion failed." }
```

Run both commands from the repository root. The spell converter processes BMPs
from `.\tools\bam_batcher\spell`; the inventory converter pairs `*L.BMP` files
in `.\tools\bam_batcher\invlarge` with matching `*S.BMP` files in
`.\tools\bam_batcher\invsmall`. Do not continue to the copy step after either
command fails.

## Copy generated BAMs

From the repository root, copy only the generated files matching the requested
spell code:

```powershell
$code = 'SPWI112' # replace with the normalized requested code
$bamFiles = @(Get-ChildItem ".\tools\bam_batcher\bam\$code*.BAM" -File)
if ($bamFiles.Count -eq 0) {
    throw "No generated BAMs found for $code."
}
Copy-Item $bamFiles.FullName (Join-Path (Get-Location) 'copy') -Force
```

Confirm that `.\copy\<CODE>*.BAM` exists after copying. Do not copy unrelated
BAMs, installer backups, or the BMP inputs.
