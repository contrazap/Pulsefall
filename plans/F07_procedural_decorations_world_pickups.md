# F07 — Procedural decorations and world pickups

- Status: Complete
- Roadmap dependency: F06
- Created: 2026-09-01
- Completed: 2026-09-01

## Objective

Populate the endless-looking arena around the moving player with a bounded, recycled set of non-colliding geometric decorations and a small capped set of collectible Health, Magnet, and Bomb pickups whose effects integrate with the existing player, XP, normal-enemy death, pause, and restart behavior.

## Preflight and existing state

- F06 is complete. `scenes/main.tscn` has `World` containers for the player, normal enemies, projectiles, and capped XP coins; `scripts/game_controller.gd` coordinates player health, normal-enemy deaths, XP collection, pause, defeat, and restart.
- `scripts/player.gd` exposes maximum/current health and health-change signals but has no focused healing method. `scripts/xp_coin.gd` has an idempotent public `collect()` path, so Magnet can preserve each coin's full value and existing progression events.
- Normal enemies alone use the `normal_enemies` group and their `take_damage()` death path creates XP drops. Bomb must use that boundary rather than a generic enemy target so a future F08 boss is not instantly defeated.
- `scripts/arena_grid.gd` already redraws a bounded camera-relative grid. No decoration, world-pickup, pickup-container, or world-population manager exists yet.
- With Godot `4.7.1.stable.official.a13da4feb`, headless import/parser, F00–F06 verification, a 600-frame main-scene smoke run, and `git diff --check` passed on 2026-09-01 before this plan was written. The dirty working tree contains completed F05/F06 work; preserve it.

## In scope

- Add lightweight, non-colliding neon decorations distributed around the player. Keep their active count at a centralized cap and recycle or replace distant entries as the player travels so the arena remains populated without accumulating nodes.
- Add one reusable world-pickup implementation with clear geometric presentations for Health, Magnet, and Bomb, plus centralized collection radius, spawn interval/count, placement annulus, and retention limits.
- Procedurally place pickups around the living player outside a positive minimum distance, never directly beneath the player, and maintain no more than the configured small cap. Recycle overly distant pickups so the active set remains relevant to the player's current area.
- Health restores exactly 25 health through a focused player healing path, never exceeds maximum health, and updates the existing health HUD immediately.
- Magnet collects every currently active valid XP coin through each coin's existing one-shot `collect()` path, preserving merged values, progression, level-up queuing, and pause behavior.
- Bomb applies centralized heavy damage through `take_damage()` only to living nodes in `normal_enemies`, allowing normal death/XP-drop behavior while leaving non-normal-enemy nodes unaffected for F08 compatibility.
- Preserve F00–F06 gameplay, upgrade/defeat pauses, bounded entity patterns, and clean scene-reload restart. Add focused F07 verification.

## Out of scope

- Boss spawning, boss damage tuning, boss health UI, victory, or any other F08 behavior; F07 only establishes that Bomb ignores nodes outside `normal_enemies`.
- New pickup types, inventories, manual pickup activation, pickup HUD/history, rarity systems, permanent upgrades, or saves.
- Blocking props, terrain generation, rooms, navigation, pathfinding, physics obstacles, or decoration collision.
- Changes to XP thresholds, upgrade offerings/ranks, normal spawn pressure, combat balance beyond the specified pickup effects, audio, external art, or final F09 tuning/polish.
- A generic loot/effect framework or broad refactor of the controller, player, enemy, XP, or arena systems.

## Expected files

- `scenes/main.tscn` — add dedicated decoration/pickup containers and the focused world-population manager wiring.
- `scripts/world_population.gd` with its Godot UID sidecar — bounded generation, placement, replenishment/recycling, deterministic test seams, and pickup-collection signaling.
- `scenes/world_decoration.tscn` and a small script only if needed — reusable non-colliding geometric decoration variants.
- `scenes/world_pickup.tscn` and `scripts/world_pickup.gd` with its UID sidecar — reusable typed pickup, distinct geometric presentation, distance-based one-shot collection, and stable pickup identifiers.
- `scripts/game_controller.gd` — receive pickup events and coordinate Health, Magnet, and normal-enemy-only Bomb effects through existing systems.
- `scripts/player.gd` — add a clamped, signal-emitting healing method suitable for Health pickups.
- `tests/verify_f07.gd` with its Godot UID sidecar — focused population, placement, effects, pause, restart, and regression checks.
- `plans/F07_procedural_decorations_world_pickups.md` and `PROGRESS.md` — implementation evidence and next-feature handoff.

