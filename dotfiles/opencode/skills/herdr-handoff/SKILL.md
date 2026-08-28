---
name: herdr-handoff
description: Hand a task to the agent running in another herdr space, and optionally block until it answers — across harness kinds, so the other side can be claude, codex or opencode. Use when asked to send work to, message, delegate to, or get an answer from an agent in another space, pane, worktree or window; or when work belongs in a different repo or checkout than this one. Requires HERDR_ENV=1.
---

# herdr-handoff

Pass work sideways, to an agent that is already running in another space.

```bash
herdr-handoff list                                    # who is out there
herdr-handoff send homelab "Bump the k3s chart to 1.31 and push the branch."
herdr-handoff send w8:p2 "Run the suite and tell me what fails." --reply
```

`--reply` blocks until the other agent settles and prints what it wrote back.
Without it, `send` returns once the prompt is delivered.

## Addressing

`herdr-handoff list` prints ADDRESS, NAME, KIND, STATE and WHERE for every live
agent. Target by any of NAME, ADDRESS or WHERE, or a unique substring of one.
Ambiguity is refused rather than guessed.

Most panes are nameless because they came from the harness picker. Name this
one with `herdr-handoff name <name>` so others can address it readably.

## Writing the task

The receiving agent gets your text and nothing else — not your conversation,
not the user's original request. Write it for a stranger:

- the goal in a sentence, then the constraints — **what not to touch is what it
  cannot infer and will get wrong**
- paths in full; its cwd is not yours
- what "done" looks like, especially with `--reply`

`--file brief.md` or a pipe carries a longer brief. Past 8000 characters the
body is sent as a path instead, which may cost the recipient a sandbox prompt;
the command warns when that happens.

## Nothing is needed on the receiving side

The prompt is self-contained: the brief is inline, the reply path is absolute.
The other agent needs no config and no knowledge of this tool, which is why
this works against harnesses that have never heard of it.

Never send a path under `~/.cache` for it to read — a sandboxed harness stops
and asks permission to read outside its working directory, and the handoff
hangs on a dialog nobody is watching.

## When it refuses

- **`<name> is blocked`** — a dialog is up in that pane, and a submitted prompt
  would answer someone else's yes/no question. Say which pane needs clearing
  instead of passing `--force`.
- **settled without writing a reply file** — it described the result instead of
  writing it. The last pane output is printed as `unconfirmed`: scraped, not
  sent, possibly cut off. A lead, not an answer.

## Tracking

```bash
herdr-handoff inbox [--all]   # what has been passed around
herdr-handoff read <id>       # brief and reply
herdr-handoff reply <id> "…"  # answer one you were sent
```
