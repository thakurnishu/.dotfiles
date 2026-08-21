# Plan: two-way nvim ↔ harness, for every harness

**Branch:** `feat/nvim-harness-bridge` · **Status:** Phase A not started

Two phases, shipped and used in that order:

- **Phase A — nvim → harness.** Push context out of the editor. Self-contained
  and useful on its own. Merge it, live with it.
- **Phase B — harness → nvim.** The return path: the agent reads the editor and
  proposes edits into it. **Only started once A has survived real work.**

The split is deliberate. A is small, low-risk, and needs no new process. B needs
a daemon, a protocol and untracked registration state. If A turns out to cover
90% of what you actually reach for, B may never be worth building — and that is
a result, not a failure.

---

## Background: the two mechanisms

Both probed on this machine before this document was written.

**Outbound — herdr types into the pane.** Every harness is a TUI reading a
terminal, and herdr can write to a terminal:

```bash
herdr pane send-text <pane> "$(printf 'Explain:\n\nfn add(a,b){}\n')"
```

Multi-line, verbatim, into an *unfocused* pane. `herdr agent prompt <pane> <text>`
is the better variant — it submits — but needs herdr to have detected an agent
(`agent_not_found` otherwise), so `send-text` is the fallback. Harness-agnostic
by construction: it does not know or care what runs in the pane.

**Inbound — MCP into nvim's RPC socket.** All three harnesses expose `mcp add`,
and nvim is drivable from outside:

```bash
$ nvim --server $SOCK --remote-expr 'expand("%:p")'
/…/sample.txt
$ nvim --server $SOCK --remote-expr 'luaeval("… nvim_buf_set_lines … ")'
ok
```

`--remote-send` is a trap — keystrokes land literally in the buffer.
`--remote-expr` + `luaeval` is the programmatic path.

---

# PHASE A — nvim → harness

**Goal:** from nvim, push a selection, a buffer or a file reference into whichever
harness this space is running, and focus it.

## What gets built

One file: `dotfiles/nvim/after/plugin/harness.lua`, replacing the ~140 lines of
tmux/herdr provider machinery in `claude.lua`.

No new process, no protocol, no daemon. It shells out to `herdr`, which is
already on PATH in every pane.

## Steps

### A1 — fix the stale tab name *(do first; it is a live bug)*

`claude.lua:99` still reads:

```lua
local CLAUDE_TAB = "claude"
```

Every tab was renamed to `harness`. The lookup finds nothing, so `<leader>ac`
**creates a duplicate `claude` tab** each time instead of reusing the real one.

Fix it in place before anything else, so the working state is good even if the
rest of Phase A stalls.

**Done when:** `<leader>ac` focuses the existing harness tab and the tab count
stops growing.

### A2 — find the harness pane

nvim is in a pane, so it has `HERDR_WORKSPACE_ID`. Ask herdr for that workspace's
panes and take the one whose tab is labelled `harness`.

Three cases to handle explicitly, because each has a different right answer:

| Situation | Action |
|---|---|
| tab exists, harness running in it | use that pane |
| tab exists, pane sitting at a shell | `herdr pane run <pane> harness` first |
| no harness tab (worktree spaces have none) | `herdr tab create --label harness`, then run it |

### A3 — the send helper

Try `agent prompt` first, fall back to `send-text`:

```lua
-- selection carries where it came from, so the harness can open the file itself
local payload = string.format("%s:%d-%d\n\n%s", relpath, first, last, text)
```

Path relative to the workspace root, not absolute — shorter, and it is what the
harness's own tools expect.

### A4 — keymaps

Keeping the fingers already trained by `claude.lua`:

| Key | Does |
|---|---|
| `<leader>ac` | focus the harness tab (start one if needed) |
| `<leader>as` | send visual selection, prefixed `path:first-last` |
| `<leader>ab` | send the current buffer as a reference |
| `<leader>as` in a tree buffer | send the file under the cursor |

### A5 — test against all three

Start each harness from the picker in turn and send the same selection.

**This is the step that can invalidate the design.** Some TUIs treat a newline as
submit and would fire a half-written prompt. `cat` cannot tell us — only the real
harnesses can. If it bites: bracketed paste, or `send-text` followed by an
explicit `send-keys enter`.

## Done when

- A selection sent from nvim appears, intact, in the harness pane
- Verified separately with **claude, codex and opencode**
- No duplicate tabs after repeated `<leader>ac`
- Works from a worktree space, which has no harness tab to begin with

## Risks

1. **Multi-line paste behaviour differs per harness** — A5, the main unknown.
2. **`agent prompt` may not submit uniformly.** It presses enter for you; if a
   harness wants something else, fall back to `send-text` + `send-keys`.
3. **Losing claudecode.nvim's diffs.** Phase A is one-way, so while you are
   living with it you lose in-editor diff review for Claude. Mitigation: leave
   `claude.lua` in place on its existing prefix during Phase A and delete it only
   after Phase B, or after deciding you do not miss it.

---

# PHASE B — harness → nvim

**Do not start until Phase A has been used for real work.** The point of the gap
is to find out what you actually miss.

**Goal:** the harness reads the editor's state and proposes edits back into it.