## Implementation steps

1. Re-run the F00–F06 baseline, confirm this plan still matches the project, and mark F07 `In progress` in `PROGRESS.md` before runtime edits.
2. Add dedicated `World/Decorations` and `World/Pickups` containers plus a small world-population manager with centralized caps, placement annuli, retention distances, refresh/spawn timing, and controllable randomness for deterministic verification.
3. Add reusable non-colliding geometric decoration variants. Populate around the player, recycle entries that fall outside the retention area as the player travels, and prove refreshes never exceed the decoration cap.
4. Add the reusable Health/Magnet/Bomb pickup with distinct readable geometry, stable identifiers, distance-based one-shot collection, and manager-owned capped spawning/recycling that never places a pickup inside the configured minimum player distance.
5. Route pickup collection to the controller: heal the player by 25 with maximum-health clamping and immediate HUD signaling, collect a snapshot of all valid XP coins through `collect()`, and heavily damage a snapshot of living `normal_enemies` through `take_damage()` without targeting other groups.
6. Add deterministic `verify_f07.gd` coverage for caps during repeated refresh/travel, placement bounds, all three one-shot effects, XP/death integration, non-normal-enemy Bomb immunity, pause behavior, and fresh restart population.
7. Run the full verification plan, perform the focused manual check, then record exact results in this plan and `PROGRESS.md`. Mark F07 complete only after every criterion is verified.

## Acceptance criteria

- [x] A new run shows lightweight geometric decorations distributed around the player. Decorations have no collision/gameplay effect, their active count never exceeds a centralized positive cap, and repeated refreshes or long-distance player travel recycle/reposition them without unbounded node growth or exposing a decorated-world boundary.
- [x] A small procedurally replenished set of Health, Magnet, and Bomb pickups appears around the living player. Every pickup is placed outside a centralized positive minimum player distance and within its configured placement area, overly distant pickups are recycled, and active pickup nodes never exceed the centralized cap.
- [x] The three pickup types are visually distinguishable from one another, the player, enemies, projectiles, and XP coins using repository-native geometric presentation.
- [x] A pickup applies its effect at most once when the living player enters the centralized collection radius and then removes itself; ordinary gameplay does not collect a pickup from outside that radius.
- [x] Health restores exactly 25 health up to the player's current maximum, never exceeds maximum health, and updates the existing health value immediately, including after Vitality has increased maximum health.
- [x] Magnet collects all XP coins that are active when its effect begins through the existing coin collection path. Each coin's full stored/merged XP value is awarded once, the XP container is cleared of those coins, and any crossed thresholds still produce the existing ordered paused upgrade choices.
- [x] Bomb heavily damages or destroys every active living normal enemy through the existing `take_damage()`/death path, so killed normal enemies retain their XP-drop behavior. It does not damage a valid damageable node that is outside the `normal_enemies` group, establishing compatibility with the future boss.
- [x] Decoration/pickup generation and pickup collection freeze while an upgrade choice or defeat overlay pauses gameplay. Restart reloads a fresh bounded population with no retained pickup effects or nodes from the prior run and preserves the existing clean player, enemy, projectile, XP, progression, upgrade, and Nova state.
- [x] F00–F06 movement, camera/grid presentation, capped enemy spawning, combat/damage, XP progression, paused upgrade flow, Vitality/Haste, Multishot/Piercing/Nova, defeat, and restart behavior remain functional.
- [x] The project imports/parses, F00–F06 regressions and focused F07 checks pass, and the configured main scene smoke-runs without parser, missing-resource, runtime, or orphan-node errors while all gameplay populations remain bounded.
- [x] No boss/victory behavior, blocking terrain, pathfinding, save/meta-progression, third-party dependency, or unrelated feature is introduced.

