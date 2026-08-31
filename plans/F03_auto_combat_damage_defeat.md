# F03 — Auto-combat, damage, and defeat

- Status: Planned
- Roadmap dependency: F02
- Created: 2026-08-31
- Completed: —

## Objective

Complete the first combat loop: the player automatically fires bounded projectiles at the nearest normal enemy, enemies and the player have reusable damage/health behavior, contact damage respects a brief invulnerability window, soft separation keeps crowds readable, and reaching zero player health produces a restartable defeat state.

## Preflight and existing state

- F02 is complete. `scenes/main.tscn` contains the moving player and camera, the repeating arena, a dedicated `World/Enemies` container, and a timer-driven off-screen spawner capped at 24 normal enemies.
- `scenes/enemy.tscn` is a reusable `CharacterBody2D` in the `normal_enemies` group with a collision shape and direct-chase script. It currently has no health, damage, death, contact behavior, or separation and can stack exactly with other enemies.
- `scenes/player.tscn` has movement and a camera but no collision/detection shape, health state, weapon, or damage behavior. The HUD health value is still the F00 placeholder, and `Main` has no gameplay-state controller or defeat overlay.
- The worktree was clean when this plan was created. With Godot `4.7.1.stable.official.a13da4feb`, headless import, F00/F01/F02 verification, a 600-iteration main-scene smoke run, and `git diff --check` all passed on 2026-08-31.

## In scope

- Add centralized player maximum/current health, enemy health, projectile damage/speed/lifetime/hit allowance, weapon fire interval, enemy contact damage, and player invulnerability tuning.
- Add a focused auto-weapon component that periodically selects the nearest valid living enemy and fires a visible projectile toward it; do nothing safely when no target exists.
- Add a reusable projectile with bounded lifetime and hit allowance, enemy damage/death handling, and collision/detection wiring that does not create hard body blocking.
- Add player contact damage with a brief invulnerability window, immediate health-HUD updates, and readable placeholder hit/death feedback.
- Add lightweight local enemy/enemy and enemy/player separation while retaining direct chase, allowing bunching and partial overlap without exact stacking or trapping the player.
- Add a single run-state coordinator for defeat, stopping or pausing active gameplay at zero health, showing a defeat overlay, and restarting into a clean initial main scene.
- Add focused F03 verification while retaining the F00–F02 regression checks.

## Out of scope

- XP coin drops, collection, thresholds, levels, or progression from F04. Enemy death in F03 must not create XP.
- Upgrade choices, Multishot, Piercing ranks beyond the projectile's base hit-allowance seam, Nova, or other combat abilities from F05/F06.
- Decorations, world pickups, boss behavior, victory, spawn-pressure scaling, or final balance tuning from F07–F09.
- Hard enemy/player body blocking, navigation, pathfinding, obstacle avoidance, multiple weapons/enemy types, external art, audio, or elaborate animation.

## Expected files

- `scenes/main.tscn` — add projectile containment, gameplay-state wiring, live health HUD integration, and the defeat/restart overlay.
- `scripts/game_controller.gd` — coordinate health display, defeat state, gameplay stop/pause, and clean restart.
- `scenes/player.tscn` and `scripts/player.gd` — add damage detection, health/invulnerability state, signals, and the auto-weapon component.
- `scripts/auto_weapon.gd` — nearest-target selection and timer-driven projectile firing.
- `scenes/projectile.tscn` and `scripts/projectile.gd` — reusable visible projectile movement, hit allowance, damage, and lifetime cleanup.
- `scenes/enemy.tscn` and `scripts/enemy.gd` — add reusable health/damage/death, contact behavior, and soft separation.
- `tests/verify_f03.gd` — focused combat, damage, separation, defeat, and restart verification.
- `plans/F03_auto_combat_damage_defeat.md` and `PROGRESS.md` — implementation evidence and handoff state.

## Implementation steps

1. Re-run the F00–F02 baseline, confirm this plan remains accurate, and mark F03 `In progress` in `PROGRESS.md` before editing runtime files.
2. Extend the player with a non-blocking contact-detection shape, centralized maximum/current health and invulnerability duration, damage/death methods and signals, and safe reset-ready initial state.
3. Extend the reusable enemy with centralized health/contact damage, an idempotent damage/death path, and lightweight locally calculated separation from nearby normal enemies and the player without changing the direct-chase model.
4. Add the projectile scene/script and auto-weapon component. Select only valid living normal enemies, aim at the nearest one at each firing opportunity, and ensure every projectile is removed after exhausting its hit allowance or lifetime.
5. Wire collision layers/masks or equivalent overlap detection, a dedicated projectile container, and contact-damage routing so projectiles can hit enemies and enemies can damage the player without hard body collision.
6. Add the focused game controller, live health label updates, defeat overlay, gameplay stop/pause behavior, and a restart button that reloads a clean run and remains operable while gameplay is stopped.
7. Add deterministic helper seams where useful and implement `tests/verify_f03.gd` for target selection, projectile damage/cleanup, health and invulnerability, separation, defeat, restart, and prior-feature integration.
8. Run the full verification plan, perform the focused manual checks, then record exact results in this plan and `PROGRESS.md`; mark F03 complete only if every criterion passes.

## Acceptance criteria

- [ ] While valid enemies exist, the player automatically fires clearly visible projectiles at the nearest living normal enemy using a positive centralized fire interval; with no valid target, firing waits safely without errors or stray projectiles.
- [ ] Projectiles travel frame-rate-independently in their initial aim direction, apply centralized damage once per eligible enemy hit, and are removed when their configured hit allowance or lifetime is exhausted so projectile count remains bounded during sustained play.
- [ ] Normal enemies have centralized positive health and contact-damage values, accept damage through a reusable method, die exactly once at zero health, leave the enemy population/group cleanly, and do not drop XP yet.
- [ ] Enemy contact reduces player health and updates the existing HUD immediately, while repeated contact during the configured invulnerability window causes no additional health loss; health never falls below zero.
- [ ] Normal enemies still chase directly, but lightweight separation prevents exact enemy/enemy stacking and keeps them from resting directly on the player without pathfinding, hard body blocking, or trapping player movement.
- [ ] At zero player health, active movement, spawning, enemy motion/contact, and firing stop or pause; a readable defeat overlay appears and its restart button remains usable.
- [ ] Restart creates a clean run with full player health, the defeat overlay hidden, normal spawning/firing restored, and no retained enemies, projectiles, invulnerability, or defeat state from the prior run.
- [ ] Combat health, damage, speed, interval, lifetime, hit allowance, invulnerability, and separation values are exported or otherwise centralized rather than scattered as unexplained literals.
- [ ] F00–F02 movement, camera, endless-looking grid, off-screen spawning, population cap, and viewport-fixed HUD behavior remain functional.
- [ ] The project imports/parses, F00–F02 regressions and focused F03 checks pass, and the configured main scene smoke-runs without parser, missing-resource, or runtime errors.
- [ ] No XP/progression, upgrade, pickup, boss, victory, third-party dependency, pathfinding, or hard body-blocking behavior is introduced.

## Verification plan

### Automated or headless

- Import and parse the project:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path . --quit`
  Expected: exit code 0 with no parser, missing-resource, or import errors.
- Re-run completed-feature regressions:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f00.gd`
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f01.gd`
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f02.gd`
  Expected: all exit 0 with their verification pass messages.
- Run the focused F03 check:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f03.gd`
  Expected: exit code 0 after exercising nearest-target selection, no-target safety, projectile hit/lifetime cleanup, enemy death, player damage/invulnerability, soft separation, defeat, clean restart, and main-scene integration.
- Smoke-run sustained spawning and combat:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --quit-after 600`
  Expected: exit code 0 with no script/runtime errors or orphan-node warnings while enemies spawn, projectiles fire, hits occur, and any defeat state remains stable.
- Check patch hygiene:
  `git diff --check`
  Expected: exit code 0.

### Manual

- Start a run, remain near the origin, and move around approaching enemies. Confirm the player repeatedly fires toward whichever living enemy is nearest, visible projectiles remove enemies after hits, and the run stays responsive while spawning continues.
- Let several enemies converge, then move through and around the crowd. Confirm they can bunch and partly overlap but do not collapse into one exact stack, sit directly on the player, or form hard collision walls.
- Allow contact and watch the health HUD. Confirm one hit reduces health, sustained overlap does not drain health every frame, and another hit applies after the invulnerability window.
- Reach zero health, confirm gameplay stops and the defeat overlay is readable, then click restart. Confirm the new run starts at full health with fresh enemies/projectiles and normal movement, spawning, and firing.

## Completion notes

Fill this in during implementation:

- Actual files changed:
- Commands/tests and results:
- Manual checks performed:
- Deviations from plan:
- Remaining risks or follow-up:
