# Pulsefall Agent Instructions

These instructions apply to the entire `Pulsefall` directory tree.

## Mission

Build Pulsefall incrementally as a small Godot 4.x game. Work on one roadmap feature at a time, leave the project runnable, and preserve enough evidence that a fresh agent can continue without relying on chat history.

## Sources of truth

Read these before planning or editing:

1. `AGENTS.md` — working rules.
2. `GAME_PLAN.md` — product scope, decisions, and ordered roadmap.
3. `PROGRESS.md` — current status, evidence, blockers, and next feature.
4. The active file in `plans/`, if one exists.
5. The actual project files and current verification results.

The repository and verification results override stale documentation. If they disagree, report the discrepancy and reconcile the documentation as part of an authorized planning or implementation task.

## Status-only response

When the user's sole request is to check or report project status (for example, `status`, `check status`, or `project status`), read the sources of truth and check the project well enough to validate them, but keep that work silent. Do not send commentary, a preamble, progress updates, headings, bullets, evidence, explanations, or follow-up text. Send exactly one user-visible response after the checks finish, consisting only of this single line:

`Status: <overall state> | Last: <last completed feature> | Current: <current feature> | Next: <next feature/action> | Blockers: <none or concise blocker>`

Keep discrepancies concise in the `Blockers` field. If the user asks for status plus another task or explicitly requests details, this status-only rule does not apply; use the normal workflow instead.

## Interpret common prompts

### “Check status”

- Read the sources of truth and inspect the actual project.
- Run safe, relevant existing verification when practical.
- Return only the single-line status response defined above, with no earlier or later user-visible text.
- Do not implement a feature or modify files unless the user also asks for changes.

### “Generate the plan for the next feature”

- Inspect the project; do not trust `PROGRESS.md` alone.
- Select the earliest dependency-satisfied roadmap feature that is not complete.
- Create or refine only `plans/F##_short_name.md` using `plans/FEATURE_PLAN_TEMPLATE.md`.
- Keep it small enough for one fresh agent session.
- Include concrete acceptance criteria and verification commands or steps.
- Update the corresponding `PROGRESS.md` row to `Planned` and set `Next action`.
- Do not implement the feature.

### “Implement the next feature”

- Select the earliest dependency-satisfied incomplete feature.
- If its plan is missing, first create a concise plan from the template, then implement it in the same session.
- Set the feature to `In progress`, implement only its scope, verify it, and update its plan and `PROGRESS.md`.

### “Implement F##”

- Confirm its dependencies are complete.
- Read or create its plan, then implement only that feature.
- If a dependency is genuinely missing, stop and explain instead of silently implementing multiple roadmap features.

## Feature workflow

1. Inspect `git status` when Git exists and preserve unrelated user changes.
2. Read the relevant files and run the previous feature’s checks as a baseline.
3. Confirm the active plan has testable acceptance criteria.
4. Mark the feature `In progress` in `PROGRESS.md` before substantive implementation.
5. Make the smallest cohesive change that satisfies the plan.
6. Run verification proportional to the change.
7. Update the feature plan’s completion notes and check only criteria actually verified.
8. Update `PROGRESS.md` with status, files changed, commands run, results, manual checks, and the next action.
9. Mark a feature `Complete` only when all required acceptance criteria pass. Otherwise leave it `In progress` or `Blocked` with a precise reason.

## Scope and engineering rules

- Use Godot 4.x and typed GDScript where it keeps code clear. Record the exact installed Godot version during F00.
- Keep the architecture simple: scenes, focused scripts, signals, groups, and small data dictionaries/resources where useful.
- Prefer reusable gameplay components, but do not build a generic framework or speculative extension points.
- Use placeholder geometric visuals made from Godot nodes or small repository-native assets. Do not wait for external art.
- Avoid third-party addons and new runtime dependencies unless the user approves them.
- Keep tunable gameplay values centralized or exported rather than scattered as unexplained literals.
- Pause gameplay during the level-up choice screen.
- Do not expand the committed scope with saves, meta-progression, multiple characters, multiple normal enemy types, pathfinding, obstacle collision, audio, mobile controls, or elaborate animation.
- Do not perform broad refactors while implementing a feature unless required for its acceptance criteria.
- Do not commit, push, delete user work, or rewrite Git history unless explicitly asked.

## Verification standard

Use the strongest checks currently available. As the project grows, this normally includes:

- Confirm the Godot project imports/parses in headless editor mode.
- Run any repository test suite or purpose-built verification scene/script.
- Smoke-run the main scene headlessly when possible and check for parser/runtime errors.
- Perform the active plan’s focused manual check when an interactive Godot run is available.
- Re-run checks for previously completed behavior that the change could affect.

Never claim a manual check was performed when it was not. If Godot is unavailable, record that limitation and use static inspection; do not mark criteria requiring runtime evidence as verified.

## Definition of done for a feature

A feature is complete only when:

- Its dependencies remain working.
- Every in-scope acceptance criterion is satisfied.
- No known parser or runtime error was introduced.
- Relevant verification passed, with exact evidence recorded.
- `PROGRESS.md` and the feature plan reflect reality.
- The project remains runnable from its documented main scene.

## Documentation hygiene

- Keep `GAME_PLAN.md` stable. Change product scope only when the user requests or approves it.
- Keep detailed session notes out of `GAME_PLAN.md`; put them in `PROGRESS.md` or the active feature plan.
- Use one plan file per feature and the `F##_short_name.md` naming convention.
- Keep plans concise. Reference existing code instead of restating it.
- Add newly discovered work to `PROGRESS.md` as a note or blocker; do not silently add roadmap features.
