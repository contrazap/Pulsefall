# Pulsefall — Progress Ledger

Last documentation update: 2026-09-01

## Current state

- Overall status: F00–F04 complete; F05 planned.
- Last completed feature: F04 — XP coins and five-level progression.
- Current feature: F05 — Upgrade choice UI and stat upgrades is planned.
- Next feature: F05 — Upgrade choice UI and stat upgrades.
- Next action: Implement F05 from `plans/F05_upgrade_choice_ui_stat_upgrades.md`, beginning with the documented baseline checks and `In progress` ledger update.
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
| F05 | Upgrade choice UI and stat upgrades | Planned | `plans/F05_upgrade_choice_ui_stat_upgrades.md` | — | Planning baseline passed Godot 4.7.1 import/parser, F00–F04 checks, and `git diff --check` on 2026-09-01. |
| F06 | Combat ability upgrades | Not started | — | — | — |
| F07 | Procedural decorations and world pickups | Not started | — | — | — |
| F08 | Boss phase and victory | Not started | — | — | — |
| F09 | Final integration and tuning | Not started | — | — | — |

## Verification baseline

F00 established a runnable Godot project and repeatable verification baseline.

F01 added a moving player, following camera, and bounded camera-relative repeating grid. On 2026-08-31, the headless import, F00 regression, focused F01 verification, and main-scene smoke commands passed. Rendered 1152×648 initial/traveled frames and an 800×450 resized frame were visually inspected successfully; the travel capture reached player world X about 1595 while remaining centered.

F02 added a reusable direct-chasing normal enemy and a timer-driven, camera-aware spawner with centralized interval, margin, and hard population cap. On 2026-08-31, import/parser, F00/F01 regressions, focused F02 verification, a 600-iteration smoke run, and `git diff --check` passed. Rendered populated origin and traveled frames were inspected; after player world X reached about 1915, enemy presentation and camera-relative behavior, floor coverage, and fixed HUD remained correct.

F03 added nearest-target automatic fire, visible bounded projectiles, reusable enemy/player health and damage, contact invulnerability, soft enemy/enemy and enemy/player separation, a live health HUD, and a paused defeat screen with clean restart. On 2026-09-01, import/parser, F00–F03 verification, a 600-iteration combat smoke run, and `git diff --check` passed. Rendered combat and defeat frames were inspected successfully. F03 verification also reloads the current scene and proves full health, cleared invulnerability, empty entity containers, hidden defeat UI, and restored spawn/fire timers.

F04 added one-shot geometric XP drops for normal-enemy combat deaths, player attraction and collection, a centralized 40-coin cap that preserves excess drop value by merging, five finite XP thresholds with carry-over and ordered level-up events, and live level/XP HUD states through level-6 completion. On 2026-09-01, import/parser, F00–F04 verification, a 600-iteration gameplay smoke run, and `git diff --check` passed. Rendered level-2 carry-over and level-6 completion frames were inspected successfully; focused verification also proved paused coins and a clean level-1 restart with empty entity containers.

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
- No known F04 runtime issue is blocking F05 planning. Initial combat and XP values remain subject to F09 tuning.

## Decision log

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-08-30 | Use the name Pulsefall. | Fits the neon pulse ability and escalating enemy swarm. |
| 2026-08-30 | End runs after five upgrade selections and one boss rather than a timer. | Preserves the desired progression loop while bounding run length and implementation scope. |
| 2026-08-30 | Use an endless-looking unobstructed arena rather than procedural terrain topology. | Provides the intended presentation without requiring pathfinding or chunk persistence complexity. |
| 2026-08-30 | Split work into F00–F09 and create detailed feature plans just in time. | Lets independent sessions use current code and verification evidence instead of stale up-front assumptions. |
| 2026-08-31 | Schedule lightweight enemy/enemy and enemy/player separation for F03. | The F02 manual play check showed exact stacking reduces crowd readability; F03 already owns contact and damage behavior. |

## Latest handoff

F04 is complete and F05 is planned in `plans/F05_upgrade_choice_ui_stat_upgrades.md`. The planning baseline passed import/parser, F00–F04 checks, and `git diff --check` on 2026-09-01. The next session should implement only F05: queued paused three-choice screens, repeatable Vitality/Haste, a one-shot combat-choice seam, applied-selection tracking, and clean restart, while leaving combat ability effects and later systems out of scope.
