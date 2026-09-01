# Pulsefall — Progress Ledger

Last documentation update: 2026-09-01

## Current state

- Overall status: F00–F07 complete; F08–F09 planned.
- Last completed feature: F07 — Procedural decorations and world pickups.
- Current feature: F08 — Boss phase and victory is planned.
- Next feature: F08 — Boss phase and victory.
- Next action: Revalidate `plans/F08_boss_phase_victory.md` against the completed F07 population/pickup APIs, then implement F08.
- Known blockers: None.

## Roadmap status

Allowed statuses: `Not started`, `Planned`, `In progress`, `Blocked`, `Complete`.

| ID | Feature | Status | Plan | Implementation evidence | Verification evidence |
| --- | --- | --- | --- | --- | --- |
| F00 | Project foundation | Complete | `plans/F00_project_foundation.md` | `project.godot`, `scenes/main.tscn`, `.gitignore`, and `tests/verify_f00.gd` with its Godot UID sidecar. | Godot 4.7.1 version, headless import, F00 verification script, and headless main-scene smoke run passed; rendered default and resized frames visually checked. |
| F01 | Player and endless-looking arena | Complete | `plans/F01_player_endless_arena.md` | `scenes/player.tscn`, `scripts/player.gd`, `scripts/arena_grid.gd`, and integration in `scenes/main.tscn`. | Import/parser, F00 regression, focused F01 verification, headless smoke run, and rendered default/traveled/resized frame inspection passed. |
| F02 | Normal enemy and spawn system | Complete | `plans/F02_normal_enemy_spawn_system.md` | `scenes/enemy.tscn`, `scripts/enemy.gd`, `scripts/enemy_spawner.gd`, `scenes/main.tscn`, and `tests/verify_f02.gd` with Godot UID sidecars. | Import/parser, F00/F01 regressions, focused F02 verification, 600-iteration smoke run, diff check, and rendered origin/traveled frame inspection passed on 2026-08-31. |
| F03 | Auto-combat, damage, and defeat | Complete | `plans/F03_auto_combat_damage_defeat.md` | Player/enemy health and damage, nearest-target auto-weapon, bounded projectile, soft separation, live health HUD, paused defeat overlay, and clean restart in the F03 runtime files. | Godot 4.7.1 import/parser, F00–F03 checks, 600-iteration combat smoke run, `git diff --check`, and rendered combat/defeat frame inspection passed on 2026-09-01. |
| F04 | XP coins and five-level progression | Complete | `plans/F04_xp_coins_five_level_progression.md` | Bounded geometric XP drops, attraction/collection, cap merging, five-threshold carry-over progression, reusable level-up events, live HUD, pause, and clean restart integration. | Godot 4.7.1 import/parser, F00–F04 checks, 600-iteration smoke run, `git diff --check`, and rendered progression/completion inspection passed on 2026-09-01. |
| F05 | Upgrade choice UI and stat upgrades | Complete | `plans/F05_upgrade_choice_ui_stat_upgrades.md` | Responsive paused three-choice overlay, ordered pending-choice queue, repeatable Vitality/Haste, guarded combat placeholder seam, applied-selection count/signal, defeat compatibility, and clean restart. | Godot 4.7.1 import/parser, F00–F05 checks, 600-frame smoke run, `git diff --check`, and rendered 1152×648/800×450 choice-screen inspection passed on 2026-09-01. |
| F06 | Combat ability upgrades | Complete | `plans/F06_combat_ability_upgrades.md` | Stable eligible ability offers, independent two-rank state, centered Multishot volleys, per-shot Piercing allowances, and a player-owned reusable Nova timer/pulse. | Godot 4.7.1 import/parser, F00–F06 checks, 600-frame smoke run, `git diff --check`, and rendered 800×450 offer/1152×648 combat inspection passed on 2026-09-01. |
| F07 | Procedural decorations and world pickups | Complete | `plans/F07_procedural_decorations_world_pickups.md` | Recycled 28-decoration population, capped shuffled-bag Health/Magnet/Bomb pickups, focused player healing, and controller-owned XP/normal-enemy effects. | Godot 4.7.1 import/parser, F00–F07 checks, 600-frame smoke run, `git diff --check`, and rendered 1152×648 origin/traveled inspection passed on 2026-09-01. |
| F08 | Boss phase and victory | Planned | `plans/F08_boss_phase_victory.md` | — | Pre-F07 implementation planning baseline passed Godot 4.7.1 import/parser, F00–F06 checks, a 600-frame smoke run, and `git diff --check` on 2026-09-01; implementation remains gated on F07 completion. |
| F09 | Final integration and tuning | Planned | `plans/F09_final_integration_tuning.md` | — | Planning baseline passed Godot 4.7.1 import/parser, F00–F06 checks, a 600-frame smoke run, and `git diff --check` on 2026-09-01; implementation remains gated on completed F07/F08 evidence. |

## Verification baseline

F00 established a runnable Godot project and repeatable verification baseline.

F01 added a moving player, following camera, and bounded camera-relative repeating grid. On 2026-08-31, the headless import, F00 regression, focused F01 verification, and main-scene smoke commands passed. Rendered 1152×648 initial/traveled frames and an 800×450 resized frame were visually inspected successfully; the travel capture reached player world X about 1595 while remaining centered.

