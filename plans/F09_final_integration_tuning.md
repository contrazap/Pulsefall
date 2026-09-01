# F09 — Final integration and tuning

- Status: Planned
- Roadmap dependency: F08
- Created: 2026-09-01
- Completed: —

## Objective

Validate the complete Pulsefall run from a clean launch through five upgrades and the boss outcome, correct only integration, balance, and readability issues found by that evidence, and leave a concise repeatable regression suite plus recorded full-run verification.

## Preflight and existing state

- Do not begin implementation until F07 and F08 are both `Complete`, their focused checks pass, and the project contains the planned bounded world population, pickup effects, boss transition, boss health UI, victory flow, and restart behavior. Reconcile this plan with their actual APIs before editing.
- F00–F06 currently provide movement and an endless-looking arena; capped normal enemies, projectiles, and XP coins; damage, defeat, and restart; five finite XP thresholds; paused queued upgrade choices; Vitality, Haste, Multishot, Piercing, and Nova. Existing combat and progression tunables are exported or centralized.
- `GAME_PLAN.md` defines the cross-feature acceptance criteria and a normal successful run target of about 3–5 minutes. F09 may tune existing values to meet that target but must not add scope.
- Planning baseline on 2026-09-01 used Godot `4.7.1.stable.official.a13da4feb`: headless import/parser, `verify_f00.gd` through `verify_f06.gd`, a 600-frame main-scene smoke run, and `git diff --check` all passed. F07/F08 evidence does not exist yet and is an execution gate, not a planning claim.
- The working tree contains ongoing earlier-feature work and another feature may be handled in parallel; preserve all unrelated changes.

## In scope

- Add one focused F09 integration verification that deterministically exercises the complete run state sequence: clean start, five separately resolved upgrades, boss transition only after selection five, both defeat and victory endings, and clean restart from each ending.
- Add bounded-population/stress coverage for every runtime collection: normal enemies, projectiles, XP coins, decorations, world pickups, and bosses. Verify cleanup/recycling while the player travels and across pause, ending, and restart states.
- Re-run all completed feature checks and fix regressions or small integration defects that prevent the documented loop from working together.
- Play the game through the intended loop without test shortcuts, record successful run duration, and tune only existing centralized/exported health, damage, speed, interval, spawn, XP, pickup, and boss values as evidence requires to produce a fair, readable run of about 3–5 minutes.
- Apply small placeholder-presentation fixes needed for immediate readability, such as contrast, hierarchy, spacing, labels, and overlapping geometric effects, at the default 1152×648 size and the supported 800×450 check size.
- Record exact automated results, measured manual run evidence, final key tuning values, any unperformed checks, and remaining risks in this plan and `PROGRESS.md`.

## Out of scope

- New characters, weapons, abilities, enemy or boss types, pickups, stages, progression layers, modes, content, or mechanics.
- Saves, meta-progression, achievements, shops, inventory, controller/mobile support, audio, localization, external art, complex animation, or accessibility systems beyond basic readability.
- Pathfinding, obstacles, procedural terrain topology, third-party addons/dependencies, broad architecture refactors, or a generic test/gameplay framework.
- Production-grade balance, exhaustive performance profiling, platform packaging/export, or changes to the five-selection/boss-ending product scope.

## Expected files

- `tests/verify_f09.gd` with its Godot UID sidecar — deterministic end-to-end state, bounded-population stress, ending, and restart regression coverage.
- Existing focused tests only if an actual regression exposes an incorrect or missing assertion owned by that feature.
- Existing scripts/scenes/resources that own centralized tuning or presentation values, but only when recorded F09 evidence justifies a change.
- `plans/F09_final_integration_tuning.md` and `PROGRESS.md` — final criteria, exact evidence, key tuned values, and project handoff.
- `README.md` only if its run or verification instructions are incomplete after F08.

## Implementation steps

1. Confirm F07 and F08 are complete, read their plans and actual implementation, run import plus `verify_f00.gd` through `verify_f08.gd`, and update this plan where later feature APIs or verified commands differ. Mark F09 `In progress` before runtime edits.
2. Build `verify_f09.gd` around the public seams that actually exist after F08. Exercise a fresh run through five individually resolved selections, assert the boss transition cannot occur early, then verify boss victory, player defeat in a separate run, and clean restart from both terminal overlays.
3. Add a deterministic travel/stress segment that creates sustained combat and world-population churn, samples all active collection counts against their configured caps, and verifies distant/transient nodes are cleaned up rather than accumulated. Include upgrade and ending pauses in the assertions.
4. Run the full suite before tuning and fix only reproducible cross-feature regressions. Put narrowly owned checks in the relevant earlier test when useful; keep the complete-loop assertions in F09.
5. Perform representative successful full runs using normal controls and no test shortcuts. Record wall-clock and active gameplay duration, upgrade paths, pressure spikes, ending clarity, and observed count/readability issues; tune existing centralized/exported values only where those observations show a need.
6. Inspect the active HUD, upgrade screen, pickups, dense combat, boss phase, defeat, and victory at 1152×648 and 800×450. Make only small contrast/layout/geometric-presentation corrections required to keep gameplay and terminal states understandable.
7. Re-run every automated check and a final normal full run, then record exact commands/results, measured duration, manual checks, final tuning changes, and residual risks. Mark F09 `Complete` only when all criteria below are actually verified.

