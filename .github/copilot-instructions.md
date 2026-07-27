Purpose

This file gives concise, repo-specific instructions for Copilot sessions operating on the Rick & Bigg Mod repository.

Quick commands

- Package / install (WeiDU):
  - From the repository root, run your WeiDU installer: weidu rick_bigg_mod.tp2
  - WeiDU is expected to be installed and on PATH (weidu.exe or weidu)

- Validate duplicates (simple checks):
  - Run the PowerShell helper to detect duplicate COPY / SAY NAME2 entries:
    powershell -NoProfile -ExecutionPolicy Bypass -File .\powershell\check-duplicates.ps1

- Fix double quotes:
  - After editing any `.tpa` file and before committing, run:
    powershell -NoProfile -ExecutionPolicy Bypass -File .\powershell\check-tpa-quotes.ps1
  - The command invokes `..\weidu --traify <file> --out ..\weidu_external\traify` for every `.tpa` below `lib\` and exits with code `1` when WeiDU cannot parse a file, including when WeiDU reports a fatal error but returns `0`.
  - To validate only edited or staged files, pass their paths after `-Files`: `powershell -NoProfile -ExecutionPolicy Bypass -File .\powershell\check-tpa-quotes.ps1 -Files ".\lib\items\amulets.tpa", ".\lib\items\boots.tpa"`.
  - Fix each reported value by replacing its inner double quotes with single quotes, or by delimiting the entire value with `~...~`.
  - If the check fails only because of nested double quotes, fix those delimiters automatically and rerun it. Report other parsing errors without modifying them.

- Tests / Lint:
  - No formal test, CI, or linter configuration found in the repository.

High-level architecture

- rick_bigg_mod.tp2 (root): WeiDU installer/manifest. Declares metadata and runtime checks (e.g., requires Spell Revisions; limits to EET trilogy). Use this as the entrypoint for packaging/installing the mod.

- lib/ : Primary WeiDU include scripts (.tpa). rick_bigg_mod.tpa in lib is the aggregator that COPYs and INCLUDEs other .tpa files. Many .tpa files implement categories (items.tpa, spells.tpa, creatures.tpa, etc.).

- items/ and copy/: Game data assets. .ITM files (items/) describe items; copy/ contains files that get copied into the game's override folder via COPY directives.

- lang/: TRA translation files and bundled iconv binaries used for character-set conversion. The TP2 includes logic to convert TRA files for EE games.

- 2da/, eff/, spell/: Game-specific data tables, effect files, and spell files.

- powershell/check-duplicates.ps1: Repo-level validation script that scans *.tp* files for duplicate COPY statements and duplicate SAY NAME2 strings.

Key conventions and patterns

- File types
  - .tp2 : WeiDU installer manifest (project metadata, preconditions, high-level BEGIN blocks).
  - .tpa : WeiDU include script — building blocks that the TP2 includes. Keep these modular and include them in lib/rick_bigg_mod.tpa.
  - .ITM, .SPL, .EFF, .2DA, .TRA : Game content files used by WeiDU/COPIES.

- Aggregation
  - lib\rick_bigg_mod.tpa is the central aggregator; prefer adding new includes there or in logically grouped .tpa files under lib/ rather than editing the TP2 top-level flow for small additions.

- Adding new items or assets
  1. Create the .ITM asset in items/ (follow existing naming and grouping by category).
  2. Add the file to copy/ if it needs to be physically copied to the override folder, and add a COPY line in the appropriate .tpa include (or let items.tpa include it).
  3. Update associated 2da and TRA files under 2da/ and lang/ as required.
  4. Run the duplicate-check script to make sure COPY and SAY NAME2 entries are not duplicated.

- Naming and grouping
  - Items are grouped by type inside lib/items/ and items/ (e.g., swords, bows, helmets). Follow the existing grouping for placement and naming conventions (uppercase-like file names observed).

- Installer checks
  - The TP2 contains explicit installer checks (see lines that FAIL if not EET or if Spell Revisions missing). Keep cross-mod dependencies declared in the TP2 to prevent broken installs.

Author / contact

- AUTHOR in rick_bigg_mod.tp2: vbigiani@gmail.com

Notes for Copilot sessions

- Prefer editing or adding modular .tpa includes under lib/ rather than modifying rick_bigg_mod.tp2 unless a new top-level component/installation flow is required.
- Use powershell/check-duplicates.ps1 as a quick pre-commit check for duplicate COPY / SAY NAME2 issues.
- After editing any `.tpa` file or before committing, run `powershell -NoProfile -ExecutionPolicy Bypass -File .\powershell\check-tpa-quotes.ps1`. For a targeted check, pass edited or staged `.tpa` paths after `-Files`. Do not leave double quotes inside a double-quoted `SAY` value; use single quotes internally or delimit the full value with `~...~`.
- Avoid changing game asset filenames or COPY targets without updating all references in .tpa/.tp2 and 2da/TRA files.
- Hard rule: In `*.tp*` files, use ASCII hyphens (`-`) only; never use en dashes or em dashes. Exceptions:
  - In an item's lore/description grammar takes precedence.
  - the user explicitly asked to use en or em dashes for a specific scope (for example, as a regexp to remove existing en/em dashes).

Summary

Created concise repo-specific instructions for building/validating and for common extension patterns (adding items/assets, where to include code). If anything should be adjusted, or if coverage should be added for a specific workflow (e.g., building a distributable archive), say what to include next.