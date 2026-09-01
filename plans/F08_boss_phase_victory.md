# F08 — Boss phase and victory

- Status: Planned
- Roadmap dependency: F07
- Created: 2026-09-01
- Completed: —

## Objective

After the fifth upgrade is applied, transition the active run into a single-boss phase: stop new normal-enemy spawning, create one clearly spiked boss by reusing the existing enemy behavior with boss-specific tuning, show its live health, and end in a paused victory screen with a clean restart when it dies.

## Preflight and existing state

- At planning time F06 is complete and F07 is being implemented in parallel. Do not begin F08 runtime work until F07 is complete, its focused verification passes, and its actual pickup/population APIs have been reconciled with this plan.
- `scripts/game_controller.gd` owns the five-selection count, applies an upgrade before emitting `selection_applied`, coordinates run pause/defeat/restart, and connects normal-enemy death to XP drops. The fifth successful selection is the authoritative boss-phase trigger.
- `scripts/enemy.gd` already provides reusable chase, contact damage, health signals, `take_damage()`, and death behavior. `scripts/enemy_spawner.gd` provides camera-aware off-screen placement but currently starts and continues normal spawning without an explicit phase-stop API.
- Normal enemies are currently the only members of `normal_enemies`; both `scripts/auto_weapon.gd` and `scripts/nova_ability.gd` target that group. F08 needs a separate shared combat-target group for normal enemies and the boss so F07 Bomb can remain normal-enemy-only.
- `scenes/main.tscn` has the live HUD and a paused defeat/restart overlay but no boss scene, boss health bar, victory overlay, or boss-phase state.
- With Godot `4.7.1.stable.official.a13da4feb`, the pre-F07 implementation baseline passed headless import/parser, F00–F06 verification, a 600-frame main-scene smoke run, and `git diff --check` on 2026-09-01. Preserve the existing dirty working tree and parallel F07 work.

## In scope

- Add one boss scene using the existing enemy script/behavior, with centralized boss-specific health, movement speed, contact damage, collision/visual size, color, and a clear repository-native spike ring or crown.
- Introduce a shared combat-target group used by the auto-weapon and Nova. Normal enemies belong to both this group and `normal_enemies`; the boss belongs to the combat-target group and a boss-specific group, but never `normal_enemies`, so F07 Bomb cannot instantly defeat it.
- Start the boss phase exactly once, immediately after the fifth valid upgrade selection has been applied. Stop normal-enemy spawning, retain already-active normal enemies, and spawn exactly one boss just outside the current viewport using the existing camera-aware placement boundary or a small focused extension of it.
- Show a readable boss health bar only while a living boss is active. Initialize it from boss maximum/current health and update it immediately from the existing health signal.
- On boss death, do not create a normal XP drop; stop active gameplay, hide boss health, and show a paused victory overlay with a restart button. Preserve defeat as the result when the player dies before the boss.
- Restart by reloading a clean run with no boss/phase/end-state retained, normal spawning enabled, base progression/upgrades restored, and F07 populations freshly initialized.
- Preserve all F00–F07 behavior and add focused deterministic F08 verification.

## Out of scope

- Additional boss attacks, phases, summons, projectiles, pathfinding, obstacle interaction, loot, or more than one boss.
- Removing existing normal enemies at the transition; only future normal spawning stops.
- Rebalancing run length, XP thresholds, upgrades, normal spawn pressure, pickup frequency, or production tuning/polish reserved for F09.
- Countdown endings, post-victory progression, save/meta-progression, achievements, audio, external art, elaborate animation, or third-party dependencies.
- A generic encounter/state-machine framework or broad enemy/controller/UI refactor beyond the focused phase and terminal-state seams required here.

## Expected files

- `scenes/boss.tscn` — boss instance reusing `scripts/enemy.gd`, boss-specific exported values, collision size, and geometric spiked presentation.
- `scenes/enemy.tscn` — add the shared combat-target group while retaining `normal_enemies`.
- `scripts/auto_weapon.gd` and `scripts/nova_ability.gd` — target the shared combat-target group so both abilities work against normal enemies and the boss.
- `scripts/enemy_spawner.gd` — add a small explicit stop/enable API and retain a testable camera-aware spawn-position seam.
- `scripts/game_controller.gd` — own boss-phase/victory guards, fifth-selection transition, boss spawn/signals, health UI, terminal-state precedence, and clean restart integration.
- `scenes/main.tscn` — wire the boss scene, any dedicated boss container, boss health HUD, and paused victory/restart overlay.
- `tests/verify_f08.gd` with its Godot UID sidecar — focused transition, targeting, health, victory, pause, and restart checks.
- `plans/F08_boss_phase_victory.md` and `PROGRESS.md` — implementation evidence and F09 handoff.

## Implementation steps

1. After F07 is complete, inspect its actual files and evidence, re-run F00–F07, adjust only stale F08 assumptions, and mark F08 `In progress` in `PROGRESS.md` before runtime edits.
2. Add a shared combat-target group to normal enemies and point AutoWeapon/Nova at it. Keep F07 Bomb explicitly filtered to `normal_enemies`, and cover both sides of this boundary in focused tests.
3. Create the spiked boss scene with the existing enemy script and centralized boss-specific tuning. Add only the small spawner/controller APIs needed to stop normal spawning and place one boss outside the current viewport.
4. In the guarded upgrade-application flow, begin the boss phase exactly once after selection five takes effect: stop the normal spawn timer, retain current normal enemies, instantiate/configure one boss, and connect its health/death signals separately from normal XP-drop handling.
5. Add the initially hidden boss health HUD and paused victory overlay/restart control. Update health from the boss signal and make victory/defeat mutually exclusive, one-shot terminal states that freeze combat and F07 world activity.
6. Add deterministic `verify_f08.gd` coverage for no early/duplicate boss, fifth-selection ordering, spawn transition, group targeting/Bomb immunity, boss tuning/health UI, normal-enemy coexistence, victory precedence, pause, and clean restart.
7. Run the full verification plan, perform the focused manual check, and record exact results in this plan and `PROGRESS.md`. Mark F08 complete only after every criterion is verified.

## Acceptance criteria

- [ ] No boss exists and normal spawning remains enabled before five upgrade selections have been applied. The fifth valid selection applies its chosen upgrade first, then starts the boss phase exactly once without a sixth choice or duplicate boss.
- [ ] The boss spawns just outside the current viewport, chases the player, deals contact damage through the existing invulnerability rules, and takes projectile damage through the reused enemy implementation.
- [ ] The boss has centralized values distinct from a normal enemy for maximum health, size/collision, color, movement speed, and contact damage, plus a clearly readable geometric ring/crown of spikes.
- [ ] Beginning the boss phase stops future normal-enemy spawning and leaves already-active normal enemies alive. Repeated transition calls or timer timeouts cannot resume spawning or create another boss.
- [ ] AutoWeapon targets the nearest living normal enemy or boss through a shared combat-target group. Nova damages an in-range boss as well as in-range normal enemies, while F07 Bomb continues to affect only `normal_enemies` and cannot damage the boss.
- [ ] A boss health bar is hidden before the phase, appears with the boss’s correct current/maximum health, updates immediately after damage, and remains readable at the supported default and 800×450 window sizes.
- [ ] Killing a normal enemy during the boss phase still follows the normal XP-drop path and does not cause victory. Killing the boss creates no normal-enemy XP drop, hides the boss health bar, pauses gameplay/F07 population activity, and shows the victory overlay exactly once.
- [ ] Player death before boss death still shows defeat, not victory. Once either terminal state is established, later damage/death callbacks cannot replace it with the other result or reopen upgrade UI.
- [ ] The victory overlay includes a working restart button. Restart restores a fresh non-boss run with normal spawning enabled, no boss or terminal overlay, hidden boss health, and no retained progression, upgrades, entities, pickup effects, or pause state.
- [ ] F00–F07 movement, arena, bounded spawning/populations, combat, XP, five-choice progression, upgrades, pickups, defeat, pause, and restart behavior remain functional.
- [ ] The project imports/parses, F00–F07 regressions and focused F08 checks pass, and the configured main scene smoke-runs without parser, missing-resource, runtime, or orphan-node errors.
- [ ] No F09 tuning/polish, extra boss mechanics, save/meta-progression, third-party dependency, pathfinding, or unrelated feature is introduced.

## Verification plan

### Automated or headless

- After F07 is complete, import and parse the project:
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
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f07.gd`
  Expected: all exit 0 with their verification pass messages.
- Run the focused F08 check:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/verify_f08.gd`
  Expected: exit 0 after deterministic checks of the fifth-selection transition, one boss, stopped normal spawning, shared targeting versus Bomb filtering, boss health UI, normal death versus boss victory, terminal-state guards, pause, and restart.
- Smoke-run the configured main scene:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --quit-after 600`
  Expected: exit code 0 with no script/runtime or orphan-node errors; all gameplay populations remain bounded and an unattended upgrade screen may leave the run safely paused.
- Check patch hygiene:
  `git diff --check`
  Expected: exit code 0.

### Manual

- Play through five upgrade selections. Confirm no boss appears early; after the fifth choice’s effect is visible, one spiked boss enters from outside the viewport, existing normal enemies remain, and no new normal enemies spawn.
- Fight the boss with projectiles and Nova, then collect Bomb while the boss and at least one normal enemy are active. Confirm the normal enemy is heavily damaged/killed, the boss is unaffected by Bomb, and the health bar accurately tracks other boss damage at the default and 800×450 sizes.
- Let the boss contact the player and confirm normal damage/invulnerability behavior. In separate runs, die during the boss phase and kill the boss; confirm only defeat or victory respectively appears and all world activity freezes.
- Press the victory restart button and confirm a clean initial run with normal spawning, hidden boss/victory UI, reset progression/upgrades, and fresh bounded F07 decorations/pickups.

## Completion notes

Fill this in during implementation:

- Actual files changed:
- Commands/tests and results:
- Manual checks performed:
- Deviations from plan:
- Remaining risks or follow-up:
