# F06 — Combat ability upgrades

- Status: Complete
- Roadmap dependency: F05
- Created: 2026-09-01
- Completed: 2026-09-01

## Objective

Replace F05's placeholder combat slot with one stable random non-maxed ability offer per level-up screen, and make the two ranks of Multishot, Piercing, and Nova immediately affect the current run while preserving the existing paused, queued, one-shot upgrade flow.

## Preflight and existing state

- F05 is complete. `scripts/game_controller.gd` owns the ordered paused-choice queue and guarded application flow, while `scripts/upgrade_choice_ui.gd` exposes exactly three buttons and a stable combat slot.
- `scripts/auto_weapon.gd` currently creates one nearest-target projectile per volley. `scripts/projectile.gd` already prevents duplicate hits and tracks a configurable hit allowance, giving Multishot and Piercing small focused extension points.
- Enemies expose reusable `take_damage()` behavior and the `normal_enemies` group. The player scene has no Nova node or combat-rank state yet.
- With Godot `4.7.1.stable.official.a13da4feb`, headless import/parser, F00–F05 verification, and `git diff --check` passed on 2026-09-01 before this plan was written. The existing dirty working tree contains the completed F05 implementation and documentation; preserve it.

## In scope

- Track separate Multishot, Piercing, and Nova ranks from 0 through 2 for the current run, with stable identifiers and centralized ability metadata.
- When each queued choice screen opens, randomly choose one ability below rank 2, show its name and next-rank effect in the combat button, and retain that exact offer until the screen is resolved.
- Apply only the offered ability when the combat slot is selected. Vitality and Haste remain available and unchanged; choosing either must not alter combat ranks.
- Multishot rank 1 fires two projectiles per volley with a small centered spread, and rank 2 fires three. All projectiles still target from the existing nearest-enemy aim and retain bounded lifetime behavior.
- Piercing ranks 1 and 2 increase every subsequently fired projectile's total enemy hit allowance from the base one to two and three respectively, without allowing the same projectile to damage one enemy twice.
- Nova rank 1 emits a readable radial pulse about every 5 seconds that damages living normal enemies in its configured radius. Rank 2 uses higher centralized damage and an interval of about 3.5 seconds; its visual effect must be transient or reused so it cannot grow nodes without limit.
- Preserve pause/queue guards, defeat, progression, HUD, clean restart, and all F00–F05 behavior. Add focused F06 verification.

## Out of scope

- Additional abilities, rank 3+, weapon selection, cooldown upgrades, upgrade history UI, rerolls, or rebalancing Vitality/Haste.
- Procedural decorations, Health/Magnet/Bomb pickups, or any other F07 work.
- Boss spawning, boss-specific Nova behavior, boss health UI, victory, or the fifth-selection transition from F08.
- Final run-length tuning, production effects, audio, animation polish, external art, saves, meta-progression, or third-party dependencies.
- Broad combat architecture refactors or a generic data-driven ability framework beyond the three fixed abilities.

## Expected files

- `scripts/game_controller.gd` — own current-run ability ranks, stable random combat offers, guarded application, and testable rank/offer accessors.
- `scripts/upgrade_choice_ui.gd` — accept and display the offered ability's name, next rank, and effect without changing the three-button layout or one-shot guard.
- `scripts/auto_weapon.gd` — apply ranked projectile count/spread and pass the current piercing allowance to new projectiles.
- `scripts/projectile.gd` — accept per-shot hit allowance configuration while preserving lifetime and duplicate-hit protection.
- `scenes/player.tscn` and a focused Nova script such as `scripts/nova_ability.gd` with its Godot UID sidecar — timer, radius damage, and bounded geometric pulse presentation.
- `scenes/main.tscn` only if controller/node references require explicit scene wiring.
- `tests/verify_f06.gd` with its Godot UID sidecar — deterministic offer/rank, Multishot, Piercing, Nova, pause, restart, and regression checks.
- `plans/F06_combat_ability_upgrades.md` and `PROGRESS.md` — completion evidence and next-feature handoff.

## Implementation steps

1. Re-run the F00–F05 baseline, confirm this plan still matches the working tree, and mark F06 `In progress` in `PROGRESS.md` before runtime edits.
2. Add the three stable ability identifiers, rank-0-to-2 state, next-rank metadata, and a controllable random-selection seam. Choose only below-max abilities when a screen opens and store the offer with that open screen so redraws or queued events cannot reroll it.
3. Extend the existing UI/controller handshake to display the stored ability and next-rank description, then apply exactly that ability through F05's one-shot choice path. Keep Vitality, Haste, stale-token rejection, selection counts, and pause/resume ordering intact.
4. Extend `AutoWeapon` and projectile configuration for centered two-/three-projectile Multishot volleys and total hit allowances of one/two/three from Piercing, using centralized tunables and preserving nearest-target, duplicate-hit, lifetime, and collision behavior.
5. Add a small player-owned Nova component with centralized rank values, a paused gameplay timer, radius-filtered normal-enemy damage, and a readable bounded geometric pulse. Rank changes must take effect immediately without creating duplicate timers or accumulating effect nodes.
6. Add deterministic `verify_f06.gd` coverage for offer stability/filtering, independent rank caps, every rank effect, queued paused choices, restart reset, and F00–F05 regressions.
7. Run the full verification plan, perform the focused manual check, then record exact results in this plan and `PROGRESS.md`. Mark F06 complete only after every criterion is verified.

