---
name: herdr-handoff
description: Hand a task to the agent running in another herdr space, and optionally block until it answers — across harness kinds (claude, codex, opencode) and across herdr sessions, so a personal-session agent can drive a work-session one. Use when the user asks to send work to, message, delegate to, ask, or get an answer from an agent in another space, pane, worktree or window; when work belongs in a different repo or checkout than the one you are in; or when you need to know what another agent is doing. Requires running inside herdr (HERDR_ENV=1).
---

# herdr-handoff

Passing work sideways, between agents that are already running.

```bash
herdr-handoff list                                    # who is out there
herdr-handoff send homelab "Bump the k3s chart to 1.31 and push the branch."
herdr-handoff send w8:p2 "Run the suite and tell me what fails." --reply
```

`--reply` blocks until the other agent settles and prints what it wrote back,
turning a fire-and-forget nudge into a request/response. Without it, `send`
returns as soon as the prompt is delivered.

## This is not `ListAgents`

`ListAgents`/`SendMessage` is **claude-to-claude only**. A codex or opencode
pane is not a peer, does not appear, and cannot be messaged that way. It is
also confined to sessions it can see, where this reaches every running one. It also
addresses by *session name*, a different namespace from the herdr space label —
the agent in the `_dotfiles` space registers as `herdr-implementation`, and a
space labelled `carestackone` shows up as `carestackone-d9`. Matching a space
label against that list concludes "no agent there" while an agent sits in it.

`herdr-handoff` addresses by what you can see: name, pane id, or directory.
Prefer it whenever the target is a *space*. `SendMessage` is still fine for
claude subagents you spawned yourself.

## Addressing

`herdr-handoff list` prints the roster of **every running session**, not just
yours:

```
SESSION    ADDRESS    NAME                         KIND      STATE     WHERE
personal   w8:p2      -                            opencode  idle      personal
personal   w7:p2      -                            claude    working   .dotfiles   <- you
work       wY:p2      -                            claude    idle      solytics
work       w12:p2     separate-config-and-secrets  claude    idle      refactor-separate-config-and-secrets
```

Any of NAME, ADDRESS or WHERE works as a target, plus a unique substring. Most
panes are nameless because they came from the harness picker rather than
`herdr agent start --name`; an agent can name itself with
`herdr-handoff name <name>`, which is worth doing for anything long-lived.

Ambiguity is refused, not guessed — two matches print both and exit.

### Sessions

A bare target is matched across all running sessions. Qualify it with a session
name when that is ambiguous, or when you want to be explicit:

```bash
herdr-handoff send work:fcc-monorepo "…"    # by name/dir, in one session
herdr-handoff send work:w12:p2 "…"          # the full address
```

The `<session>:` prefix is only stripped when it actually names a running
session, so a plain pane id (`w12:p2`, which also contains a colon) is never
mistaken for one.

**Pane ids are minted per session and collide across them** — `w12:p2` can
exist in both `personal` and `work` and mean two different agents. An agent is
therefore identified by `(session, pane)`, and a bare pane id is only safe when
one session has it. Prefer names.

Each session is a separate herdr server with its own socket, which is why a
plain `herdr agent list` sees only your own — `herdr --session <name>` is what
crosses the boundary, and everything here carries it through.

## Writing the task

The brief is the whole contract. The receiving agent gets your text and nothing
else: not your conversation, not the user's original request, not the file you
were both looking at. Write it as if to a stranger, because that is what it is.

- State the goal in a sentence, then the constraints — **what not to touch is
  the part it cannot infer and will get wrong**.
- Name paths in full. Its cwd is not yours.
- Say what "done" looks like, especially with `--reply`.

`--file brief.md` or a pipe carries a longer brief. Past 8000 characters the
body stops being inlined and is sent as a path instead, which may cost the
recipient a sandbox permission prompt; the command warns when it does this.

## What you do not have to do

**Nothing on the receiving side.** The prompt is self-contained — the brief is
inline and the reply path is absolute — so the other agent needs no knowledge
of this tool, no config, and no skill of its own. This is why it works against
harnesses that have never heard of it.

Do not try to help by pre-arranging anything in the target's directory, and do
not send it a path under `~/.cache` to read: a sandboxed harness stops and asks
permission to read outside its working directory, and the handoff stalls on a
dialog nobody is watching. That failure is the reason the brief is inline.

## When it refuses

**`<name> is blocked`** — a permission or trust dialog is up in that pane. A
submitted prompt would answer someone else's yes/no question, so it stops.
Tell the user which pane needs clearing rather than passing `--force`.

**Settled without writing a reply file** — it did the work and described the
result instead of writing it. The command falls back to printing that pane's
last output, labelled `unconfirmed` because it is scraped, not sent, and may be
cut off mid-thought. Treat it as a lead, not an answer; `herdr agent read
<pane>` shows more.

## Tracking

```bash
herdr-handoff inbox          # handoffs addressed to you
herdr-handoff inbox --all    # everything, with status
herdr-handoff read <id>      # the brief and its reply
herdr-handoff reply <id> "…" # answer one you were sent
```

Status is `open` (reply wanted, none yet), `answered`, or `sent`.

## Related

`herdr-worktree` creates a *new* space with a task in it. This skill talks to
one that already exists.