## Verification plan

### Automated or headless

- Import and parse the project:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path . --quit`
  Expected: exit code 0 with no parser, missing-resource, or import errors.
- Re-run completed-feature regressions:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f00.gd`
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f01.gd`
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f02.gd`
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f03.gd`
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f04.gd`
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f05.gd`
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f06.gd`
  Expected: all exit 0 with their verification pass messages.
- Run the focused F07 check:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f07.gd`
  Expected: exit 0 after deterministic checks of decoration/pickup caps and recycling, valid placement, one-shot Health/Magnet/Bomb effects, HUD/XP/drop integration, normal-enemy-only Bomb filtering, pause, and clean restart.
- Smoke-run sustained spawning, combat, world-population refresh, and collection:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --quit-after 600`
  Expected: exit 0 with no script/runtime or orphan-node errors; enemy, projectile, XP coin, decoration, and pickup populations remain bounded. An unattended level-up may leave the run safely paused at its choice screen.
- Check patch hygiene:
  `git diff --check`
  Expected: exit code 0.

### Manual

- Start a run and travel far enough to force several population refreshes. Confirm the arena stays lightly decorated without collision or a visible decorated edge, old decorations/pickups do not trail indefinitely, and all three pickup silhouettes/colors are readable among combat entities.
- Take damage, collect Health, and confirm the HUD rises by 25 without passing maximum health. Collect Health near maximum and confirm the value clamps correctly.
- Leave several XP coins active, including a merged-value coin if practical, then collect Magnet. Confirm all current coins disappear, their total XP is awarded, and any level-up opens the normal paused three-choice screen.
- Collect Bomb with multiple normal enemies active. Confirm they take heavy damage or die, their normal XP drops remain, and no unrelated world entity is affected.
- Open an upgrade choice and trigger defeat with world population present to confirm generation/collection freezes, then restart and confirm a fresh clean run with bounded decorations/pickups and no retained effects.

## Completion notes

- Actual files changed: `scenes/main.tscn`, `scenes/world_decoration.tscn`, `scenes/world_pickup.tscn`, `scripts/world_decoration.gd`, `scripts/world_pickup.gd`, `scripts/world_population.gd`, their generated Godot UID sidecars, `scripts/player.gd`, `scripts/game_controller.gd`, `tests/verify_f07.gd` and its UID sidecar, this plan, and `PROGRESS.md`.
- Commands/tests and results: Godot 4.7.1 headless editor import passed; `verify_f00.gd` through `verify_f07.gd` all passed; the configured main scene completed a 600-frame fixed-FPS smoke run without parser/runtime/orphan errors; `git diff --check` passed. Focused F07 coverage proved the 28-decoration and 3-pickup caps, node recycling across eight long-distance moves, annulus placement, no decoration collision, all three stable types, collection radius/idempotence, exact and clamped Health, merged-value Magnet progression/pause, normal-only Bomb damage with XP drops, pause, replenishment, and clean restart.
- Manual checks performed: rendered with the normal OpenGL compatibility renderer and visually inspected 1152×648 origin and far-traveled frames containing the player, enemies, an XP coin, decorations, and all pickups. The subtle cyan decoration variants remained distributed after travel; the pink cross Health, violet horseshoe Magnet, and orange rayed-diamond Bomb were distinct from the cyan player/coin and magenta enemies. The temporary harness and captures were removed. Physical keyboard/mouse play was not performed; travel, effects, upgrade/defeat pause, and restart were exercised by `verify_f07.gd`.
- Deviations from plan: added the optional small `world_decoration.gd` script to draw three reusable variants; the initial three-pickup population deliberately draws each type once from a shuffled bag so every effect is available and visually inspectable while later replenishment remains randomized.
- Remaining risks or follow-up: pickup frequency and combat impact remain initial values for F09 tuning. F08 must keep its boss outside `normal_enemies` so Bomb remains boss-safe.
