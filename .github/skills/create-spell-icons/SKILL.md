---
name: create-spell-icons
description: Create or accept a Baldur's Gate II spell icon GIF, generate the A/B/C BAMs with the bundled Near Infinity converter, and save them in the BAM batcher output directory. Use when asked to create spell icons or BAMs for a spell code.
---

# Create Spell Icons

Create the four GIF inputs expected by the Near Infinity BAM converter, save the
resulting spell BAMs in `tools\bam_batcher\bam`, and copy them into `copy`.

## Locate the game assets

The repository's `tools\bam_batcher` asset tree is explicitly in scope for this
skill. Do not repeatedly ask for permission before reading, writing, or
running tools against those paths.

## Collect and validate inputs

The request must provide either:

- spell name or visual subject;
- one icon color:
  - `blue` for buffs or healing;
  - `red` for damage or debuffs;
  - `green` for summons;
  - `white` for divination or generalist spells;
- a spell code such as `SPWI112`.

Alternatively, the user may provide an existing B or C GIF icon. In that mode,
the icon replaces the spell name and color requirements; the spell code is
still required.

Normalize the spell code to uppercase and reject it unless it matches
`^[A-Z]{4}[0-9]{3}$`. Use the normalized code in every output filename.

Run from the repository root and verify the game directory layout before
changing anything:

```powershell
if (-not (Test-Path '.\tools\bam_batcher' -PathType Container)) {
    throw "Expected .\tools\bam_batcher to be a directory."
}
if (-not (Test-Path '.\copy' -PathType Container)) {
    throw "Expected .\copy to be a directory."
}
foreach ($subdir in 'invsmall', 'invlarge', 'spell', 'bam') {
    if (-not (Test-Path ".\tools\bam_batcher\$subdir" -PathType Container)) {
        throw "Missing .\tools\bam_batcher\$subdir directory."
    }
}
$templates = @(
    '.\tools\bam_batcher\invsmall\SPWI110AS.GIF',
    '.\tools\bam_batcher\invlarge\SPWI110AL.GIF',
    '.\tools\bam_batcher\spell\SPWI110B.GIF',
    '.\tools\bam_batcher\spell\SPWI110C.GIF'
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
    '.\tools\bam_batcher\invsmall\SPWI423AS.GIF',
    '.\tools\bam_batcher\invlarge\SPWI423AL.GIF',
    '.\tools\bam_batcher\spell\SPWI423B.GIF',
    '.\tools\bam_batcher\spell\SPWI423C.GIF'
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

## Start from a user-provided B/C icon

When the user provides an existing `B.GIF` or `C.GIF`, accept either name as
the source icon instead of drawing a new silhouette. The two files are
identical for this workflow. Validate that the supplied file is a GIF with the
same indexed canvas, transparent top-left pixel, and dimensions required by
the selected `BLANK_SCROLL.GIF`; do not silently resize, re-quantize, or
redraw it.

Use the supplied file to create both spell inputs, then create the inventory
inputs from it:

```powershell
$code = '<CODE>'.ToUpperInvariant()
$icon = 'C:\path\provided-by-user\B.GIF' # C.GIF is also accepted
$spellDir = '.\tools\bam_batcher\spell'
Copy-Item -LiteralPath $icon -Destination (Join-Path $spellDir "$code`C.GIF")
Copy-Item -LiteralPath (Join-Path $spellDir "$code`C.GIF") `
    -Destination (Join-Path $spellDir "$code`B.GIF")
Copy-Item .\tools\bam_batcher\invsmall\SPWI110AS.GIF `
    .\tools\bam_batcher\invsmall\$code`AS.GIF
python .\.github\skills\create-spell-icons\compose_al_gif.py `
    .\tools\bam_batcher\invlarge\BLANK_SCROLL.GIF `
    (Join-Path $spellDir "$code`C.GIF") `
    .\tools\bam_batcher\invlarge\$code`AL.GIF
```

The supplied icon is the source of truth: `B.GIF` and `C.GIF` must be
byte-for-byte identical, while `AL.GIF` preserves the complete scroll canvas
and overlays that icon.

Create a simple, monochrome pixel-art icon no larger than 32x32 pixels. Use a
clear silhouette, hard-edged pixels, and one shade of the requested color
family, with at most a small number of darker or lighter values only when
needed to make the silhouette legible. Do not attempt detailed or
multicolored artwork: the 32x32 canvas has very limited visual resolution.
The top-left pixel must be transparent.

Do not use antialiasing, smoothing, alpha transparency, or an
uncontrolled true-color export. If a drawing tool is unavailable, use an
existing image tool or a small local script with an installed image library;
do not download assets or contact external services.

## Examples

Use the matching existing spell assets as the visual and palette reference:

| Spell color | Reference files |
|---|---|
| `white` | `tools\bam_batcher\invsmall\SPWI110AS.GIF`, `tools\bam_batcher\invlarge\SPWI110AL.GIF`, `tools\bam_batcher\spell\SPWI110B.GIF`, and `tools\bam_batcher\spell\SPWI110C.GIF` |
| `green` | `tools\bam_batcher\invsmall\SPWI423AS.GIF`, `tools\bam_batcher\invlarge\SPWI423AL.GIF`, `tools\bam_batcher\spell\SPWI423B.GIF`, and `tools\bam_batcher\spell\SPWI423C.GIF` |
| `blue` | `TBD` |
| `red` | `TBD` |

Copy both the reference's visual style and its indexed color palette for the
requested color. The GIF background/transparent area must be exactly
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
| `tools\bam_batcher\invsmall` | `<CODE>AS.GIF` | A copy of the existing `SPWI110AS.GIF`; do not redraw it. |
| `tools\bam_batcher\spell` | `<CODE>C.GIF` | The new spell icon alone. |
| `tools\bam_batcher\spell` | `<CODE>B.GIF` | A copy of the `<CODE>C.GIF` icon. |
| `tools\bam_batcher\invlarge` | `<CODE>AL.GIF` | The existing `BLANK_SCROLL.GIF` canvas with the image on top; this produces the `A` BAM. |

Inspect the example files before editing them so dimensions, indexed palettes,
and canvas bounds are retained. Never overwrite the `SPWI110` source
templates. The `AS` file must be copied byte-for-byte from `SPWI110AS.GIF`.
For `B.GIF`, copy byte-for-byte from the `<CODE>C.GIF` icon. For `AL.GIF`, start from
`BLANK_SCROLL.GIF` and preserve its complete scroll background, then draw the
`C.GIF` icon over it. Do not replace the scroll with a blank transparent
canvas.

Copy the small inventory template explicitly:

```powershell
Copy-Item .\tools\bam_batcher\invsmall\SPWI110AS.GIF `
    .\tools\bam_batcher\invsmall\<CODE>AS.GIF
```

