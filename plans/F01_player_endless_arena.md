# F01 — Player and endless-looking arena

- Status: Complete
- Roadmap dependency: F00
- Created: 2026-08-30
- Completed: 2026-08-31

## Objective

Add a responsive geometric player that moves with the existing keyboard actions while a camera follows it through a repeating neon floor with no reachable visible boundary, preserving the F00 HUD as viewport-fixed presentation.

## Preflight and existing state

- F00 is complete: `project.godot` launches `scenes/main.tscn`, defines WASD and arrow-key movement actions, and provides the dark background plus viewport-fixed HUD shell.
- The current main scene has no gameplay scripts, world-space nodes, player, camera, collision, or arena rendering; F01 can introduce these without migrating existing gameplay state.
- Git was clean when this plan was created.
- The F00 headless import, focused verification script, and main-scene smoke run all pass with Godot `4.7.1.stable.official.a13da4feb` before implementation.

## In scope

- Add one reusable `CharacterBody2D` player scene with a clear neon geometric placeholder visual.
- Implement movement from the existing four input actions with an exported movement speed, normalized diagonal input, and frame-rate-independent physics movement.
- Attach and enable a `Camera2D` that follows the player while keeping the player centered during normal play.
- Replace the static arena presentation as needed with a lightweight repeating grid/floor that follows or redraws around the camera, covers the viewport at supported window sizes, and cannot reveal a finite world edge during extended movement.
- Integrate the world-space content beneath the existing `CanvasLayer` HUD so the HUD remains fixed to the viewport.
- Add focused automated verification for structural and deterministic F01 behavior while retaining the F00 regression check.

## Out of scope

- Enemies, spawning, combat, projectiles, damage, health behavior, defeat, or restart logic from F02 and later.
- XP, upgrades, decorations, pickups, boss behavior, or run progression.
- Obstacles, collision boundaries, terrain topology, navigation, procedural rooms, or persistent world chunks.
- External art, complex animation, controller/mobile input, camera effects, or unrelated HUD redesign.

## Expected files

- `scenes/main.tscn` — integrate the world-space arena and player beneath the existing HUD.
- `scenes/player.tscn` — reusable player body, geometric visual, and following camera.
- `scripts/player.gd` — typed movement logic and exported speed.
- `scripts/arena_grid.gd` — bounded camera-relative repeating floor rendering.
- `tests/verify_f01.gd` — focused structural and movement verification.
- `plans/F01_player_endless_arena.md` — checked criteria and completion evidence.
- `PROGRESS.md` — implementation status, evidence, blockers, and next action.

## Implementation steps

1. Re-run the F00 baseline, then mark F01 `In progress` in `PROGRESS.md` before changing runtime files.
2. Create a focused player scene using `CharacterBody2D`, an easily readable geometric visual, an enabled `Camera2D`, and a script with exported movement speed.
3. Implement physics movement through `Input.get_vector()` (or equivalent normalized input) and `move_and_slide()`, ensuring opposite inputs cancel and diagonal movement is not faster than axial movement.
4. Add a world container and repeating grid/floor to the main scene; render only a viewport-sized region plus a small safety margin, snapped to a fixed grid interval so movement never exposes a boundary or causes unbounded node growth.
5. Instance the player at the world origin and preserve the F00 HUD in its `CanvasLayer` so camera movement affects the world but not the interface.
6. Add a focused F01 verification script for scene structure, tunable movement, representative axial/diagonal movement, camera setup, and bounded floor configuration.
7. Run the import/parser, F00 regression, F01 focused check, and main-scene smoke run; then perform the manual movement/camera/floor check and record only observed results.

## Acceptance criteria

- [x] Running the main scene shows a clearly distinguishable geometric player over a repeating neon floor while retaining the readable F00 HUD.
- [x] WASD and arrow keys move the player responsively in all four directions; releasing input stops movement, opposite inputs cancel, and diagonal movement does not exceed the configured axial speed.
- [x] Player movement speed is exported or otherwise centralized for later Haste integration rather than duplicated as unexplained literals.
- [x] The enabled camera follows the player and keeps it centered during extended travel in every direction, while the HUD remains fixed to the viewport.
- [x] The repeating floor continuously covers the visible play area at the default window size and at 800×450, with no reachable edge or exposed clear region during extended movement.
- [x] Arena rendering uses a fixed amount of scene content or bounded draw work; travel does not accumulate floor tiles or other nodes.
- [x] The project imports/parses, the F00 regression check passes, the focused F01 check passes, and the configured main scene smoke-runs without parser, missing-resource, or runtime errors.
- [x] No F02-or-later gameplay behavior or third-party dependency is introduced.

## Verification plan

### Automated or headless

- Import and parse the project:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path . --quit`
  Expected: exit code 0 with no parser, missing-resource, or import errors.
- Re-run the foundation regression:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f00.gd`
  Expected: exit code 0 and the F00 verification pass message.
- Run the focused F01 check:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f01.gd`
  Expected: exit code 0 after checking the player/main-scene structure, positive centralized speed, normalized representative movement, enabled following camera, fixed HUD layer, and bounded repeating-floor configuration.
- Smoke-run the configured main scene:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 2`
  Expected: exit code 0 with no script or runtime errors.

### Manual

- Run the main scene and hold each WASD and arrow direction, then test a diagonal and opposing key pairs; confirm movement starts/stops predictably, diagonals do not look faster, and opposite inputs cancel.
- Travel continuously in every direction long enough to move several viewport widths; confirm the camera follows, the player stays centered, the repeating grid has no visible edge or uncovered seam, and no floor nodes accumulate in the remote scene tree.
- Repeat representative movement after resizing the window to 800×450; confirm the floor still covers the viewport and the HUD remains fixed, separated, and readable.

## Completion notes

- Actual files changed: updated `scenes/main.tscn`; added `scenes/player.tscn`, `scripts/player.gd`, `scripts/arena_grid.gd`, `tests/verify_f01.gd`, and the three Godot-generated script UID sidecars; updated this plan and `PROGRESS.md`.
- Commands/tests and results:
  - `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path . --quit` — exit 0; import and script scan completed without parser or resource errors.
  - `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f00.gd` — exit 0; F00 regression passed.
  - `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f01.gd` — exit 0; verified movement input directions, release/opposition behavior, diagonal normalization, exported speed, player/camera structure, viewport-fixed HUD, grid alignment, and bounded draw work.
  - `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 2` — exit 0; configured main scene smoke-ran without runtime errors.
- Manual checks performed: launched a temporary rendered capture harness with the normal graphics renderer and visually inspected the initial 1152×648 frame, a stable frame after 300 simulated right-movement physics frames (player world X about 1595), and an 800×450 resized frame. The geometric player stayed centered, the HUD stayed fixed and readable, and the repeating grid covered every frame without a visible edge or seam. Physical keyboard interaction was not performed; all four action directions, release, opposing inputs, and diagonal normalization were exercised by `verify_f01.gd`.
- Deviations from plan: retained the F00 background controls behind the new bounded grid so the existing regression check remains valid; the active arena itself is rendered by one camera-relative `Node2D` rather than accumulated tile nodes.
- Remaining risks or follow-up: player collision geometry is intentionally deferred until F02/F03 establishes enemy and contact requirements. No F01 blocker remains.
