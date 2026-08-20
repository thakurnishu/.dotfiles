---
name: herdr-worktree
description: Create or open a git-worktree-backed herdr workspace so an agent gets its own isolated checkout of a branch, laid out as terminal + lazygit tabs. Use when the user asks to work on a branch in a separate workspace, to spin up an isolated checkout, to open an existing worktree as a space, or when parallel work on two branches of one repo would otherwise collide in a single checkout. Requires running inside herdr (HERDR_ENV=1).
---

# herdr worktree spaces

A herdr **space** is identified by a directory. A **worktree-backed space** is a
space whose directory is a git worktree — a second checkout of the same repo on
a different branch, sharing one `.git`.

This is how two agents work on two branches of one repo without fighting: each
gets its own working directory, its own `git status`, its own build output.

Everything below shows up in the herdr sidebar immediately; there is no
separate "register with the UI" step.

## Check you are inside herdr first

```bash
test "${HERDR_ENV:-}" = 1
```

If this fails, stop and say you are not running inside herdr. Do not try to
drive someone else's session from outside.

**Never run bare `herdr`** — it launches or attaches the TUI, and with no TTY
it panics with `failed to initialize terminal`. Always use a subcommand.

## Create a space for a NEW branch

Preferred — one command, creates worktree + space + tabs:

```bash
herdr-worktreeizer <branch> [base]      # e.g. herdr-worktreeizer feat/thing main
```

Non-interactive when given arguments, which is the agent path. Without
arguments it prompts, which is the human path (bound to prefix+shift+g).

Raw equivalent, if you need control over the steps:

```bash
herdr worktree create --workspace "$WS" --branch feat/thing --base main \
  --label feat-thing --focus
```

The checkout lands in `~/.herdr/worktrees/<repo>/<branch with / as ->`.

## Open a branch that ALREADY has a worktree

`create` fails or duplicates if the worktree exists. Use `open`:

```bash
herdr worktree list --workspace "$WS"          # see what exists, and what is already open
herdr worktree open --cwd <repo-root> --branch <branch> --label <label> --no-focus
```

The response carries `already_open`; if it is `true`, do not lay out tabs again.
`open` works wherever the checkout lives — including `<repo>/.claude/worktrees/`
— so there is no need to relocate anything.

## Resolving which workspace you are acting on

This is the part that breaks silently. Two callers, two answers:

- Running in a **pane**: `HERDR_WORKSPACE_ID` is set — use it. The pane you are
  in is not necessarily the focused one.
- Running in a **popup**: `HERDR_ENV` is set but `HERDR_WORKSPACE_ID` is **not**.
  Fall back to the focused workspace:
  `herdr api snapshot | jq -r .result.snapshot.focused_workspace_id`

Passing an empty `--workspace` is not harmless — herdr answers with no source
repo, which surfaces as a confusing "not inside a git repository" while sitting
in a perfectly good one.

## Laying out tabs

`workspace create`, `tab create` and `worktree create` all return
`result.root_pane.pane_id` and `result.tab.tab_id`. Tab 1 already exists as the
workspace root; it only needs renaming.

```bash
herdr tab rename "$TAB1" terminal
TJ=$(herdr tab create --workspace "$WS" --cwd "$CHECKOUT" --label lazygit --no-focus)
PANE=$(printf '%s' "$TJ" | jq -r .result.root_pane.pane_id)
herdr pane run "$PANE" lazygit
herdr tab focus "$TAB1"        # land on terminal, not on the last tab created
```

Use `pane run` rather than launching the tool as the pane's command: it types
into the tab's shell, so quitting lazygit leaves a usable shell instead of
closing the tab.

## Labels

Label collisions are invisible in the sidebar and easy to create: the same
branch name often exists in several repos. Prefix with the repo when that can
happen — `fcc-nbo-poc` vs `feat-nbo-fcc-poc` for `feat/nbo-fcc-poc` in two
different repos.

## Cleaning up

```bash
herdr workspace close "$WS"                    # closes the space, keeps the checkout
herdr worktree remove --workspace "$WS"         # closes the space AND deletes the checkout
```

`remove` deletes the working directory. The branch and its commits survive —
removing a worktree is not deleting a branch — but **`--force` discards
uncommitted changes** in that checkout. Never pass `--force` without saying so
first. A `locked` worktree refuses removal until `git worktree unlock`.