F02 added a reusable direct-chasing normal enemy and a timer-driven, camera-aware spawner with centralized interval, margin, and hard population cap. On 2026-08-31, import/parser, F00/F01 regressions, focused F02 verification, a 600-iteration smoke run, and `git diff --check` passed. Rendered populated origin and traveled frames were inspected; after player world X reached about 1915, enemy presentation and camera-relative behavior, floor coverage, and fixed HUD remained correct.

F03 added nearest-target automatic fire, visible bounded projectiles, reusable enemy/player health and damage, contact invulnerability, soft enemy/enemy and enemy/player separation, a live health HUD, and a paused defeat screen with clean restart. On 2026-09-01, import/parser, F00–F03 verification, a 600-iteration combat smoke run, and `git diff --check` passed. Rendered combat and defeat frames were inspected successfully. F03 verification also reloads the current scene and proves full health, cleared invulnerability, empty entity containers, hidden defeat UI, and restored spawn/fire timers.

F04 added one-shot geometric XP drops for normal-enemy combat deaths, player attraction and collection, a centralized 40-coin cap that preserves excess drop value by merging, five finite XP thresholds with carry-over and ordered level-up events, and live level/XP HUD states through level-6 completion. On 2026-09-01, import/parser, F00–F04 verification, a 600-iteration gameplay smoke run, and `git diff --check` passed. Rendered level-2 carry-over and level-6 completion frames were inspected successfully; focused verification also proved paused coins and a clean level-1 restart with empty entity containers.

F05 added a responsive always-process level-up overlay with exactly three stable choices, controller-owned queuing for synchronous multi-level awards, exact repeatable Vitality and Haste formulas, guarded one-shot/stale-token handling, a no-effect combat-choice signal for F06, and reusable applied-selection state capped at five. On 2026-09-01, import/parser, F00–F05 verification, a 600-frame gameplay smoke run, and `git diff --check` passed. Rendered 1152×648 and 800×450 level-2 screens were inspected successfully; focused verification also proved paused gameplay nodes, ordered queued screens, immediate HUD/stat effects, defeat compatibility, and a clean restart.

F06 replaced the placeholder combat card with one stable random non-maxed Multishot, Piercing, or Nova offer per screen and independent ranks capped at two. Multishot now fires centered one/two/three-projectile volleys, Piercing configures new projectiles for one/two/three distinct hits, and the player-owned Nova uses one paused timer plus a reused drawn pulse at 5.0/3.5-second rank intervals. On 2026-09-01, import/parser, F00–F06 verification, a 600-frame gameplay smoke run, and `git diff --check` passed. Rendered 800×450 offer and 1152×648 combat frames were inspected successfully; focused verification also proved offer stability/filtering, immediate rank effects, pause/defeat behavior, bounded presentation, and clean restart.

F07 added a draw-only recycled population of 28 subtle neon decorations plus a capped set of three procedurally placed Health, Magnet, and Bomb pickups. Health uses a clamped signal-emitting player heal, Magnet snapshots active XP coins and invokes their existing idempotent collection path, and Bomb snapshots only `normal_enemies` and uses their normal damage/death/XP-drop path. On 2026-09-01, import/parser, F00–F07 verification, a 600-frame gameplay smoke run, and `git diff --check` passed. Rendered 1152×648 origin and far-traveled frames were inspected successfully; focused verification also proved annulus placement, node recycling, all caps, type readability, one-shot collection, merged XP carry-over and upgrade pause, boss-safe group filtering, defeat pause, replenishment, and clean restart.

Local Godot environment verified on 2026-08-30:

- GUI executable: `C:\MyFiles\Godot\Godot_v4.7.1-stable_win64.exe`
- Console executable for command-line checks: `C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe`
- Version command: `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --version`
- Version result: `4.7.1.stable.official.a13da4feb`

Passing F00 commands on 2026-08-30:

- Headless import/parser check: `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path . --quit`
- Focused foundation check: `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f00.gd`
- Main-scene smoke run: `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 2`
- Visual check: rendered and inspected the HUD at the default window and a requested 800×450 resized window; both passed after correcting the responsive stat layout.

## Active blockers and known issues

- No blockers.
- No known runtime issue blocks F08 implementation. Its planned assumptions should now be revalidated against F07's `WorldPopulation` signal/API and controller-owned `normal_enemies` Bomb filter; balance remains subject to F09 tuning.

## Decision log

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-08-30 | Use the name Pulsefall. | Fits the neon pulse ability and escalating enemy swarm. |
| 2026-08-30 | End runs after five upgrade selections and one boss rather than a timer. | Preserves the desired progression loop while bounding run length and implementation scope. |
| 2026-08-30 | Use an endless-looking unobstructed arena rather than procedural terrain topology. | Provides the intended presentation without requiring pathfinding or chunk persistence complexity. |
| 2026-08-30 | Split work into F00–F09 and create detailed feature plans just in time. | Lets independent sessions use current code and verification evidence instead of stale up-front assumptions. |
| 2026-08-31 | Schedule lightweight enemy/enemy and enemy/player separation for F03. | The F02 manual play check showed exact stacking reduces crowd readability; F03 already owns contact and damage behavior. |

## Latest handoff

F00–F07 are complete and F08–F09 are planned in their feature files. F07's final verification passed import/parser, F00–F07 checks, a 600-frame smoke run, `git diff --check`, and rendered origin/far-traveled inspection on 2026-09-01. Revalidate `plans/F08_boss_phase_victory.md` against the completed `WorldPopulation` pickup signal and controller-owned Bomb filter, then implement the fifth-selection boss transition, shared combat targeting, boss health UI, victory, and restart.
