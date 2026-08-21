# Plan: two-way nvim ↔ harness, for every harness

**Branch:** `feat/nvim-harness-bridge` · **Status:** proposal, nothing implemented

> Third draft. First chased ACP + `agentic.nvim`; second dropped protocols for
> one-way `send-text`. This one is two-way, which needs a real component — but
> a smaller and more general one than the ACP route.

## Goal

What `claudecode.nvim` gives you with Claude today, available whichever harness
the picker started:

- nvim pushes context to the harness (selection, buffer, file refs)
- the harness reaches back into nvim (open a file at a line, read the selection,
  see LSP diagnostics, propose a diff you accept or reject in the editor)

## The two directions use different mechanisms

Both proven on this machine before writing this.

### nvim → harness: herdr types into the pane

```bash
herdr pane send-text <pane> "$(printf 'Explain:\n\nfn add(a,b){}\n')"
```

Multi-line, verbatim, into an unfocused pane. `herdr agent prompt <pane> <text>`
is the nicer variant — it submits — but requires herdr to have detected an agent
(`agent_not_found` otherwise), so `send-text` is the fallback.

Harness-agnostic by construction: it does not know what is running in the pane.

### harness → nvim: MCP, into nvim's RPC socket

**All three harnesses speak MCP.** Verified: `claude mcp add <name> <cmd> [args]`,
`codex mcp add <NAME> -- <COMMAND>`, `opencode mcp add`.

**nvim exposes a full RPC API to any process.** Verified — an outside process
reading and writing a running nvim:

```bash
$ nvim --server $SOCK --remote-expr 'expand("%:p")'
/…/sample.txt
$ nvim --server $SOCK --remote-expr 'luaeval("(function() vim.api.nvim_buf_set_lines(0,1,2,false,{\"CHANGED\"}) return \"ok\" end)()")'
ok
$ nvim --server $SOCK --remote-expr 'join(getline(1,"$"), " | ")'
line one | CHANGED | line three
$ nvim --server $SOCK --remote-expr 'luaeval("(function() vim.cmd(\"edit +2 /etc/hosts\") return … end)()")'
/etc/hosts:2
```

Note `--remote-send` is the wrong tool — keystrokes land literally in the buffer.
`--remote-expr` with `luaeval` is the programmatic path.

So the missing piece is one process that speaks MCP on one side and nvim RPC on
the other. **That is the thing we build.** One server, all three harnesses,
because MCP is the common denominator rather than an adapter per harness.

## Architecture

```
┌─ terminal tab ─────────────┐         ┌─ harness tab ─────────────────┐
│ nvim                       │         │ claude │ codex │ opencode     │
│                            │         │            │                  │
│  serverstart(SOCK) ◄───────┼── RPC ──┼── herdr-nvim-mcp (stdio MCP)  │
│                            │         │            ▲                  │
│  <leader>as ───────────────┼─────────┼─ herdr pane send-text ────────┤
└────────────────────────────┘         └───────────────────────────────┘
             both sides derive SOCK from $HERDR_WORKSPACE_ID
```

### Socket discovery

nvim and the MCP server are in different panes of the same **workspace**, and
both inherit `HERDR_WORKSPACE_ID` from herdr. So both compute the same path with
no registry, no config, no discovery protocol:

```
${XDG_STATE_HOME:-~/.local/state}/herdr-nvim/<HERDR_WORKSPACE_ID>.sock
```

nvim publishes it — `vim.fn.serverstart(path)` verified working — and the MCP
server connects to it. When nvim is not running, tools return "no editor in this
workspace" rather than failing obscurely.

**Collision:** two nvims in one workspace both want that path. v1 rule: first one
wins, the second runs without publishing. Good enough for terminal-tab-plus-nvim,
and the failure mode is "the harness talks to the other nvim", not a crash. If it
bites, the fix is a per-pane socket plus a `list_editors` tool.

## Components

### 1. `dotfiles/nvim/after/plugin/harness.lua`

Replaces the ~140 lines of provider machinery in `claude.lua`.

- On startup inside herdr: `serverstart` at the workspace socket path
- Find the `harness` tab's pane from `herdr api snapshot`
- Send helpers, `agent prompt` first and `pane send-text` as fallback
- Keymaps, keeping the fingers already trained:

| Key | Does |
|---|---|
| `<leader>ac` | focus the harness tab, starting `harness` if the pane is at a shell |
| `<leader>as` | send visual selection, prefixed `path:first-last` |
| `<leader>ab` | send the current buffer as a reference |
| `<leader>aa` / `<leader>ad` | accept / reject a proposed diff |

### 2. `dotfiles/.local/bin/herdr-nvim-mcp`

A stdio MCP server. **`python3Packages.mcp` is in nixpkgs at 1.29.0**, so this is
an SDK server rather than hand-rolled JSON-RPC.

Tools exposed to the harness:

