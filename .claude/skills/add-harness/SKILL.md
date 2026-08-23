---
name: add-harness
description: Add a new agent CLI (claude, codex, opencode, gemini, amp, droid, ...) as a pickable harness in the herdr "harness" tab, wired for state detection and conversation resume. Use when asked to add/install a new agent CLI or coding agent to this machine, to make a harness appear in the prefix+shift+a picker, when a harness starts but the sidebar shows no agent state, or when switching to a harness and back loses the conversation.
---

# Adding a harness

A **harness** is the agent CLI that the `harness` tab becomes. The tab runs
`~/.local/bin/harness`, which offers whatever is installed and `exec`s your
choice, so quitting drops you back at a shell where running `harness` again
picks a different one.

Three separate systems have to agree about the name, and each one fails
differently when it does not:

| System | What it gives you | Symptom when missing |
|---|---|---|
| `harness` `KINDS` | appears in the picker | you cannot select it at all |
| herdr detection manifest | working/idle/blocked in the sidebar | runs fine, sidebar shows nothing |
| herdr integration | the session id, so it survives a swap | switch away and back = cold start |

## 0. Check what herdr already knows

Do this first — most of the work may already be done for you.

```bash
herdr agent start --help | grep -A3 'possible values'   # canonical kinds
herdr integration status                                # who reports a session
ls ~/.local/state/herdr/agent-detection/remote/         # who gets state detection
```

As of herdr 0.8.0 the **canonical kinds** are:

```
pi claude codex gemini cursor devin agy cline omp mastracode
opencode copilot kimi kiro droid amp grok hermes kilo qodercli maki
```

**The name must be BOTH herdr's canonical kind AND the executable on PATH.**
`harness` finds candidates with `command -v "$k"` and hands the same string to
`herdr agent start --kind`. A CLI whose binary is named differently from
herdr's kind cannot currently be added without changing `harness` to carry a
kind/executable pair. No installed harness has that problem today.

Gaps worth knowing, both harmless but silent:

- **no detection manifest:** `omp`, `mastracode`. They will run; the sidebar
  just will not know what they are doing.
- **no integration:** `gemini` (herdr's target is named `antigravity-cli`),
  `agy`, `cline`, `kiro`, `amp`, `maki`. They will run and be detected; they
  will not survive a harness swap.

## 1. Install the CLI

Nix first — `modules/darwin/packages.nix`, where `claude-code`, `codex` and
`opencode` already live. GUI apps go to `modules/darwin/homebrew.nix`. A CLI
in neither is the only case for npm/curl, and it should be commented as such.

## 2. Teach `harness` about it

`dotfiles/.local/bin/harness`, three places:

```bash
KINDS=(claude codex opencode ... yourtool)   # required -- discovery list

describe() {                                  # optional -- picker label
    case $1 in
        yourtool) printf 'Your Tool' ;;
```

```bash
resume_argv() {                               # required for session memory
    case $k in
        claude)   printf '%s\n--resume\n%s\n'  "$k" "$id" ;;
        opencode) printf '%s\n--session\n%s\n' "$k" "$id" ;;
        codex)    printf '%s\nresume\n%s\n'    "$k" "$id" ;;
        *)        printf '%s\n' "$k" ;;        # no resume flag -> starts fresh
```

Find the flag with:

```bash
yourtool --help | grep -iE 'resume|continue|session'
```

**Read the shape, not just the flag name.** codex takes a *subcommand*
(`codex resume <id>`), so it changes `argv[1]`, while claude and opencode take
a trailing flag. That is why `resume_argv` prints whole argv lines instead of
returning a flag string.

Prefer resume **by id** over "most recent" (`--continue`, `resume --last`).
Most-recent is cwd-scoped, so with two panes on one repo it will happily
resume the *other* pane's conversation. Falling back to a fresh session is
better than that. The `*)` branch already does the right thing.

## 3. Install the herdr integration, if there is one

`modules/home/default.nix`:

```nix
for target in claude codex opencode; do    # add yours here
```

This is what makes the session id available at all — without it `harness` has
nothing to resume. **The integration writes into the tool's own config**, not
just herdr's: installing `codex` added `[features] hooks = true` to
`~/.codex/config.toml`. herdr owns those files and version-stamps them, which
is why this step is imperative rather than a `home.file`. Reverse with
`herdr integration uninstall <target>`.

## 4. Apply

```bash
.claude/skills/run-dotfiles/driver.sh          # lint + build first
.claude/skills/run-dotfiles/driver.sh switch   # Touch ID
```

`~/.local/bin/harness` is a **store symlink**, so a repo edit changes nothing
until you switch. This is the single most common reason "I added it and it
does not work".

## 5. Prove it, do not assume it

```bash
harness --list          # kind <TAB> description <TAB> resumable-id
```

For anything touching the destructive path, test in a **throwaway workspace**,
never a live one:

```bash
WS=$(herdr workspace create --cwd /tmp/scratch --label zz-test --no-focus \
     | jq -r .result.workspace.workspace_id)
# ... create a tab labelled `harness`, exercise it ...
herdr workspace close "$WS"
```

The round trip that actually proves resume works — id equality alone is weak,
so check the **content** comes back:

1. start the harness, send it a distinctive marker (`herdr agent prompt`)
2. note the id: `herdr agent list`
3. `prefix+shift+a` → another harness
4. `prefix+shift+a` → back
5. the pane should show the marker again, and the same session id

## Gotchas

- **Test the REPO copy, not the installed one.** This has cost real debugging
  time here more than once: you edit `dotfiles/.local/bin/harness`, run the
  test, and it exercises the last-switched `~/.local/bin/harness`. Use the
  seam:
  ```bash
  HERDR_HARNESS_BIN=$PWD/dotfiles/.local/bin/harness ./dotfiles/.local/bin/herdr-harness-switch
  ```
  A `herdr pane run` needs the absolute repo path too — the pane's PATH finds
  the installed one.

- **Env does not reach the pane.** Overriding `XDG_STATE_HOME` for a test only
  affects the process you set it on; `harness` running *inside* the pane reads
  the real one. A test rigged that way reports a false failure.

- **Session memory is keyed by pane AND kind AND cwd.** State lives at
  `~/.local/state/herdr-harness/<session>/<pane>.json`. herdr itself keeps only
  ONE session slot per pane and **clears it when the agent kind changes**, so
  it cannot survive a round trip on its own — that is why the map exists. The
  cwd check means a recycled pane id never resumes a conversation about a
  different repo.

- **Conversations swapped before this existed are not recoverable through the
  picker.** They are still on disk; `claude --resume` / `codex resume` with no
  argument opens each tool's own picker.

- **A harness with no resume flag is fine.** It starts fresh, the picker simply
  never shows `· resume` for it. Do not invent a flag.

## Where the pieces live

| File | Role |
|---|---|
| `dotfiles/.local/bin/harness` | discovery, picker, session memory, `exec` |
| `dotfiles/.local/bin/herdr-harness-switch` | `prefix+shift+a`: record → signal → relaunch |
| `dotfiles/herdr/config.toml` | the `prefix+shift+a` binding |
| `dotfiles/.local/bin/herdr-sessionizer` | creates the `harness` tab in new spaces |
| `dotfiles/.local/bin/herdr-worktreeizer` | same for worktree spaces, and starts a NAMED agent pre-seeded with the branch context |
| `modules/home/default.nix` | installs the scripts; runs `herdr integration install` |
| `modules/darwin/packages.nix` | the CLIs themselves |