## Acceptance criteria

- [x] Every open level-up screen still contains exactly Vitality, Haste, and one combat button; the combat button names one randomly selected ability below rank 2 and accurately describes the next rank it will grant.
- [x] The offered ability is selected once when that screen opens and does not reroll while it remains open. A later queued screen receives its own eligible offer, and rank-2 abilities are never offered again.
- [x] Selecting the combat button raises exactly the displayed ability by one rank, never above rank 2, and applies its effect immediately. Vitality or Haste selection changes no combat rank.
- [x] Multishot fires one projectile at rank 0, two at rank 1, and three at rank 2 in a small centered spread; all projectiles preserve nearest-target aiming, damage, collision, lifetime, and bounded cleanup.
- [x] Piercing rank 0/1/2 gives newly fired projectiles total hit allowances of 1/2/3 respectively. A projectile can damage that many distinct enemies but cannot damage the same enemy twice.
- [x] Nova is inactive at rank 0. Rank 1 visibly pulses about every 5 seconds and damages each living normal enemy inside its configured radius once; rank 2 has higher damage and pulses about every 3.5 seconds, while enemies outside the radius are unaffected.
- [x] Nova timing and all other gameplay remain frozen while an upgrade or defeat overlay pauses the tree, and the Nova visual/timer implementation does not accumulate unbounded nodes or parallel timers.
- [x] F05's queued one-screen-per-level behavior, stale/double-selection guards, five-selection cap, Vitality/Haste formulas, defeat flow, and selection signals remain correct.
- [x] Restart reloads base single-shot/non-piercing behavior, all three ability ranks at 0, no active Nova pulse/timer progress carried from the old run, no stored offer, and clean F00–F05 entities/progression/UI state.
- [x] The project imports/parses, F00–F05 regressions and focused F06 checks pass, and the configured main scene smoke-runs without parser, missing-resource, runtime, or orphan-node errors.
- [x] No F07 pickup/decoration, F08 boss/victory, save/meta-progression, third-party dependency, pathfinding, or unrelated feature is introduced.

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
  Expected: all exit 0 with their verification pass messages.
- Run the focused F06 check:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f06.gd`
  Expected: exit 0 after deterministic checks of eligible stable offers, independent two-rank caps, exact volley/hit counts, Nova timing/damage/radius/pause behavior, queue guards, and clean restart.
- Smoke-run the configured main scene:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --quit-after 600`
  Expected: exit 0 with no script/runtime or orphan-node errors; an unattended level-up may leave the run safely paused at its choice screen.
- Check patch hygiene:
  `git diff --check`
  Expected: exit code 0.

### Manual

- Reach several level-ups and inspect each combat button before selecting. Confirm its ability/rank description remains unchanged while open, selection immediately changes combat, and a max-rank ability no longer appears.
- Obtain both Multishot ranks and visually confirm centered two- then three-projectile volleys. Obtain both Piercing ranks and confirm one projectile can pass through two then three distinct clustered enemies without re-hitting one enemy.
- Obtain Nova rank 1 and observe a readable pulse damaging nearby enemies about every 5 seconds; upgrade to rank 2 and confirm stronger, faster pulses around 3.5 seconds. Open an upgrade screen between pulses and confirm the world and Nova timing freeze.
- Trigger defeat and restart after applying abilities; confirm the new run returns to one projectile, one hit, no Nova, zero ability ranks, and a hidden choice screen.

## Completion notes

- Actual files changed: `scripts/game_controller.gd`, `scripts/upgrade_choice_ui.gd`, `scripts/auto_weapon.gd`, `scripts/projectile.gd`, `scripts/nova_ability.gd` and its UID sidecar, `scenes/player.tscn`, `tests/verify_f06.gd` and its UID sidecar, this plan, and `PROGRESS.md`.
- Commands/tests and results: with Godot `4.7.1.stable.official.a13da4feb`, headless editor import/parser, `verify_f00.gd` through `verify_f06.gd`, the configured main scene for 600 fixed-FPS frames, and `git diff --check` all exited 0 on 2026-09-01. The focused test deterministically covers stable/max-rank-filtered offers, exact independent ranks, one/two/three-shot centered volleys, one/two/three-hit piercing with duplicate rejection, both Nova timings/damage/radius behavior, paused upgrade and defeat states, bounded pulse presentation, queue guards, and clean restart.
- Manual checks performed: rendered with the normal OpenGL compatibility renderer and visually inspected the level-2 Multishot rank-1 offer at 800×450 and a 1152×648 combat frame with the rank-2 three-projectile spread, readable Nova ring, player, and nearby enemies. Text and cards were readable without clipping, the volley was centered, and the Nova radius was visually distinct. The temporary harness and captures were removed afterward. Physical mouse/keyboard play was not performed; selection, combat effects, pause, defeat, and restart were exercised by `verify_f06.gd`.
- Deviations from plan: `scenes/main.tscn` needed no F06-specific wiring because the player-owned weapon and Nova component are discovered through the existing player scene. A small forced-offer seam was added for deterministic verification; production offers still use a per-run randomized eligible selection.
- Remaining risks or follow-up: combat feel and final damage/radius/spread balance remain for F09. F08 must decide how Nova interacts with the boss without changing F06's normal-enemy-only behavior prematurely.
