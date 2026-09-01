# F05 — Upgrade choice UI and stat upgrades

- Status: Complete
- Roadmap dependency: F04
- Created: 2026-09-01
- Completed: 2026-09-01

## Objective

Turn each F04 level-up event into one paused, mouse-selectable screen containing exactly three stable choices: repeatable Vitality and Haste upgrades that affect the current run immediately, plus a combat-choice slot and selection seam that F06 can populate with real ability offers.

## Preflight and existing state

- F04 is complete. `RunProgression` emits one ordered `level_up(level)` signal per crossed threshold, including several synchronous events from one XP award, and stops after exactly five events at level 6.
- `scripts/game_controller.gd` already coordinates progression, HUD, defeat pause, and scene-reload restart. `scenes/main.tscn` has a viewport-fixed `CanvasLayer` and a paused-process defeat overlay but no level-up UI or pending-choice state.
- `scripts/player.gd` exposes centralized `maximum_health`, `current_health`, and `movement_speed`, but has no focused methods for increasing maximum health/healing or multiplying movement speed.
- The F04 implementation is present as expected in the working tree; no unrelated modifications were detected. With Godot `4.7.1.stable.official.a13da4feb`, headless import/parser, F00–F04 verification, and `git diff --check` passed on 2026-09-01.

## In scope

- Add a readable responsive level-up overlay that processes while paused and presents exactly three mouse-selectable choices: Vitality, Haste, and one stable combat-choice slot.
- Open one choice screen for every `RunProgression.level_up` event and pause gameplay before the player can continue.
- Queue multiple level-up events from one XP award. Present them one at a time, keep gameplay paused between pending choices, and resume only after the queue is empty.
- Apply Vitality as exactly `+20` maximum health and `+20` current health capped at the new maximum; allow repeated selections and refresh the health HUD immediately.
- Apply Haste as a multiplicative `+12%` to the player's current movement speed; allow repeated selections so increases compound and affect movement immediately.
- Make the combat slot selectable through the same one-shot choice flow, with stable option metadata and a dedicated signal/identifier for F06. It intentionally applies no combat ability or rank in F05.
- Track exactly one applied selection per resolved level-up and expose a small selection-count/signal seam for the later boss transition; do not start the boss in F05.
- Preserve defeat, XP/progression, clean restart, and all earlier gameplay behavior; a reload must restore base health/speed, zero applied selections, no pending choices, and a hidden overlay.
- Add focused F05 verification while retaining the F00–F04 regressions.

## Out of scope

- Randomly choosing Multishot, Piercing, or Nova; ability ranks, projectile changes, Nova pulses, max-rank filtering, or final combat-option text from F06.
- Boss spawning after the fifth selection, boss health UI, victory, or normal-spawn transition from F08.
- Procedural decorations, health/magnet/bomb world pickups, spawn-pressure scaling, or final balance/readability tuning from F07–F09.
- Keyboard/controller choice navigation, rerolls, upgrade history, saves, meta-progression, audio, animation polish, external art, or third-party dependencies.
- Refactoring F04 threshold/carry-over behavior or changing the five required XP values.

## Expected files

- `scenes/main.tscn` — instance the paused-process upgrade overlay in the existing HUD and wire any controller paths.
- `scenes/upgrade_choice_ui.tscn` and `scripts/upgrade_choice_ui.gd` — responsive three-choice presentation, stable choice identifiers/content, one-shot button handling, and selection signal.
- `scripts/game_controller.gd` — connect level-up events, queue pending screens, coordinate pause/resume, apply choices, count selections, and preserve defeat/restart rules.
- `scripts/player.gd` — add focused repeatable Vitality and Haste application methods that emit/update existing state cleanly.
- `tests/verify_f05.gd` — focused UI, pause, queue, stat, one-shot selection, combat-slot seam, defeat, and restart verification.
- `plans/F05_upgrade_choice_ui_stat_upgrades.md` and `PROGRESS.md` — implementation evidence and handoff state.

## Implementation steps

1. Re-run the F00–F04 baseline, confirm this plan still matches the project, and mark F05 `In progress` in `PROGRESS.md` before runtime edits.
2. Add focused player methods for the exact Vitality and Haste formulas, keeping values centralized and using the existing health signal so HUD state changes immediately.
3. Build the responsive paused-process overlay with exactly three readable buttons/cards, stable choice identifiers, and guarded one-shot selection emission; keep combat metadata fixed for the lifetime of an open screen.
4. Connect `RunProgression.level_up` to a controller-owned pending-choice queue. Pause on the first event, resolve one screen per event, remain paused while work is pending, then resume without disturbing completed progression.
5. Route Vitality, Haste, and the combat placeholder through the same selection flow, track applied selection count, and expose the combat/selection seam needed by F06/F08 without implementing either later feature.
6. Preserve defeat and reload behavior, including clean base stats and empty UI/queue state, and add deterministic seams plus `tests/verify_f05.gd` for focused integration coverage.
7. Run the full verification plan, perform the focused manual check, and record exact results in this plan and `PROGRESS.md`; mark F05 complete only when every criterion passes.

## Acceptance criteria

