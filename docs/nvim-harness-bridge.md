# Plan: two-way nvim ↔ harness, for every harness

**Branch:** `feat/nvim-harness-bridge` · **Status:** Phase A not started

Two phases, shipped and used in that order:

- **Phase A — nvim → harness.** Push context out of the editor. Self-contained,
  no new process. Merge it and live with it.
- **Phase B — harness → nvim.** The return path. **Only started once A has
  survived real work.**

The split is deliberate. A is one plugin and shells out to a CLI already on PATH.
B needs a daemon, a protocol, and untracked registration state across three
harnesses. If A covers 90% of what you reach for, B may never be worth building
— and that is a result, not a failure.

---

## Where the editor config actually stands

Three files are involved, and two of them are currently broken under herdr.
Measured, not assumed.

### `after/plugin/claude.lua` — 237 lines, partly working

Configures `claudecode.nvim` with a tmux provider *and* a herdr provider. The
herdr one works, except:

```lua
local CLAUDE_TAB = "claude"     -- line 99
```

Every tab was renamed to `harness`. The lookup finds nothing, so `<leader>ac`
**creates a duplicate `claude` tab** each time instead of reusing the real one.

### `after/plugin/opencode.lua` — 65 lines, entirely dead

Configures `opencode.nvim` — which *is* installed — but every path in it is
tmux-only:

```lua
local session_id = tonumber(vim.fn.system("tmux display-message -p '#{session_id}' …"))
return 30000 + (session_id % 10000)
```

Under herdr, verified in a real pane:

```
$TMUX                             = nil
tmux server processes             = 0
vim.g.opencode_opts.server.port   = nil
```

So the toggle warns "Not inside a tmux session" and the server port is `nil`.
Worse, it holds live keymaps for that dead path — `<C-a>`, `<C-x>`, `go`, `goo`,
`<S-C-u>`, `<S-C-d>` — and it **remapped `<C-a>`/`<C-x>` to `+`/`-`**, changing
increment/decrement for a plugin that no longer functions.

### There is no shared layer

Both files reimplement "find the tab, make it if missing, focus it" against
different multiplexers. That duplication is why the rename broke one and not the
other, and it is the actual thing to fix.

---

## Phase A builds a plugin, not another config file

```
dotfiles/nvim/
  lua/herdr-harness/
    init.lua      -- setup(), public API, keymaps
    herdr.lua     -- thin wrapper over the herdr CLI (snapshot, tab, pane, send)
    payload.lua   -- formatting: selection, buffer, tree file
  after/plugin/
    herdr-harness.lua   -- require("herdr-harness").setup({ … })
```

Why a `lua/` module rather than a fourth `after/plugin` script:

- **Testable in isolation** — `:lua =require("herdr-harness.herdr").find_pane()` without triggering keymaps or setup.
- **Reloadable** — clear `package.loaded` and re-require while iterating, instead of restarting nvim.
- **One owner for tab logic** — `claude.lua`'s provider becomes a few lines delegating to it, so a rename can never again break one caller and not the other.
- **Extractable** — if it earns its keep it becomes `herdr-harness.nvim`, a repo, rather than something welded to this config.

`after/plugin/herdr-harness.lua` stays a thin `setup()` call, matching how the
rest of the config is organised.

---

# PHASE A — nvim → harness

**Goal:** from nvim, push a selection, buffer or file reference into whichever
harness this space is running, and focus it. Works the same for claude, codex and
opencode because it does not know which is running.

## Mechanism *(proven)*

herdr types into the pane. Every harness is a TUI reading a terminal:

```bash
herdr pane send-text <pane> "$(printf 'Explain:\n\nfn add(a,b){}\n')"
```

Multi-line, verbatim, into an *unfocused* pane. `herdr agent prompt <pane> <text>`
is better where it works — it submits — but needs a detected agent
(`agent_not_found` otherwise), so `send-text` is the fallback.

## Steps

### A1 — the module skeleton

`herdr.lua`: `snapshot()`, `find_pane()`, `ensure_tab()`, `send()`. Pure functions
over the herdr CLI, no keymaps, no side effects on load.

### A2 — finding the harness pane

nvim has `HERDR_WORKSPACE_ID`. Ask herdr for that workspace's panes, take the one
whose tab is labelled `harness`. Three cases, three different right answers:

| Situation | Action |
|---|---|
| tab exists, harness running | use that pane |
| tab exists, pane at a shell | `herdr pane run <pane> harness` first |
| no harness tab | `herdr tab create --label harness`, then run it |

The third is not hypothetical: **worktree spaces have no harness tab** — they are
`terminal, lazygit, hunk`.

### A3 — payloads

```lua
-- selection carries its origin so the harness can open the file itself
string.format("%s:%d-%d\n\n%s", relpath, first, last, text)
```

Relative to the workspace root, not absolute: shorter, and it matches what the
harnesses' own file tools expect.

### A4 — keymaps

Keeping the fingers `claude.lua` already trained:

| Key | Does |
|---|---|
| `<leader>ac` | focus the harness tab, starting one if needed |
| `<leader>as` | send visual selection, prefixed `path:first-last` |
| `<leader>ab` | send the current buffer as a reference |
| `<leader>as` in a tree buffer | send the file under the cursor |

### A5 — resolve the two existing files

- **`claude.lua`:** delete its `herdr_provider` and delegate to the new module, so
  tab logic has one owner. Keep `claudecode.nvim` itself — its in-editor diffs are
  real and Phase A does not replace them.
- **`opencode.lua`:** decide. It is dead under herdr and is holding `<C-a>`/`<C-x>`
  hostage. **Recommend retiring it** — deleting the file restores normal
  increment/decrement, and the new module covers opencode the same as any other
  harness. Porting it to herdr is Phase B work, if ever, since its value is its
  server protocol.

