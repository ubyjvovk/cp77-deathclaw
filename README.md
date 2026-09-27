# Deathclaw local mod project

This repository checkpoints both the original Badlands statue and the animated
territorial creature. The current creature release is **v3.3**; see
[creature/README.md](creature/README.md) for controls, limitations and testing status.
[STATUS.md](STATUS.md) contains the development record and runtime observations.

The user verified the statue in-game and confirmed the brawler attacks V and NPCs.
The latest v3.3 fists-only loadout, scanner names and Mother animation-root scaling
have passed offline checks but still require in-game validation.

This is a local checkpoint including extracted/converted assets, Blender work,
source tools, diagnostics and packaged builds. No remote is configured. Python
virtual environments, downloaded tool installations, compilation caches and game-save
backups are excluded by .gitignore and remain on disk. The assets are for this local
modding project; this repository is not a public distribution package.

## Original statue build notes

The following records the initial statue build; later verification and changes are
recorded in STATUS.md.

# Deathclaw Badlands — local development build

Ports the original Fallout: New Vegas Deathclaw into Cyberpunk 2077 as a static,
textured statue near the Badlands Wind Farm. Source files are extracted from the
local New Vegas installation. The mesh is posed using the first frame of its
original combat-ready animation and scaled to 3.2 metres tall.

## Current verification

- Extraction succeeded; source paths and SHA-256 hashes are in `source_manifest.json`.
- Blender preview inspected: `work/deathclaw_preview.png`.
- WolvenKit compiled and read back the mesh, entity, colour texture, and normal map.
- Compiled mesh has one render chunk, four simple collision boxes, and correct bounds.
- A GLB exported back from the compiled mesh renders correctly in Blender and retains
  all 6,930 triangles. See `work/deathclaw_compiled_preview.png`.
- Texture imports use DXT colour with gamma and normal-map compression without gamma.
- Packed archive contents inspected: four resources, all under `local/deathclaw_badlands`.
- CET loaded the mod and ran its initialization successfully.
- Lua lifecycle checks passed for repeated return visits, duplicate prevention,
  world/save reloads, and bounded spawn retries using mocked game APIs.
- **In-game appearance, placement, collision, and reload behaviour remain unverified.**
  Startup tests with the AMM registration installed crashed. Tests with the archive
  and placement script, without AMM registration, stayed running for several minutes.
  This narrows the issue but does not establish its cause. AMM registration is held
  in `optional/amm` and is not installed. Desktop screenshot captures time out, so
  on-screen game verification still requires a working capture connection.

## Installed files

This development build is installed directly into `E:\Games\Cyberpunk 2077`.
It is visible to MO2 profiles using that game installation. The exact files and
their installation hashes are recorded in `installed-files.json`:

- `archive/pc/mod/deathclaw_badlands.archive`
- `bin/x64/plugins/cyber_engine_tweaks/mods/DeathclawBadlands/init.lua`

A third installed file is an identical CET `init.lua` under MO2's
`overwrite/bin/x64/plugins/cyber_engine_tweaks/mods/DeathclawBadlands/` directory.
This is necessary in this MO2 setup: after CET creates its runtime directory there,
its Lua sandbox otherwise cannot find the physical game-root `init.lua`.

Requires CET and Codeware. The automatic Wind Farm placement does not require AMM.

## Find it

Open CET with your configured overlay key. The **Deathclaw Badlands** panel has a
**Visit the statue** button. It teleports V to the Wind Farm viewing spot.
The intended statue position is approximately **3816, -1555, 130**; terrain height
is determined by a downward raycast when V comes within 180 metres.

The entity is removed beyond 250 metres and recreated on approach. It is not
written into the save as a persistent dynamic entity; the installed script restores
the placement in loaded games. This behaviour still needs in-game validation.

The optional AMM registration is not part of the installed build pending diagnosis.

## Project files

- `source/`: original extracted assets, local only.
- `work/deathclaw.blend`: editable scene and material preview.
- `project/source/raw/`: converted GLB and PNG textures.
- `project/source/archive/`: compiled REDengine resources and editable JSON.
- `project/source/resources/`: CET integration.
- `optional/amm/`: AMM registration, excluded from the installed/test package.
- `dist/Deathclaw Badlands/`: game-relative installation package.
- `tools/`: extraction, pose conversion, resource construction, and packaging scripts.
- `save-backup-before-testing/`: copy of the save directory before the game tests.

## Removal

With the game closed, remove the three installed files recorded in the manifest. The
`DeathclawBadlands` CET directory may also contain generated status/log/database
files. Do not remove AMM itself. Original game archives are not replaced.

## Known limits

This is a stationary prop, with approximate body collision. It has no AI or combat
behaviour. Textures retain their original 1024×1024 resolution. No AI remeshing or
texture upscaling has been applied.