## Acceptance criteria

- [ ] A clean launch enters an active base-state run with no parser, missing-resource, runtime, or orphan-node errors and no retained upgrades, progression, entities, boss state, or overlays.
- [ ] Using normal play, the player can collect enough XP to receive and resolve exactly five paused upgrade screens; XP carry-over and the game world remain correct across every pause.
- [ ] Every upgrade has an immediately visible gameplay effect and retains its defined formula/rank behavior: repeatable Vitality and Haste, and two ranks each for Multishot, Piercing, and Nova without max-rank reoffers.
- [ ] The boss does not appear before the fifth selection is applied, appears exactly once immediately afterward, stops normal spawning as specified by F08, remains compatible with existing normal enemies and abilities, and presents a readable updating health bar and spiked boss visual.
- [ ] Player health reaching zero produces only the paused defeat state; boss death produces only the paused victory state. Each ending's restart control reloads the same clean initial state without retained stats, ranks, XP, selections, entities, timers, pause state, boss state, or UI.
- [ ] Normal enemy, projectile, XP coin, decoration, world-pickup, and boss counts stay within their configured bounds during sustained combat and long-distance travel. Transient effects are reused or cleaned up, including through pauses, terminal states, and restart.
- [ ] Enemy separation remains soft: crowds can bunch but do not collapse into one unreadable stack, sit directly on the player, or create hard body blocking that traps movement.
- [ ] Health, Magnet, and Bomb pickups remain distinguishable and perform their exact F07 effects; Bomb cannot instantly defeat the boss, and pickup/decor placement remains relevant without spawning beneath the player or growing without limit.
- [ ] At least one successful full run performed with normal controls and without debug/test shortcuts is recorded. Its active gameplay duration is approximately 3–5 minutes, difficulty remains survivable with attentive movement, and the fifth-upgrade-to-boss transition does not create an unintended dead period or unavoidable damage spike.
- [ ] At 1152×648 and 800×450, the player, enemies, projectiles, XP, pickups, Nova, boss spikes, HUD, choice cards, boss bar, and defeat/victory controls remain legible without critical clipping or overlap; the complete loop is understandable with placeholder visuals.
- [ ] Headless import, every `verify_f00.gd` through `verify_f09.gd` check, the configured main-scene smoke run, and `git diff --check` pass on the final tree, with exact evidence recorded.
- [ ] F09 introduces no new feature scope, third-party dependency, external art requirement, pathfinding/obstacles, broad refactor, save/meta system, or undocumented debug shortcut.

## Verification plan

### Automated or headless

- Import and parse the project:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path . --quit`
  Expected: exit code 0 with no parser, missing-resource, or import errors.
- Run all focused and integration regressions, after confirming F07/F08 use the expected filenames:
  `foreach ($id in '00','01','02','03','04','05','06','07','08','09') { & 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script "res://tests/verify_f$id.gd"; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } }`
  Expected: every script exits 0 with its pass message; F09 covers the complete five-selection/boss/end/restart sequence and bounded stress assertions.
- Smoke-run the configured main scene for one simulated minute:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --quit-after 3600`
  Expected: exit code 0 with no script/runtime or orphan-node errors; an unattended run may safely pause at a level-up screen.
- Check patch hygiene:
  `git diff --check`
  Expected: exit code 0.

### Manual

- Start from a clean launch and complete at least one successful run using only documented movement and mouse choice controls. Record the chosen upgrades, wall-clock and pause-excluded active duration, boss transition timing, and outcome; expect approximately 3–5 minutes of active gameplay and a clear victory state.
- In a separate run, allow contact damage to cause defeat and use its restart button. Also restart after victory. In both cases, confirm base health/speed/weapon/ranks, level 1 and 0 XP, active gameplay, empty fresh entity containers, normal spawning, and hidden ending/choice/boss UI.
- During the successful run, deliberately collect each pickup, travel far enough to force decoration/pickup recycling, observe a dense enemy pack, and use each obtained combat ability. Confirm readable distinctions/effects, soft crowd separation, and no visible accumulating stale effects.
- Repeat representative active HUD, upgrade, dense-combat, boss, defeat, and victory observations at 1152×648 and 800×450. Confirm essential text and controls fit and all gameplay elements remain distinguishable.

## Completion notes

Fill this in during implementation:

- Actual files changed:
- Commands/tests and results:
- Measured full-run evidence and final key tuning values:
- Manual checks performed:
- Deviations from plan:
- Remaining risks or follow-up:
