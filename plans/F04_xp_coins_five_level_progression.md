# F04 — XP coins and five-level progression

- Status: Complete
- Roadmap dependency: F03
- Created: 2026-09-01
- Completed: 2026-09-01

## Objective

Add the finite XP loop: each normal enemy defeated through the existing damage path drops a collectible XP coin, collected XP advances through exactly five centralized thresholds with carry-over, and the fixed HUD reports the current level and progress while emitting a clean level-up event for the F05 choice screen.

## Preflight and existing state

- F03 is complete. `scenes/main.tscn` has dedicated enemy and projectile containers, a player with a following camera, placeholder level/XP HUD controls, and `scripts/game_controller.gd` coordinating health, defeat, pause, and restart.
- `scripts/enemy.gd` emits `died(enemy)` exactly once before freeing a defeated normal enemy. `scripts/enemy_spawner.gd` owns all current normal-enemy creation but does not yet expose spawned enemies to the controller.
- The player has a non-blocking `CharacterBody2D` collision shape. No XP coin scene, XP container, progression state, level-up signal, or live level/XP HUD wiring exists.
- The worktree was clean when this plan was created. With Godot `4.7.1.stable.official.a13da4feb`, headless import, F00–F03 verification, and `git diff --check` all passed on 2026-09-01.

## In scope

- Add a reusable, visible XP coin that is attracted toward the player within a centralized pickup radius, awards its positive XP value once on collection, and then removes itself.
- Connect normal enemies created by the existing spawner to the XP drop path so each normal enemy defeated through `take_damage()` drops exactly one coin at its death position; freeing or restarting must not create drops.
- Add a capped `World/XPCoins` population. When the cap is reached, preserve earned XP by merging a new drop's value into an existing coin instead of growing the node count or discarding XP.
- Add focused run-progression state with required-XP thresholds `[5, 9, 14, 20, 28]`, carry-over XP, a starting level of 1, and one level-up event for each crossed threshold, including multiple thresholds crossed by one award.
- Stop progression after the fifth threshold: show level 6 and a clear completed XP state, and never emit a sixth level-up event.
- Update the existing level label, XP value label, and XP bar immediately on collection and after every threshold crossing.
- Preserve F03 defeat and clean-restart behavior; paused defeat must freeze coins, and restart must restore level 1, `0 / 5` XP, and an empty coin container.
- Add focused F04 verification while retaining the F00–F03 regression checks.

## Out of scope

- Upgrade-choice UI, pausing on level-up, selection queues, Vitality, Haste, or applying any upgrade from F05.
- Multishot, Piercing, Nova, or other combat ability behavior from F06.
- Coin magnet world pickups, health/bomb pickups, decorations, boss spawning, victory, or spawn-pressure scaling from F07–F09.
- Balance tuning beyond the specified thresholds and small centralized coin pickup/population values.
- Saves, meta-progression, additional currencies, loot tables, audio, external art, or third-party dependencies.

## Expected files

- `scenes/main.tscn` — add the XP coin container, progression node/resource wiring, coin scene reference, and live XP HUD integration.
- `scripts/game_controller.gd` — connect spawned-enemy death and coin collection signals, create or merge drops, and coordinate HUD/restart integration.
- `scripts/enemy_spawner.gd` — expose each successfully spawned normal enemy through a signal for focused integration.
- `scenes/xp_coin.tscn` and `scripts/xp_coin.gd` — reusable geometric XP coin, attraction/collection, stored XP value, and one-shot collection signal.
- `scripts/run_progression.gd` — finite threshold/carry-over state and XP, level, and level-up signals.
- `tests/verify_f04.gd` — focused drop, collection, cap/merge, threshold, HUD, defeat, and restart verification.
- `plans/F04_xp_coins_five_level_progression.md` and `PROGRESS.md` — implementation evidence and handoff state.

## Implementation steps

1. Re-run the F00–F03 baseline, confirm this plan still matches the project, and mark F04 `In progress` in `PROGRESS.md` before editing runtime files.
2. Add the focused progression script with the five required thresholds, level/current-XP state, carry-over processing that can cross multiple thresholds, completion clamping after five events, and signals suitable for HUD and F05 integration.
3. Add the XP coin scene/script with a positive configurable value, visible repository-native geometry, centralized attraction/collection tuning, target assignment, and idempotent collection that emits its awarded value once.
4. Expose successful spawns from `enemy_spawner.gd`; have the controller connect each normal enemy's existing one-shot death signal and create a coin at the captured death position without changing generic enemy damage behavior.
5. Add `World/XPCoins` and controller-owned capped drop handling. At the cap, merge the new value into a valid active coin so total earned XP is preserved while coin nodes remain bounded.
6. Route collected coin values into progression and wire progression changes to the existing level label, XP value, and progress bar, including an unambiguous completed state after threshold five.
7. Add deterministic seams where useful and implement `tests/verify_f04.gd` for one-shot drop/collection, attraction, cap/merge preservation, exact threshold/carry-over behavior, five-event limit, HUD updates, pause, restart, and prior-feature integration.
8. Run the full verification plan, perform the focused manual check, and record exact results in this plan and `PROGRESS.md`; mark F04 complete only if every criterion passes.