**This is a decision, not a mechanical step.** Retiring `opencode.lua` gives up
`opencode.nvim`'s richer integration for opencode specifically.

### A6 — test against all three harnesses

Start each from the picker in turn; send the same selection.

**This is the step that can invalidate the design.** Some TUIs treat a newline as
submit and would fire a half-written prompt. `cat` proved the transport but
cannot tell us this — only the real harnesses can. If it bites: bracketed paste,
or `send-text` followed by an explicit `send-keys enter`.

## Done when

- A selection sent from nvim lands intact in the harness pane
- Verified separately with **claude, codex and opencode**
- Repeated `<leader>ac` does not grow the tab count
- Works from a worktree space, which starts with no harness tab
- `<C-a>` / `<C-x>` behave as increment/decrement again, if `opencode.lua` is retired

## Risks

1. **Multi-line paste differs per harness** — A6, the main unknown.
2. **`agent prompt` may not submit uniformly**; fall back to `send-text` + `send-keys`.
3. **Phase A is one-way**, so you keep `claudecode.nvim` for Claude's diffs until
   Phase B or until you decide you do not miss them.

---

# PHASE B — harness → nvim

**Do not start until Phase A has been used for real work.** The gap exists to
find out what you actually miss.

## Mechanism *(proven)*

All three harnesses expose `mcp add`, and nvim is drivable from outside:

```bash
$ nvim --server $SOCK --remote-expr 'expand("%:p")'
/…/sample.txt
$ nvim --server $SOCK --remote-expr 'luaeval("… nvim_buf_set_lines … ")'
ok
```

`--remote-send` is a trap — keystrokes land literally in the buffer.
`--remote-expr` + `luaeval` is the programmatic path.

So one process bridges MCP to nvim RPC, and **MCP being the common denominator is
what makes it one server instead of three adapters.**

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

`vim.fn.serverstart(path)` — verified — at:

```
${XDG_STATE_HOME:-~/.local/state}/herdr-nvim/<HERDR_WORKSPACE_ID>.sock
```

No registry: both sides are in the same workspace and compute the same path.

**Collision rule for v1:** first nvim wins; a second runs without publishing. The
failure mode is "the harness talks to the other nvim", not a crash.

### B2 — read-only tools

| Tool | Notes |
|---|---|
| `editor_context` | current file, cursor, visual selection |
| `list_buffers` | what is open, with modified flags |
| `read_buffer` | **unsaved** contents — the harness sees what you see, not disk |
| `diagnostics` | **LSP errors and warnings.** nvim has language servers; the harness does not. This is the tool worth building Phase B for. |

`python3Packages.mcp` is in nixpkgs at **1.29.0**, so this is an SDK server, not
hand-rolled JSON-RPC.

### B3 — registration, which must stay declarative

`claude mcp add --scope user` writes `~/.claude.json`; codex writes `~/.codex/`;
opencode its own config. **All untracked state** — the trap the gh-dash note in
`packages.nix` already calls out.

1. **Write the config from Nix** where a harness reads a plain file we can own,
   as `dotfiles/claude/settings.json` already is.
2. **`home.activation`** running each `mcp add` idempotently — the pattern used
   for `herdr integration install`.
3. Project-scoped `.mcp.json`. Rejected: pollutes every repo.

**Decide before B2 ships.** Getting it wrong means a fresh machine silently has
no bridge.

### B4 — write tools

`open_file` (jump to `path:line`), `propose_diff` (accept/reject in the editor —
the `claudecode.nvim` feature otherwise lost), `notify`.

### B5 — decide about claudecode.nvim

Delete its provider code, or keep it for Claude's native diffs. **Deliberately
deferred to here** — decide with evidence.

## Risks

1. **Does the MCP server inherit `HERDR_WORKSPACE_ID`?** Spawned by the harness,
   which has it, so inheritance says yes — unverified, and the discovery scheme
   rests on it. **First thing B1 checks.** Fallback: pass it at registration.
2. **Registration as untracked state** — B3.
3. **Two nvims, one workspace** — B1's first-wins rule.
4. **`propose_diff` is the biggest piece here** and the likeliest to disappoint.
   If it gets ugly, keeping `claudecode.nvim` for Claude and living with one-way
   elsewhere is a legitimate stopping point.

---

## Not in either phase: a herdr plugin

herdr has a real plugin system — verified by linking a probe and reading what the
action received: `herdr-plugin.toml`, actions as plain processes, and an
invocation context carrying `workspace_cwd`, `tab_label`, `focused_pane_id`,
`selected_text` and `focused_pane_agent` (which reported `"claude"` correctly).

**Neither phase needs it.** nvim gets its workspace from the environment, the MCP
server the same way, and `herdr` on PATH is the whole API. A plugin buys one thing
neither side can: letting *herdr* act on the editor. Build it when there is a
concrete want.

## Verified vs assumed

**Verified on this machine:** `opencode.lua` computes a `nil` port with no tmux
server running; the stale `CLAUDE_TAB`; `pane send-text` delivers multi-line text
verbatim to an unfocused pane; `agent prompt` requires a detected agent; the nvim
RPC round-trip (read buffer, query file, write lines, open at line) from an
outside process; `--remote-send` unsuitable, `--remote-expr` + `luaeval` works;
`vim.fn.serverstart` publishes a predictable socket; all three harnesses expose
`mcp add`; `python3Packages.mcp` 1.29.0 in nixpkgs; herdr's plugin manifest format
and invocation context.

**Assumed:** how each harness's TUI handles injected multi-line text (A risk 1);
MCP env inheritance (B risk 1); that `propose_diff` can be made pleasant (B risk 4).
