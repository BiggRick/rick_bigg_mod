---
name: create-spell-icons
description: Create Baldur's Gate II spell icon BMPs, run BAM Batcher, and copy the generated BAMs into the mod. Use when asked to create spell icons or BAMs for a spell code.
---

# Create Spell Icons

Create the four BMP inputs expected by BAM Batcher, convert them to BAM files,
and copy the resulting spell BAMs into this mod's `copy` directory.

## Bootstrap the BAM editing tool

The game directory and its `..\bambatch` tree are explicitly in scope for this
skill. Do not repeatedly ask for permission before reading, writing, or
running tools against those paths. Use the official BAM Batcher repository:
`https://github.com/Sampsca/BAM-Batcher`.

Before editing BAM-related files, automatically ensure a local tool checkout
exists under `..\bambatch\tools\Sampsca-BAM-Batcher`. Reuse it when present;
otherwise download it non-interactively:

```powershell
$game = (Resolve-Path ..).Path
$toolRoot = Join-Path $game 'bambatch\tools\Sampsca-BAM-Batcher'
if (-not (Test-Path $toolRoot -PathType Container)) {
    git clone --depth 1 https://github.com/Sampsca/BAM-Batcher.git $toolRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to download Sampsca BAM Batcher."
    }
}
```

Do not use an interactive Git prompt, ask for confirmation, or place the
checkout outside `..\bambatch\tools`. Use the downloaded tool for any direct
BAM inspection or editing it supports. Use the existing
`..\setup-bambatch.exe` for this skill's BMP-to-BAM conversion when it is
available; do not replace it with an unverified binary. If the checkout is
missing the required executable or its documented build step is necessary,
follow that repository's instructions automatically and report a concrete
build/download error rather than asking for permission to access the game
directory.

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
$game = Resolve-Path ..
if (-not (Test-Path (Join-Path $game 'bambatch') -PathType Container)) {
    throw "Expected ..\bambatch to be a directory."
}
if (-not (Test-Path (Join-Path $game 'setup-bambatch.exe') -PathType Leaf)) {
    throw "Expected ..\setup-bambatch.exe to be a file."
}
foreach ($subdir in 'invsmall', 'invlarge', 'spell', 'bam') {
    if (-not (Test-Path (Join-Path $game "bambatch\$subdir") -PathType Container)) {
        throw "Missing ..\bambatch\$subdir directory."
    }
}
$templates = @(
    (Join-Path $game 'bambatch\invsmall\SPWI110AS.BMP'),
    (Join-Path $game 'bambatch\invlarge\SPWI110AL.BMP'),
    (Join-Path $game 'bambatch\spell\SPWI110B.BMP'),
    (Join-Path $game 'bambatch\spell\SPWI110C.BMP')
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
    (Join-Path $game 'bambatch\invsmall\SPWI423AS.BMP'),
    (Join-Path $game 'bambatch\invlarge\SPWI423AL.BMP'),
    (Join-Path $game 'bambatch\spell\SPWI423B.BMP'),
    (Join-Path $game 'bambatch\spell\SPWI423C.BMP')
)
foreach ($example in $greenExamples) {
    if (-not (Test-Path $example -PathType Leaf)) {
        throw "Missing required green reference file: $example"
    }
}
```

Do not silently create or substitute the required `bambatch` directory or
installer. Do not modify the read-only `SPWI110` source files. Surface the
error if any required path is absent, has the wrong type, or is not read-only.

## Draw the icon

Create a simple, monochrome pixel-art icon no larger than 32x32 pixels. Use a
clear silhouette, hard-edged pixels, and one shade of the requested color
family, with at most a small number of darker or lighter values only when
needed to make the silhouette legible. Do not attempt detailed or
multicolored artwork: the 32x32 canvas has very limited visual resolution.
The top-left pixel must be exactly `#00ff00`; this is the transparent color
used by the game and must remain unchanged in every icon BMP.

Use an indexed/paletted BMP compatible with BAM Batcher. Preserve or create a
palette entry for `#00ff00`, and verify the actual pixel at `(0, 0)` after
saving. Do not use antialiasing, smoothing, alpha transparency, or an
uncontrolled true-color export. If a drawing tool is unavailable, use an
existing image tool or a small local script with an installed image library;
do not download assets or contact external services.

## Examples

Use the matching existing spell assets as the visual and palette reference:

| Spell color | Reference files |
|---|---|
| `white` | `..\bambatch\invsmall\SPWI110AS.BMP`, `..\bambatch\invlarge\SPWI110AL.BMP`, `..\bambatch\spell\SPWI110B.BMP`, and `..\bambatch\spell\SPWI110C.BMP` |
| `green` | `..\bambatch\invsmall\SPWI423AS.BMP`, `..\bambatch\invlarge\SPWI423AL.BMP`, `..\bambatch\spell\SPWI423B.BMP`, and `..\bambatch\spell\SPWI423C.BMP` |
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
| `..\bambatch\invsmall` | `<CODE>AS.BMP` | A copy of the existing `SPWI110AS.BMP`; do not redraw it. |
| `..\bambatch\invlarge` | `<CODE>AL.BMP` | The existing `BLANK_SCROLL.BMP` canvas with the image on top; this produces the `A` BAM. |
| `..\bambatch\spell` | `<CODE>C.BMP` | The new spell icon alone. |
| `..\bambatch\spell` | `<CODE>B.BMP` | The spell code rendered or represented with a small amount of gray background, following the existing `SPWI110B.BMP` layout. |

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
Copy-Item ..\bambatch\invsmall\SPWI110AS.BMP `
    ..\bambatch\invsmall\<CODE>AS.BMP
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

## Run BAM Batcher

Install the converter from the game directory, not from the mod directory.
Run the two components as separate commands and check each exit code:

```powershell
Push-Location ..
try {
    .\setup-bambatch.exe --force-install 1
    if ($LASTEXITCODE -ne 0) { throw "BAM Batcher component 1 failed." }

    .\setup-bambatch.exe --force-install 2
    if ($LASTEXITCODE -ne 0) { throw "BAM Batcher component 2 failed." }
}
finally {
    Pop-Location
}
```

The first install converts BAMs to BMPs and the second converts BMPs to BAMs
according to the bundled BAM Batcher components. Inspect the generated
`..\SETUP-BAMBATCH.DEBUG` log if either command fails. Do not continue to the
copy step after a failed component.

## Copy generated BAMs

From the repository root, copy only the generated files matching the requested
spell code:

```powershell
$code = 'SPWI112' # replace with the normalized requested code
$bamFiles = @(Get-ChildItem (Join-Path (Resolve-Path '..') "bambatch\bam\$code*.BAM") -File)
if ($bamFiles.Count -eq 0) {
    throw "No generated BAMs found for $code."
}
Copy-Item $bamFiles.FullName (Join-Path (Get-Location) 'copy') -Force
```

Confirm that `.\copy\<CODE>*.BAM` exists after copying. Do not copy unrelated
BAMs, installer backups, or the BMP inputs.