## Acceptance criteria

- [x] Every normal enemy killed through its existing damage/death path drops exactly one visible XP coin at the death position; freeing an enemy for cleanup or restarting a run does not create a drop.
- [x] Each coin stores a positive XP value, moves toward the valid living player when within a centralized attraction radius, awards its full value exactly once within a centralized collection radius, and removes itself after collection.
- [x] Active XP coin nodes never exceed a centralized positive cap during sustained kills; a drop created at the cap is merged into an active coin so the total uncollected XP value is preserved.
- [x] A new run starts at level 1 with zero XP and uses exactly the next-level requirements `[5, 9, 14, 20, 28]` in order.
- [x] Collected XP carries over after a threshold. One award may cross multiple thresholds and emits exactly one ordered level-up event per crossed threshold without losing XP.
- [x] After the fifth threshold, progression is complete at level 6, the HUD shows a clear completed XP state, and further XP cannot create another level or a sixth level-up event.
- [x] The existing level label, XP value label, and XP bar reflect the current progression state immediately after XP collection and threshold changes; before completion, the bar's maximum is the active threshold and its value is the carried current XP.
- [x] Defeat still pauses active gameplay, including coin attraction/collection, and restart creates a clean level-1 run with `0 / 5` XP, no pending progression from the previous run, and no retained enemies, projectiles, or XP coins.
- [x] F00–F03 movement, camera, arena, enemy cap/spawning, combat, health, defeat, and restart behavior remain functional.
- [x] The project imports/parses, F00–F03 regressions and focused F04 checks pass, and the configured main scene smoke-runs without parser, missing-resource, or runtime errors.
- [x] No upgrade UI/effects, procedural world pickups, decoration, boss, victory, save/meta-progression, third-party dependency, pathfinding, or hard body-blocking behavior is introduced.

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
  Expected: all exit 0 with their verification pass messages.
- Run the focused F04 check:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f04.gd`
  Expected: exit code 0 after exercising enemy-drop wiring, one-shot coin collection, attraction, cap/merge XP preservation, all five thresholds and carry-over, HUD updates, defeat pause, and clean restart.
- Smoke-run sustained spawning, combat, drops, and collection:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --quit-after 600`
  Expected: exit code 0 with no script/runtime errors or orphan-node warnings, and enemy/projectile/coin populations remain bounded.
- Check patch hygiene:
  `git diff --check`
  Expected: exit code 0.

### Manual

- Start a run and defeat several enemies. Confirm each combat death leaves one distinct visible coin where the enemy died and that coins begin moving toward the player only when approached.
- Move through attracted coins. Confirm each disappears on collection and the XP text/bar updates immediately; cross a threshold and confirm the level increases, carry-over remains visible, and gameplay does not yet show or pause for an upgrade screen.
- Continue until all five thresholds are crossed. Confirm the HUD reaches level 6 with a clear completed XP state and no further level increase occurs.
- Allow the player to be defeated with coins present, confirm the paused world and defeat UI remain correct, then click restart and confirm health, level/XP HUD, enemies, projectiles, and coins all return to a clean initial run.

## Completion notes

- Actual files changed: updated `scenes/main.tscn`, `scripts/enemy_spawner.gd`, and `scripts/game_controller.gd`; added `scenes/xp_coin.tscn`, `scripts/xp_coin.gd`, `scripts/run_progression.gd`, `tests/verify_f04.gd`, and the three Godot-generated script UID sidecars; updated this plan and `PROGRESS.md`.
- Commands/tests and results:
  - `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --version` — reported `4.7.1.stable.official.a13da4feb`.
  - Headless editor import/parser check — exit 0 with no parser or missing-resource errors.
  - F00, F01, F02, F03, and F04 verification scripts — all exited 0. F04 exercised exact combat drops, cleanup without drops, attraction and one-shot collection, cap merging with total-XP preservation, all five thresholds and carry-over, ordered level-up events, completion locking, immediate HUD updates, paused coins, and clean restart.
  - `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --quit-after 600` — exit 0 with no script/runtime errors or orphan-node warnings during sustained spawning, combat, drops, and collection.
  - `git diff --check` — exit 0.
- Manual checks performed: ran a temporary capture harness with the normal OpenGL renderer and visually inspected 1152×648 progression and completion frames. Six cyan geometric coins were distinct from the larger player, the level-2 `1 / 9` carry-over state and partial bar were readable, and level 6 showed `COMPLETE` with a full bar. The harness and captures were removed afterward. Physical keyboard/mouse play was not performed; combat drops, collection, pause, and restart were exercised by the focused automated verification.
- Deviations from plan: none. The controller owns the centralized coin cap and merges excess drops into the first valid active coin; progression remains a focused child node with reusable signals for F05.
- Remaining risks or follow-up: XP, attraction, and coin-cap values are initial prototype tuning for F09. F05 must decide how to queue or pause on the existing `level_up(level)` signal when one award crosses multiple thresholds.
