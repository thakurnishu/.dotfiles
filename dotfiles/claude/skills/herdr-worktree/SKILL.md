---
name: herdr-worktree
description: Create or open a git-worktree-backed herdr workspace so an agent gets its own isolated checkout of a branch, laid out as terminal / harness / lazygit / hunk tabs, and bind your own session to that checkout with EnterWorktree. Use when the user asks to work on a branch in a separate workspace, to spin up an isolated checkout, to open an existing worktree as a space, when parallel work on two branches of one repo would otherwise collide in a single checkout, or when you need to reach the agent running in another herdr space. Requires running inside herdr (HERDR_ENV=1).
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
arguments it opens a create/open menu, which is the human path (bound to
prefix+shift+g).

Raw equivalent, if you need control over the steps:

```bash
herdr worktree create --workspace "$WS" --branch feat/thing --base main \
  --label feat-thing --focus
```

The checkout lands in `~/.herdr/worktrees/<repo>/<branch with / as ->`.

## Bind YOUR OWN session to the checkout

Creating the space is not enough, and the gap is easy to miss because the
sidebar looks right. `herdr-worktreeizer` gives the **user** a visible
workspace; it does not move **your** working directory.

Your Bash cwd resets between calls, so without this step every command needs
its own `cd` and one omission writes to the source branch — exactly what the
worktree existed to prevent. That happened in a real session before it was
caught.

Immediately after create/open:

```
EnterWorktree(path="~/.herdr/worktrees/<repo>/<branch with / as ->")
```

The path must appear in `git worktree list` for the repo that owns it, which
it does — herdr just created it. Once bound, cwd persists across Bash calls
and git operations outside the worktree are refused.

`ExitWorktree` will NOT delete a worktree entered this way. Use
`action: "keep"` to return to the original directory; real teardown is the
`herdr workspace close` / `herdr worktree remove` commands below.

### One entry only, for herdr worktrees

You get **one** EnterWorktree into a herdr checkout per session. Entering
another is rejected.

The reason is a mismatch worth understanding rather than memorising: the
first entry only requires the path to be in `git worktree list`, which a
herdr worktree satisfies. But **switching** from one worktree to another
additionally requires the target to live under the repo's
`.claude/worktrees/`, and herdr puts its checkouts in `~/.herdr/worktrees/`.
So the second hop has nowhere legal to land.

Practical consequence: decide which branch this session owns before binding.
To work a second branch, that is a second session — which is the model herdr
spaces already assume.

### While bound

- **Write plain, single-purpose commands.** The harness must be able to prove
  statically that a command stays inside the worktree, and refuses when it
  cannot. A heredoc with a redirect, or `cd ../.. && git ...`, are both
  rejected even when harmless.

- **A fresh checkout has no build artifacts.** Dependencies, `node_modules`,
  virtualenvs and the like belong to the source checkout — and container
  volumes usually bind there too, so nothing is shared. Install inside the
  worktree before trusting any verification step. (On this machine `pnpm` is
  not on PATH; `corepack pnpm install` works.)

## Talking to the agent in another space

`ListAgents` lists peers by **session name**, which has nothing to do with the
herdr **space label**. The agent in the `_dotfiles` space registers as
`herdr-implementation`; sessions show up as `carestackone-d9` and
`refactor-rename-providers-to-doctors-e3` while their spaces are labelled
`carestackone` and `refactor-rename-providers-to-doctors`.

Matching a space label against that list concludes "no agent there" while an
agent is sitting right in it. Two separate namespaces.

`herdr api snapshot` gives the other half — `.result.snapshot.agents` carries
`cwd`, `workspace_id` and `pane_id` for every live agent, so that is how you
find WHICH space has an agent. It does not carry the peer's session name, so
there is no mechanical join between the two; use the cwd to work out who you
mean, then address them by the session name `ListAgents` shows.

## Open a branch that ALREADY has a worktree

`create` fails or duplicates if the worktree exists. Use `open`:

```bash
herdr-worktreeizer --open <branch>      # branch name, or the checkout's directory name
```

Same two-tab layout as create, and it is a no-op-plus-focus when the worktree is
already open as a space. With no branch argument it shows a picker.

Raw equivalent:

```bash
herdr worktree list --workspace "$WS"   # what exists, and what is already open
herdr worktree open --workspace "$WS" --path <checkout> --label <label> --focus
```

Each entry in `worktree list` carries **`open_workspace_id`, present only when
this session already has that worktree open**. When it is set, `herdr workspace
focus "$id"` instead of opening — opening again stacks a duplicate space.

Address the checkout by `--path`, not `--branch`: paths are unique, and it is
the field `worktree list` gives you. `open` works wherever the checkout lives —
including `<repo>/.claude/worktrees/` — so there is no need to relocate
anything.

Beware `--cwd`: when you address the source repo by directory rather than by
`--workspace`, herdr materialises a space for the source repo too, so you get
two new spaces instead of one.

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

You almost certainly do not need to. `herdr-worktreeizer` calls
`herdr-space-layout`, which is the ONE place that decides what a space looks
like -- shared with `herdr-sessionizer` so the two cannot drift. A worktree
space comes out as:

```
1:terminal | 2:harness | 3:lazygit | 4:hunk
```

and lands on **harness**, whose agent is named after the branch's last segment
(`feat/vault-rotation` -> `vault-rotation`) and opens with the branch and
checkout already in its prompt. `--harness <kind>` picks which one without
prompting; without a TTY the picker is skipped and the menu is left in the
pane.

No gh-dash tab: a worktree's PRs are the parent repo's PRs, so a second
dashboard on the same query is noise.

If you are building a space by hand anyway, `workspace create`, `tab create`
and `worktree create` all return `result.root_pane.pane_id` and
`result.tab.tab_id`, and tab 1 already exists as the workspace root:

```bash
herdr tab rename "$TAB1" terminal
TJ=$(herdr tab create --workspace "$WS" --cwd "$CHECKOUT" --label lazygit --no-focus)
PANE=$(printf '%s' "$TJ" | jq -r .result.root_pane.pane_id)
herdr pane run "$PANE" lazygit
```

Use `pane run` rather than launching the tool as the pane's command: it types
into the tab's shell, so quitting lazygit leaves a usable shell instead of
closing the tab. Creation order IS tab order, so create tabs in the order you
want them.

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
