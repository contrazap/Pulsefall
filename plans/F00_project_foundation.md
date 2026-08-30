# F00 — Project foundation

- Status: Planned
- Roadmap dependency: None
- Created: 2026-08-30
- Completed: —

## Objective

Create the minimal runnable Godot 4.7.1 project foundation for Pulsefall: a configured main scene, keyboard movement input actions, and a simple HUD shell that establishes the intended neon presentation without implementing gameplay.

## Preflight and existing state

- The repository currently contains only planning documentation; `project.godot`, scenes, scripts, and runtime assets do not exist.
- Git reports a clean working tree before planning.
- The local console executable exists at `C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe` and reports `4.7.1.stable.official.a13da4feb`.
- No prior feature requires regression verification because F00 has no roadmap dependency.

## In scope

- Create a Godot 4.x `project.godot` with a documented main scene and desktop-sized display defaults.
- Define `move_up`, `move_down`, `move_left`, and `move_right` input actions, each mapped to both its WASD key and corresponding arrow key.
- Create a minimal runnable main scene with a dark background and a full-rect HUD shell suitable for later gameplay integration.
- Show static placeholder HUD labels for health, level, and XP so the intended information hierarchy can be verified.
- Add only the small amount of repository-native scene/script structure required for a clean launch.
- Record exact automated and manual verification evidence in this plan and `PROGRESS.md` during implementation.

## Out of scope

- Player movement, a camera, arena rendering, or any other F01 behavior.
- Enemies, combat, damage, progression logic, upgrade UI, pickups, boss behavior, or end screens.
- Functional health, level, or XP state; F00 HUD values are presentation placeholders only.
- External art, fonts, addons, runtime dependencies, or broad project architecture.

## Expected files

- `project.godot` — project settings, main-scene assignment, display defaults, and input actions.
- `scenes/main.tscn` — runnable root scene and minimal presentation/HUD composition.
- `scripts/main.gd` — only if needed for a focused startup or layout responsibility; omit if the scene alone is sufficient.
- `plans/F00_project_foundation.md` — checked criteria and completion evidence.
- `PROGRESS.md` — feature status, changed files, verification results, and next action.

## Implementation steps

1. Mark F00 `In progress` in `PROGRESS.md` and re-confirm the clean baseline before substantive edits.
2. Create `project.godot` for Godot 4.7.1, set `scenes/main.tscn` as the run/main scene, and configure sensible desktop viewport/stretch defaults.
3. Add the four directional input actions with WASD and arrow-key mappings.
4. Build `scenes/main.tscn` with a dark full-window background and a full-rect HUD layer whose health, level, and XP placeholders remain readable at the configured viewport size.
5. Add a focused typed GDScript only if scene configuration cannot cleanly provide a required foundation behavior.
6. Run the headless import/parser and main-scene smoke checks, resolving all parser, missing-resource, and runtime errors within F00 scope.
7. Launch the project interactively, verify the visible shell and input mappings, then update this plan and `PROGRESS.md` with only the checks actually performed.

## Acceptance criteria

- [ ] `project.godot` opens as a Godot 4.x project and identifies the exact installed version used for verification as `4.7.1.stable.official.a13da4feb` in the recorded evidence.
- [ ] Running the project starts `scenes/main.tscn` without parser, missing-resource, or runtime errors.
- [ ] `move_up`, `move_down`, `move_left`, and `move_right` exist and each accepts both the specified WASD key and corresponding arrow key.
- [ ] The main scene visibly presents a dark game background plus readable health, level, and XP placeholder labels in a HUD layer.
- [ ] The HUD layout remains anchored to the viewport when the window is resized during the focused manual check.
- [ ] No F01-or-later gameplay behavior or third-party dependency is introduced.

## Verification plan

### Automated or headless

- Confirm the engine version:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --version`
  Expected: `4.7.1.stable.official.a13da4feb`.
- Import and parse the project:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path . --quit`
  Expected: exit code 0 with no parser, missing-resource, or import errors.
- Smoke-run the configured main scene:
  `& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 2`
  Expected: the configured main scene starts and exits cleanly with no script or runtime errors.
- Inspect `project.godot` after import to confirm all four input actions contain both required key bindings.

### Manual

- Launch the project with the Godot editor or GUI executable and run the main scene.
- Confirm a dark background and readable health, level, and XP placeholders are visible with no error dialog or debugger error.
- Resize the game window and confirm the HUD stays attached to the intended viewport edges and remains readable.
- Press WASD and arrow keys while using Godot's input/debug inspection, or otherwise inspect the Input Map, to confirm both bindings exist; no movement is expected in F00.

## Completion notes

Fill this in during implementation:

- Actual files changed:
- Commands/tests and results:
- Manual checks performed:
- Deviations from plan:
- Remaining risks or follow-up:
