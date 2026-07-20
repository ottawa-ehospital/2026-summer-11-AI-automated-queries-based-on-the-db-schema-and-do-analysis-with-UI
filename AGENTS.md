# Repository Instructions

## Worktree Isolation

When handling multiple concurrent changes, start each change in its own Git worktree instead of editing the current local checkout directly.

- Do not make unrelated concurrent changes in `main` or the active local checkout.
- Create a separate branch and worktree for each independent task before editing files.
- Use branch names such as `codex/<change-name>` unless the user specifies another naming scheme.
- If a task has already started in Local and should continue in isolation, hand it off to a worktree or create a new worktree before continuing.

## OpenSpec Apply

When applying an OpenSpec change, always create and work in a dedicated Git worktree before making edits.

- Name the branch exactly after the OpenSpec feature/change name.
- Use the same OpenSpec feature/change name for the worktree directory when practical.
- Do not run `openspec apply` implementation work directly in `main` or the active local checkout.
