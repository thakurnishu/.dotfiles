# Plan: nvim ↔ harness, for every harness

**Branch:** `feat/nvim-harness-bridge` · **Status:** proposal, nothing implemented yet

> Revised. The first draft recommended ACP via `agentic.nvim`. Probing herdr's
> own API showed that is more machinery than the job needs — see "Why we do not
> need a protocol".

## The problem

The `terminal` tab and the `harness` tab share a directory and nothing else.
Under tmux they talked: `claudecode.nvim` ran a WebSocket server inside nvim,
Claude connected to it as an "IDE", and that bought `<leader>as` to send a
selection and `<leader>ab` to add a buffer.

That integration is Claude-specific, and the tab is now a picker that can start
codex or opencode instead.

## What is broken right now

`dotfiles/nvim/after/plugin/claude.lua:99` still says:

```lua
local CLAUDE_TAB = "claude"
```

Every tab was renamed to `harness` this morning. The lookup finds nothing, so
`<leader>ac` **creates a duplicate `claude` tab** instead of reusing the one that
is there. One line, fix it first regardless of everything below.

## Why we do not need a protocol

The three harnesses speak three different protocols — Claude a WebSocket IDE
protocol, opencode built-in ACP, codex an experimental app-server. Chasing that
means either three bespoke bridges or adopting ACP and a general-purpose chat
plugin.

**But they all have one thing in common: they are TUIs reading from a terminal.**
And herdr can type into a terminal. Verified on this machine — `cat` running in a
pane, text sent from outside:

```bash
herdr pane send-text wG:p4 "$(printf 'Explain this:\n\nfunction add(a, b) {\n  return a + b\n}\n')"
```

```
Explain this:

function add(a, b) {
  return a + b
}
```

Multi-line, verbatim, no escaping problems. There is also `herdr agent prompt
<pane> <text>`, which *submits* rather than just typing — nicer, but it requires
herdr to have detected an agent in that pane (`agent_not_found` otherwise), so
`send-text` is the fallback that always works.

That is the entire transport. It is harness-agnostic **by construction**: it does
not know or care what is running in the pane, so a harness we install next month
works with no code change. No ACP, no WebSocket server, no herdr plugin, no
third-party nvim plugin.

## What we build

One Lua file, replacing the provider machinery in `claude.lua`. Roughly 80 lines.

**Finding the harness pane.** nvim is in a pane, so it has `HERDR_WORKSPACE_ID`.
Ask herdr for that workspace's panes, take the one whose tab is labelled
`harness`. If the tab exists but is sitting at a shell, run `harness` in it; if
it does not exist, create it.

**Sending.** Try `agent prompt` first, fall back to `pane send-text`:

```lua
-- selection + where it came from, so the harness can open the file itself
local payload = string.format("%s:%d-%d\n\n%s", relpath, first, last, text)
```

**The keymaps**, keeping the muscle memory already in `claude.lua`:

| Key | Does |
|---|---|
| `<leader>ac` | focus the harness tab (start one if the pane is at a shell) |
| `<leader>as` | send the visual selection, prefixed with `path:line-line` |
| `<leader>ab` | send the current buffer's path as a reference |
| `<leader>aa` | send the file under the cursor in a tree buffer |

Same prefix, same fingers, works whichever harness the picker started.

## What this gives up

Worth being explicit, because it is a real trade and not a rounding error.

`claudecode.nvim`'s IDE protocol is **two-way**. Ours is **one-way** — nvim
pushes context, the harness answers in its own pane. So we lose:

- **Diffs opening as nvim buffers**, with `<leader>aa` / `<leader>ad` to accept or deny. This is the big one. You configured unified layout and custom highlight groups for it.
- The harness seeing your cursor and selection **without being told**.
- `ClaudeCodeAdd`-style structured file references — ours are plain text the harness has to interpret.

You read the harness's output in the harness pane, the way you would if you had
typed the prompt yourself. For a workflow where the harness edits files and you
review them in the `hunk` tab, that may be the whole of what you need — but it is
less than what you have with Claude today.

**Mitigation, if the diffs turn out to matter:** keep `claudecode.nvim` bound to
its own prefix for when the harness is Claude, and use the universal bridge for
everything else. Costs a second keymap namespace and the code stays around.

## Phases

### Phase 1 — fix the stale tab name *(do now, independent)*
`CLAUDE_TAB = "claude"` → `"harness"`.
**Done when:** `<leader>ac` focuses the existing tab and the tab count stops growing.

### Phase 2 — the bridge
New `dotfiles/nvim/after/plugin/harness.lua`: pane discovery, send, the four keymaps.
**Done when:** a visual selection lands in the harness pane, with claude, codex and opencode in turn.

### Phase 3 — decide about claudecode.nvim
Use Phase 2 for a few days of real work, then either delete the ~140 lines of
provider code in `claude.lua`, or keep it on a second prefix for Claude's diffs.
**Explicitly deferred** — this is the question the first draft tried to answer
before there was any evidence.

### Phase 4 — a herdr plugin *(optional, probably not)*
herdr does have a real plugin system, verified: `herdr-plugin.toml`, actions as
plain processes, `herdr plugin link`. The invocation context carries
`workspace_cwd`, `tab_label`, `focused_pane_id`, `selected_text` and — the useful
one — **`focused_pane_agent`**, which reported `"claude"` correctly in a probe.

It would let herdr *itself* act on the editor, which no nvim plugin can do. But
nothing in Phases 1–3 needs it: nvim already knows its workspace from the
environment, and `herdr` on PATH is the whole API. **Do not build this until
there is a concrete want it answers.**

## Open questions

1. **Does `agent prompt` submit reliably across all three?** It presses enter for you. If codex or opencode need a different key to send, `send-text` plus an explicit `send-keys enter` is the fallback. Test in Phase 2.
2. **Does the harness pane need to be focused to receive input?** `send-text` worked on an unfocused pane in the probe, but that pane was running `cat`, not a TUI with its own input handling.
3. **What does a harness do with a multi-line paste?** Some TUIs treat a newline as submit and would fire the prompt half-written. Bracketed paste may be needed — `send-text` may already handle it; worth checking per harness.

## Verified vs assumed

**Verified on this machine:** the stale `CLAUDE_TAB`; that `pane send-text`
delivers multi-line text verbatim to an unfocused pane; that `agent prompt`
requires a detected agent and errors cleanly otherwise; herdr's plugin manifest
format and full invocation context, by linking a probe plugin and reading what
the action received; the CLI surfaces of `claude`, `codex` and `opencode`.

**Assumed:** how each harness's TUI reacts to injected multi-line text. That is
question 3, and it is the one thing that could force this design to change.