- [x] Each F04 level-up event opens a readable overlay containing exactly three stable mouse-selectable choices labeled/described as Vitality, Haste, and a combat ability slot; no reroll or fourth choice appears while it is open.
- [x] While a choice is open, the scene tree is paused: player movement, enemies, spawning, projectiles, and XP coins cannot process, while all three choice buttons remain operable.
- [x] Selecting Vitality once increases maximum health by exactly 20 and current health by exactly 20 capped at the new maximum; repeat selections apply the same increments and the health HUD updates immediately.
- [x] Selecting Haste once multiplies the current movement speed by exactly `1.12`; repeat selections compound from the upgraded value and `calculate_velocity()` immediately uses the new speed.
- [x] Selecting the combat slot resolves exactly one pending choice and emits/exposes its stable combat identifier for F06 without changing projectile, piercing, Nova, or ability-rank behavior in F05.
- [x] A choice can be applied only once. Double presses or stale callbacks cannot apply two upgrades, increment the applied-selection count twice, or consume more than one pending event.
- [x] If one XP award crosses multiple thresholds, exactly one choice screen is resolved per ordered level-up event; gameplay stays paused between queued screens and resumes only after the final pending selection.
- [x] The applied-selection count starts at zero, reaches at most five from the five F04 events, and exposes a reusable signal/state seam without spawning a boss or showing victory.
- [x] Existing defeat remains readable and restartable, and scene reload restores base health and speed, zero selections, an empty pending queue, hidden choice UI, level 1 with `0 / 5` XP, and empty enemy/projectile/coin containers.
- [x] F00–F04 movement, arena, spawning, combat, damage/invulnerability, defeat, XP drops/collection/cap, threshold carry-over, HUD, completion, and restart behavior remain functional.
- [x] The project imports/parses, F00–F04 regressions and focused F05 checks pass, and the main scene smoke-runs without parser, missing-resource, runtime, or orphan-node errors.
- [x] No combat ability effect/rank, procedural pickup/decoration, boss/victory, save/meta-progression, third-party dependency, pathfinding, or hard body-blocking behavior is introduced.

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
  Expected: all exit 0 with their verification pass messages.
- Run the focused F05 check:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f05.gd`
  Expected: exit 0 after exercising exact three-choice content, pause/process modes, Vitality/Haste formulas and repetition, one-shot combat selection, multi-event queue order, selection count, defeat compatibility, and clean restart.
- Smoke-run the configured main scene:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --quit-after 600`
  Expected: exit 0 with no script/runtime or orphan-node errors; reaching a threshold may leave the unattended run safely paused at its choice screen.
- Check patch hygiene:
  `git diff --check`
  Expected: exit code 0.

### Manual

- Reach the first XP threshold. Confirm the world freezes behind a readable three-choice overlay and that Vitality, Haste, and the combat slot are the only choices.
- Take damage before choosing Vitality; click it and confirm maximum/current health and the HUD increase by 20, then repeat at a later level to confirm the upgrade remains available.
- Record the feel of base movement, choose Haste, and confirm movement becomes faster immediately; choose it again later and confirm the increase compounds.
- Cross multiple thresholds with one merged/high-value coin or a verification setup. Resolve each queued screen and confirm the world never advances between screens, then resumes after the last choice.
- Select the combat slot once and confirm it closes normally without adding an F06 ability yet. After several upgrades, reach defeat and restart; confirm base stats, progression, entities, and the hidden choice UI are clean.

## Completion notes

Fill this in during implementation:

- Actual files changed: `scenes/main.tscn`, `scenes/upgrade_choice_ui.tscn`, `scripts/game_controller.gd`, `scripts/player.gd`, `scripts/upgrade_choice_ui.gd` and its UID sidecar, `tests/verify_f05.gd` and its UID sidecar, this plan, and `PROGRESS.md`.
- Commands/tests and results: with Godot `4.7.1.stable.official.a13da4feb`, headless editor import/parser, `verify_f00.gd` through `verify_f05.gd`, the configured main scene for 600 fixed-FPS frames, and `git diff --check` all exited 0 on 2026-09-01. The focused check covers exact formulas and repetition, three stable choices, paused processing, stale/double selection guards, ordered multi-level queuing, the combat seam, the one-to-five selection signal/count, defeat, and clean restart.
- Manual checks performed: ran a temporary capture harness with the normal OpenGL renderer and visually inspected the open level-2 choice screen at 1152×648 and 800×450. The dimmed paused arena, centered panel, level heading, and all three distinct choice buttons were readable without clipping at both sizes. The harness and captures were removed afterward. Physical mouse/keyboard play was not performed; button selection, pause behavior, upgrade effects, queue handling, and restart were exercised by `verify_f05.gd`.
- Deviations from plan: the F05 combat slot uses intentionally fixed placeholder metadata and emits `combat_choice_selected(&"combat")`; F06 remains responsible for replacing that placeholder with a stable randomly selected non-maxed ability offer. No other scope deviation.
- Remaining risks or follow-up: physical gameplay feel and final balance remain for F09. F06 must populate the combat slot without weakening the existing one-shot token guard or queued pause flow.