| Tool | Direction | Notes |
|---|---|---|
| `editor_context` | read | current file, cursor, visual selection |
| `list_buffers` | read | what is open, with modified flags |
| `read_buffer` | read | unsaved contents — the harness sees what you see, not what is on disk |
| `diagnostics` | read | **LSP errors/warnings.** nvim has language servers; the harness does not. Highest-value tool here. |
| `open_file` | write | jump the editor to `path:line` |
| `propose_diff` | write | opens a diff buffer for review — the `claudecode.nvim` feature we would otherwise lose |
| `notify` | write | message in the editor |

Read tools first; they cannot damage anything.

### 3. Registration — the part that must stay declarative

`claude mcp add --scope user` writes `~/.claude.json`; codex writes `~/.codex/`;
opencode its own config. **All untracked state**, the exact problem the gh-dash
extension note in `packages.nix` already calls out.

Options, in order of preference:

1. **Write the config files from Nix** where each harness reads a plain file we can own — the way `dotfiles/claude/settings.json` is already an out-of-store symlink.
2. **`home.activation`** running each harness's `mcp add`, idempotently — the pattern already used for `herdr integration install`.
3. Project-scoped `.mcp.json`, which pollutes every repo. Rejected.

This needs deciding before Phase 3, not after: get it wrong and a fresh machine
silently has no bridge.

## Phases

Each is separately mergeable.

### Phase 1 — fix the stale tab name *(do now, independent)*
`claude.lua:99` still says `CLAUDE_TAB = "claude"`; the rename to `harness` broke
the lookup so `<leader>ac` spawns a duplicate tab.
**Done when:** `<leader>ac` focuses the existing tab, tab count stops growing.

### Phase 2 — nvim → harness *(useful alone)*
`harness.lua`: pane discovery, send helpers, keymaps, `serverstart`.
**Done when:** a selection lands in the harness pane, with claude, codex and
opencode in turn.

### Phase 3 — harness → nvim, read-only
`herdr-nvim-mcp` with `editor_context`, `list_buffers`, `read_buffer`,
`diagnostics`. Registration decided per the section above.
**Done when:** each harness can answer "what am I looking at?" and "what are the
LSP errors in this file?"

### Phase 4 — write tools
`open_file`, `propose_diff`, `notify`.
**Done when:** the harness proposes an edit and it opens as a diff in nvim.

### Phase 5 — decide about claudecode.nvim
After real use: delete its provider code, or keep it on a second prefix for
Claude's native diffs. **Deliberately deferred** — no evidence yet.

## Does this need a herdr plugin?

herdr has a real plugin system — verified by linking a probe and reading what the
action received: `herdr-plugin.toml`, actions as plain processes, and an
invocation context carrying `workspace_cwd`, `tab_label`, `focused_pane_id`,
`selected_text`, and `focused_pane_agent` (which correctly reported `"claude"`).

**But nothing in Phases 1–4 needs it.** nvim gets its workspace from the
environment; the MCP server gets it the same way; `herdr` on PATH is the whole
API. A herdr plugin buys one thing neither side can do: letting *herdr* act on
the editor — a herdr keybinding that sends the focused pane's selection into
nvim, say. Worth building when there is a concrete want. Not now.

## Risks and unknowns

1. **Does the MCP server inherit `HERDR_WORKSPACE_ID`?** It is spawned by the harness, which has it, so ordinary process inheritance says yes — but unverified, and the whole discovery scheme rests on it. **First thing Phase 3 checks.** Fallback: pass it at registration time via `codex --env` / equivalent.
2. **Multi-line paste into a TUI.** Some TUIs treat newline as submit and would fire a half-written prompt. `cat` cannot tell us; each harness must be tried. May need bracketed paste or `send-keys enter` separately.
3. **Two nvims, one workspace.** Documented above; first wins.
4. **MCP config as untracked state.** The registration question. Bad answer here means a fresh machine has no bridge and nothing says so.
5. **`propose_diff` scope.** Rebuilding claudecode.nvim's diff UI is the largest single piece of work in this plan and the most likely to disappoint. If Phase 4 gets ugly, keeping claudecode.nvim for Claude and living with one-way for the others is a legitimate stopping point.

## Verified vs assumed

**Verified on this machine:** `pane send-text` delivers multi-line text verbatim
to an unfocused pane; `agent prompt` requires a detected agent; nvim RPC
round-trip (read buffer, query file, write lines, open at line) from an outside
process; `--remote-send` is unsuitable while `--remote-expr` + `luaeval` works;
`vim.fn.serverstart` publishes a predictable socket; all three harnesses expose
`mcp add`; `python3Packages.mcp` 1.29.0 is in nixpkgs; herdr's plugin manifest
format and invocation context; the stale `CLAUDE_TAB`.

**Assumed:** MCP env inheritance (risk 1); TUI paste behaviour (risk 2); that
`propose_diff` can be made pleasant (risk 5).
