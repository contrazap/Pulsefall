---
name: pulsefall-git-publish
description: Initialize, inspect, commit, and push the Pulsefall repository when the user explicitly requests Git publishing, a commit, or a push. Do not use for read-only status checks or as permission to publish ordinary code changes.
---

# Pulsefall Git Publish

Publish requested changes from the Pulsefall repository while preserving user work and Git history.

## Repository contract

- Repository root: the directory containing `AGENTS.md`, `GAME_PLAN.md`, and `PROGRESS.md`.
- Canonical branch: `main`.
- Canonical remote: `origin` at `https://github.com/contrazap/Pulsefall.git`.
- A commit or push always requires an explicit user request. Loading this skill does not grant that authorization.

## Workflow

1. Read the repository instructions and relevant sources of truth before changing or publishing files.
2. Inspect `git status --short --branch`, unstaged and staged diffs, the current branch, and configured remotes. If Git is not initialized, confirm the exact repository root before running `git init`.
3. Preserve unrelated user changes. Stage only the requested files unless the user explicitly requested an initial or whole-repository snapshot and inspection shows no unrelated material.
4. Before committing, inspect the staged snapshot and run `git diff --cached --check`. Stop if it contains likely credentials, generated caches, unexpectedly large files, or changes outside the request.
5. Use a concise, meaningful commit message. Do not amend an existing commit or change published history unless the user separately and explicitly requests it.
6. Add `origin` only when absent. If it exists with a different URL, report the mismatch rather than replacing it without authorization.
7. Push `main` with upstream tracking when requested. Never force-push. On authentication failure, non-fast-forward rejection, or conflicts, stop and report the exact blocker; do not automatically pull, merge, or rebase.
8. Verify the result with `git status --short --branch`, `git log -1 --oneline`, and `git remote -v`, then report the commit identifier and push result.
