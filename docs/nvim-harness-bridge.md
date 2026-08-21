# Plan: nvim ↔ harness, for every harness

**Branch:** `feat/nvim-harness-bridge` · **Status:** proposal, nothing implemented yet

## The problem

The `terminal` tab and the `harness` tab are two panes that share a directory and
nothing else. Under tmux they talked: `claudecode.nvim` ran a WebSocket server
inside nvim, Claude Code connected to it as an "IDE", and that bought
`<leader>as` to send a visual selection, `<leader>ab` to add a buffer, and diffs
opened as real nvim buffers instead of scrolling past in a chat log.

Two things broke that, one old and one from today.

## What is actually broken right now

**1. The nvim provider is looking for a tab that no longer exists.**

`dotfiles/nvim/after/plugin/claude.lua:99` says:

```lua
local CLAUDE_TAB = "claude"
```

Every space's second tab was renamed to `harness` this morning. `herdr_find_tab()`
matches on that label, finds nothing, and creates a *second* tab called `claude`
each time you hit `<leader>ac`. This is a one-line fix and should land first,
independent of everything else below.

**2. It only ever worked for Claude.**

The provider is claudecode.nvim's, the env it forwards is Claude's
(`CLAUDE_CODE_SSE_PORT`, `ENABLE_IDE_INTEGRATION`), and the tab it opens runs
`claude`. Now that the tab is a *picker*, the editor bridge has to survive you
choosing codex or opencode.

## What each harness actually offers

Verified from the installed binaries, not from docs:

| Harness | Editor-facing surface |
|---|---|
| `claude` | WebSocket IDE protocol. `claudecode.nvim` implements the nvim end. Also `claude-code-acp` — **in nixpkgs at 0.64.0** — which exposes Claude over ACP. |
| `opencode` | `opencode acp` (Agent Client Protocol server), `opencode serve` (headless HTTP), `opencode attach <url>`. ACP is built in — no bridge needed. |
| `codex` | `codex app-server` (experimental), `codex mcp-server` (stdio MCP), and a TUI that can connect to a remote app-server over websocket. |

Three harnesses, three protocols. That is the whole design problem.

## The fork in the road

### Option A — one bespoke bridge per harness

Keep `claudecode.nvim` for Claude, add `opencode.nvim` for opencode, find or
write something for codex. Each gets its own provider, its own keymaps, its own
failure modes.

- **For:** claudecode.nvim already works and is already configured; no new protocol to learn.
- **Against:** three plugins, three keymap namespaces, three things to debug. Adding a fourth harness means writing a fourth integration. The `harness` picker promises "any agent on PATH"; this delivers "any of the three we hand-wired".

### Option B — ACP as the single protocol *(recommended)*

The Agent Client Protocol is, roughly, LSP for coding agents: one client, many
agents. `agentic.nvim` is an ACP chat client for nvim with providers for
Claude, Codex, OpenCode, Gemini, Cursor, Copilot and others. Sessions are
interchangeable with the terminal, and it reuses the MCP servers, skills and
subagents already configured for each CLI.

- **For:** one plugin, one keymap set, one mental model. A new harness that speaks ACP works with no code from us. `claude-code-acp` is already packaged in nixpkgs and `opencode acp` is built in, so two of your three are ready today.
- **Against:** a newer, less-proven plugin than claudecode.nvim. Codex's ACP story needs checking — it may need an adapter. The inline-diff behaviour you tuned (`ClaudeCodeInlineDiffAdd`, unified layout) is claudecode.nvim-specific and would have to be re-established or given up.

### Recommendation

**Option B, arrived at in stages, with A as the fallback.** The deciding argument
is that the `harness` tab is now open-ended by design: the picker offers whatever
is installed, so the editor bridge should be open-ended too. But we should not
rip out a working Claude integration to find out — run both, compare, then cut.

## Does this need a herdr plugin?

**herdr has a real plugin system.** I confirmed it against the running binary
rather than the docs:

```toml
# herdr-plugin.toml
id = "example"
name = "Example"
version = "0.0.1"
min_herdr_version = "0.1.0"     # required; link fails without it

[[actions]]
id = "hello"
title = "Hello"
command = ["/path/to/script.sh", "ARG1"]   # `command` is required
```

`herdr plugin link <dir>` registers it; `herdr plugin action invoke <id>` runs it.
The action is a plain process, and herdr hands it context through the environment:

```
HERDR_PLUGIN_CONTEXT_JSON={
  "workspace_id":"w7", "workspace_cwd":"/Users/…/.dotfiles",
  "worktree":{"repo_root":"…","checkout_path":"…","is_linked_worktree":false},
  "tab_id":"w7:t2", "tab_label":"harness",
  "focused_pane_id":"w7:p2", "focused_pane_cwd":"…",
  "focused_pane_agent":"claude", "focused_pane_status":"working",
  "invocation_source":"cli"
}
HERDR_PLUGIN_ROOT=…  HERDR_PLUGIN_STATE_DIR=…  HERDR_PLUGIN_CONFIG_DIR=…
HERDR_SOCKET_PATH=…  HERDR_WORKSPACE_ID=…  HERDR_PANE_ID=…
```

The schema also carries `selected_text` and `clicked_url` / `link_handler_id` on
that context, and `plugin.pane.open` lets a plugin own a pane with its own
entrypoint, placement and env.

**`focused_pane_agent` is the important field.** herdr already knows *which*
harness is running in the pane — it reported `"claude"` correctly in my probe.
That is exactly the routing key a multi-harness bridge needs, and we would
otherwise have had to infer it.

### Where a herdr plugin helps, and where it does not

It **does not** carry the editor bridge. nvim talks to the harness directly over
ACP/WebSocket; herdr is not in that path and putting it there would add a hop for
nothing.

It **does** solve the surrounding problems, which are real:

- **Finding the harness pane.** Today the nvim provider shells out to `herdr tab list` and greps for a label. A plugin gets `focused_pane_agent` and the workspace's panes handed to it.
- **Routing by harness.** One action, "send selection to the harness in this space", that dispatches on `focused_pane_agent` — ACP for opencode, IDE socket for claude, whatever codex ends up needing.
- **Driving it from the herdr side.** A keybinding or a click in herdr that acts on the *editor*, which no nvim plugin can offer.

So: **a small herdr plugin, later, as the glue — not as the transport.** Phase 4,
and genuinely optional.

## Proposed phases

Each phase is separately mergeable and separately useful.

### Phase 1 — stop the bleeding *(small, do regardless)*
- `CLAUDE_TAB = "claude"` → `"harness"` in `claude.lua`.
- Verify `<leader>ac` reuses the existing tab instead of spawning a duplicate.
- **Done when:** `<leader>ac` from the terminal tab focuses the harness tab, and the tab count does not grow.

### Phase 2 — prove ACP with one harness
- Add `claude-code-acp` (nixpkgs) and `agentic.nvim` to the config.
- Wire it under a *separate* keymap prefix so claudecode.nvim keeps working side by side.
- **Done when:** a visual selection reaches Claude through ACP, and the reply lands in nvim.

### Phase 3 — the other two
- opencode via its built-in `opencode acp`.
- codex: establish whether ACP works, or whether `app-server` / `mcp-server` is the route. **This is the unknown.**
- **Done when:** the same keymap works whichever harness the picker started.

### Phase 4 — herdr plugin *(optional glue)*
- `herdr-plugin.toml` with actions like "send selection to this space's harness", dispatching on `focused_pane_agent`.
- Bind it in `herdr/config.toml`.
- **Done when:** the action works from a herdr keybinding with no nvim involvement.

### Phase 5 — decide
- Keep both, or delete `claudecode.nvim` and its ~140 lines of provider code.
- **Only after Phase 3 has run for real work**, not on the strength of a demo.

## Open questions

1. **Codex + ACP.** `agentic.nvim` lists a Codex provider, but codex's own CLI advertises `app-server` and `mcp-server`, not ACP. Needs a real test — it is the most likely place this plan changes shape.
2. **The inline diff.** The unified red/green diff and its custom highlights are claudecode.nvim features. Does ACP give an equivalent, or is that a real loss?
3. **Session identity.** herdr resumes agent panes via `pane.report_agent_session`. If nvim spawns the harness over ACP instead of the pane running it, does herdr still see an agent to report on? Worth checking before Phase 3, because losing the sidebar's state would be a bad trade.
4. **Two clients, one session.** If nvim and the harness tab are both attached, who owns the conversation? opencode's `attach` suggests this is expected; Claude's IDE protocol assumes one editor.

## What I verified vs. assumed

**Verified on this machine:** the stale `CLAUDE_TAB`; herdr's plugin manifest
format, required fields, and the full invocation context (by linking a probe
plugin and reading what the action received); the CLI surfaces of `codex`,
`opencode` and `claude`; that `claude-code-acp` 0.64.0 is in nixpkgs.

**Not verified — taken from docs and search:** everything about `agentic.nvim`'s
behaviour, ACP's suitability for codex, and whether ACP can reproduce the inline
diff. Phase 2 exists to test the first of those cheaply.