Use the spell name and requested color to choose one clear, recognizable
monochrome silhouette for `C.GIF`. Create `AL.GIF` from the selected reference
canvas, preserve the scroll background, and draw the same simplified `C.GIF`
icon on top of it. Do not put readable UI text or extra detailed artwork
outside the available bitmap area.

Use the bundled `compose_al_gif.py` tool to create the large inventory image.
It keeps `BLANK_SCROLL.GIF` as the indexed base image and replaces only pixels
where the `C.GIF` icon is non-transparent; do not composite and re-quantize
the entire image, because that can corrupt the scroll background:

```powershell
python .\.github\skills\create-spell-icons\compose_al_gif.py `
    .\tools\bam_batcher\invlarge\BLANK_SCROLL.GIF `
    .\tools\bam_batcher\spell\<CODE>C.GIF `
    .\tools\bam_batcher\invlarge\<CODE>AL.GIF
```

## Convert the GIFs to BAMs

Use the bundled `.\.github\skills\create-spell-icons\convert-SPWI314A.bat`
for the conversion. The skill folder contains the matching
`NearInfinity.jar` and `input.json`; no external Near Infinity directory is
needed. Edit the bundled `input.json` before each invocation. Use absolute
paths for the GIF sources and BAM outputs because the batch file changes to
the skill directory.

First generate the two-frame A BAM from the AS and AL GIFs:

```json
{
  "sources": [
    {
      "file": "C:\\Games\\Steam\\steamapps\\common\\Rick_Mod_work\\rick_bigg_mod\\tools\\bam_batcher\\invsmall\\<CODE>AS.GIF",
      "centerX": 20,
      "centerY": 15
    },
    {
      "file": "C:\\Games\\Steam\\steamapps\\common\\Rick_Mod_work\\rick_bigg_mod\\tools\\bam_batcher\\invlarge\\<CODE>AL.GIF",
      "centerX": 0,
      "centerY": 0
    }
  ],
  "cycles": [[0, 1]],
  "output": "C:\\Games\\Steam\\steamapps\\common\\Rick_Mod_work\\rick_bigg_mod\\tools\\bam_batcher\\bam\\<CODE>A.BAM"
}
```

Then edit `input.json` and invoke the same batch file once for each single-frame
BAM. Each configuration has one source, `centerX: 0`, `centerY: 0`, and an
output ending in `\<CODE>B.BAM` or `\<CODE>C.BAM`:

```json
{
  "sources": [
    {
      "file": "C:\\Games\\Steam\\steamapps\\common\\Rick_Mod_work\\rick_bigg_mod\\tools\\bam_batcher\\spell\\<CODE>B.GIF",
      "centerX": 0,
      "centerY": 0
    }
  ],
  "cycles": [[0]],
  "output": "C:\\Games\\Steam\\steamapps\\common\\Rick_Mod_work\\rick_bigg_mod\\tools\\bam_batcher\\bam\\<CODE>B.BAM"
}
```

Use the analogous `C.GIF` and `<CODE>C.BAM` values for the third invocation.
Verify `<CODE>A.BAM`, `<CODE>B.BAM`, and `<CODE>C.BAM` exist in
`tools\bam_batcher\bam` after conversion.

Copy all three generated BAMs to the repository's `copy` directory in both
icon-creation modes. Do not copy only the A BAM:

```powershell
$bamDir = '.\tools\bam_batcher\bam'
$copyDir = '.\copy'
foreach ($suffix in 'A', 'B', 'C') {
    $source = Join-Path $bamDir "$code$suffix.BAM"
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Missing generated BAM: $source"
    }
    Copy-Item -LiteralPath $source -Destination (Join-Path $copyDir "$code$suffix.BAM") -Force
}
```

Verify that `<CODE>A.BAM`, `<CODE>B.BAM`, and `<CODE>C.BAM` also exist in
`copy` before completing the skill.

After writing the GIF files, verify all four exist, are GIFs, are at most 32x32
pixels where applicable, and have the required green top-left pixel. If the
scroll template is larger than 32x32, retain its original template dimensions;
the 32x32 limit applies to the drawn spell icon, not the surrounding scroll
asset.