## What gets built

`dotfiles/.local/bin/herdr-nvim-mcp` — a stdio MCP server bridging into nvim's
RPC socket. **`python3Packages.mcp` is in nixpkgs at 1.29.0**, so this is an SDK
server, not hand-rolled JSON-RPC.

```
┌─ terminal tab ─────────────┐         ┌─ harness tab ─────────────────┐
│ nvim                       │         │ claude │ codex │ opencode     │
│  serverstart(SOCK) ◄───────┼── RPC ──┼── herdr-nvim-mcp (stdio MCP)  │
│  <leader>as ───────────────┼─────────┼─ herdr pane send-text ────────┤
└────────────────────────────┘         └───────────────────────────────┘
             both sides derive SOCK from $HERDR_WORKSPACE_ID
```

## Steps

### B1 — nvim publishes a socket

`vim.fn.serverstart(path)` — verified working — at:

```
${XDG_STATE_HOME:-~/.local/state}/herdr-nvim/<HERDR_WORKSPACE_ID>.sock
```

No registry and no discovery protocol: both sides are in the same workspace, so
both compute the same path.

**Collision rule for v1:** two nvims in one workspace, first wins; the second
runs without publishing. The failure mode is "the harness talks to the other
nvim", not a crash. Revisit with a per-pane socket and a `list_editors` tool only
if it bites.

### B2 — read-only tools

Read tools first: they cannot damage anything, and they are most of the value.

| Tool | Notes |
|---|---|
| `editor_context` | current file, cursor, visual selection |
| `list_buffers` | what is open, with modified flags |
| `read_buffer` | **unsaved** contents — the harness sees what you see, not what is on disk |
| `diagnostics` | **LSP errors and warnings.** nvim has language servers; the harness does not. This is the tool worth building Phase B for. |

### B3 — registration, which must stay declarative

`claude mcp add --scope user` writes `~/.claude.json`; codex writes `~/.codex/`;
opencode its own config. **All untracked state** — the same trap the gh-dash note
in `packages.nix` already calls out.

Preference order:

1. **Write the config from Nix**, where a harness reads a plain file we can own —
   as `dotfiles/claude/settings.json` already is.
2. **`home.activation`** running each `mcp add` idempotently — the pattern
   already used for `herdr integration install`.
3. Project-scoped `.mcp.json`, polluting every repo. Rejected.

**Decide this before B2 ships**, not after. Getting it wrong means a fresh
machine silently has no bridge and nothing says so.

### B4 — write tools

| Tool | Notes |
|---|---|
| `open_file` | jump the editor to `path:line` |
| `propose_diff` | open a diff buffer for accept/reject — the `claudecode.nvim` feature otherwise lost |
| `notify` | message in the editor |

### B5 — decide about claudecode.nvim

Delete its provider code, or keep it on a second prefix for Claude's native
diffs. **Deliberately deferred to here** — decide with evidence, not before.

## Done when

- Each harness can answer "what am I looking at?" and "what are the LSP errors?"
- A proposed edit opens as a diff in nvim
- Registration survives a fresh machine, i.e. it is in the repo

## Risks

1. **Does the MCP server inherit `HERDR_WORKSPACE_ID`?** It is spawned by the
   harness, which has it, so process inheritance says yes — but it is unverified
   and the whole discovery scheme rests on it. **First thing B1 checks.**
   Fallback: pass it at registration (`codex --env` and equivalents).
2. **Registration as untracked state** — B3.
3. **Two nvims, one workspace** — B1's first-wins rule.
4. **`propose_diff` is the biggest single piece here** and the most likely to
   disappoint. If it gets ugly, keeping `claudecode.nvim` for Claude and living
   with one-way elsewhere is a legitimate stopping point.

---

## Not in either phase: a herdr plugin

herdr has a real plugin system — verified by linking a probe and reading what the
action received: `herdr-plugin.toml`, actions as plain processes, and an
invocation context carrying `workspace_cwd`, `tab_label`, `focused_pane_id`,
`selected_text` and `focused_pane_agent` (which reported `"claude"` correctly).

**Neither phase needs it.** nvim gets its workspace from the environment, the MCP
server gets it the same way, and `herdr` on PATH is the whole API. A plugin buys
one thing neither side can: letting *herdr* act on the editor — a herdr
keybinding that pushes the focused pane's selection into nvim, say. Build it when
there is a concrete want.

## Verified vs assumed

**Verified on this machine:** `pane send-text` delivers multi-line text verbatim
to an unfocused pane; `agent prompt` requires a detected agent and errors cleanly;
nvim RPC round-trip (read buffer, query file, write lines, open at line) from an
outside process; `--remote-send` is unsuitable, `--remote-expr` + `luaeval` works;
`vim.fn.serverstart` publishes a predictable socket; all three harnesses expose
`mcp add`; `python3Packages.mcp` 1.29.0 is in nixpkgs; herdr's plugin manifest
format and invocation context; the stale `CLAUDE_TAB`.

**Assumed:** how each harness's TUI handles injected multi-line text (Phase A
risk 1); MCP env inheritance (Phase B risk 1); that `propose_diff` can be made
pleasant (Phase B risk 4).
