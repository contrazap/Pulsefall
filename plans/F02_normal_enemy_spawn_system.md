# F02 — Normal enemy and spawn system

- Status: Planned
- Roadmap dependency: F01
- Created: 2026-08-31
- Completed: —

## Objective

Add a reusable geometric normal enemy that moves directly toward the player, plus a configurable world-level spawner that creates enemies just outside the current camera view and enforces a hard active-enemy cap.

## Preflight and existing state

- F01 is complete: `scenes/main.tscn` contains `World/Player`, an enabled player-owned `Camera2D`, a bounded camera-relative arena grid, and the viewport-fixed F00 HUD.
- The player is a moving `CharacterBody2D` with centralized speed, but the project has no enemy scene, gameplay controller, spawner, combat, damage, or collision-driven interaction yet.
- Git was clean when this plan was created.
- On 2026-08-31, the headless import, F00 regression, F01 focused verification, and main-scene smoke run all passed with Godot `4.7.1.stable.official.a13da4feb`.

## In scope

- Add one reusable normal-enemy scene with a readable geometric placeholder visual and a focused typed script.
- Give the enemy a player target and direct, frame-rate-independent chase movement with exported or centralized movement speed.
- Add a focused world-level spawn system that references the existing player and camera, spawns at randomized positions beyond the visible viewport edge with a positive margin, and never spawns directly on the player.
- Centralize the spawn interval, off-screen margin, and maximum active-enemy count for later tuning.
- Keep spawned enemies under a dedicated world container and/or group so the active population is countable and usable by later combat features.
- Add focused automated verification while retaining the F00 and F01 regression checks.

## Out of scope

- Projectiles, auto-targeting, enemy health or death, XP drops, player contact damage, invulnerability, defeat, or restart behavior from F03 and F04.
- Difficulty scaling by level, waves, multiple normal enemy types, pathfinding, navigation, obstacle avoidance, or enemy separation behavior.
- Boss-specific stats or visuals, boss spawning, and boss health UI from F08.
- External art, complex animation, sound, or unrelated player, arena, and HUD changes.

## Expected files

- `scenes/main.tscn` — add the enemy container and configured spawner to the existing world.
- `scenes/enemy.tscn` — reusable normal-enemy body and geometric visual.
- `scripts/enemy.gd` — target assignment and direct chase movement.
- `scripts/enemy_spawner.gd` — timed, camera-aware, capped off-screen spawning.
- `tests/verify_f02.gd` — focused structural, chase, spawn-position, and population-cap verification.
- `plans/F02_normal_enemy_spawn_system.md` — checked criteria and completion evidence.
- `PROGRESS.md` — implementation status, evidence, blockers, and next action.

## Implementation steps

1. Re-run the F00 and F01 baseline, then mark F02 `In progress` in `PROGRESS.md` before changing runtime files.
2. Create a reusable `CharacterBody2D` enemy scene with a distinct neon geometric visual, a useful collision shape for later integration, and membership in a dedicated enemy group.
3. Implement typed enemy movement toward an assigned `Node2D` target using centralized speed and normalized direction, handling a missing or freed target without errors.
4. Add an enemy container and focused spawner beneath `World`; configure it with references to the existing player, its camera, and the enemy scene.
5. Implement timer-driven spawning on randomized viewport sides. Convert the camera view to world-space extents, add the configured margin, assign the player target, and refuse new spawns whenever the active-enemy cap is reached.
6. Expose deterministic helper methods or equivalent test seams for chase velocity, off-screen position validation, and cap decisions without introducing a generic framework.
7. Add `tests/verify_f02.gd`, then run import/parser, F00, F01, F02, and main-scene smoke checks; perform the focused manual spawn/chase/cap check and record only observed results.

## Acceptance criteria

- [ ] Running the main scene produces clearly distinguishable normal enemies that enter from beyond the current visible play area and move directly toward the moving player.
- [ ] The reusable enemy accepts a player target, uses a positive centralized movement speed, moves frame-rate-independently, and remains safe when its target is absent or freed.
- [ ] Every generated spawn position is outside the camera-visible world rectangle by a configured positive margin and is not directly on the player, including after the player travels away from the origin.
- [ ] Spawn interval, off-screen margin, and maximum active-enemy count are exported or otherwise centralized rather than scattered as unexplained literals.
- [ ] The active normal-enemy population never exceeds the configured cap, and continued runtime at the cap does not accumulate extra enemy nodes.
- [ ] The player movement, following camera, repeating floor, and viewport-fixed HUD from F00/F01 remain functional while enemies spawn and chase.
- [ ] The project imports/parses, the F00 and F01 regression checks pass, the focused F02 check passes, and the configured main scene smoke-runs without parser, missing-resource, or runtime errors.
- [ ] No combat, damage, death, XP, upgrade, pickup, boss, or third-party dependency behavior is introduced.

## Verification plan

### Automated or headless

- Import and parse the project:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path . --quit`
  Expected: exit code 0 with no parser, missing-resource, or import errors.
- Re-run the foundation and arena regressions:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f00.gd`
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f01.gd`
  Expected: both exit 0 with their verification pass messages.
- Run the focused F02 check:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f02.gd`
  Expected: exit code 0 after validating the reusable enemy structure, direct chase calculations, missing-target safety, world integration, off-screen spawn positions around representative camera locations, centralized tuning, target assignment, and hard population cap.
- Smoke-run the configured main scene for 600 fixed iterations to exercise repeated spawning:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --quit-after 600`
  Expected: exit code 0 with no script or runtime errors while multiple spawn intervals elapse.

### Manual

- Run the main scene and remain near the origin long enough to observe several spawns; confirm enemies first appear from outside different viewport edges, enter view, and head directly toward the player.
- Move several viewport widths and change direction while enemies are active; confirm new enemies spawn relative to the current view rather than the world origin and existing enemies adjust their chase direction.
- Keep the run open until the configured cap is reached and inspect the remote scene tree or a temporary debug count; confirm the enemy count stops at the cap while player movement, camera following, floor coverage, and HUD presentation remain intact.

## Completion notes

Fill this in during implementation:

- Actual files changed:
- Commands/tests and results:
- Manual checks performed:
- Deviations from plan:
- Remaining risks or follow-up:
