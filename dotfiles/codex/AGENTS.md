# Global notes

## Handing work to an agent in another herdr space

When `HERDR_ENV=1`, other agents are running in other spaces and `herdr-handoff`
passes work to them — whatever harness each is running.

```bash
herdr-handoff list                                  # ADDRESS / NAME / KIND / STATE / WHERE
herdr-handoff send <target> "<task>"                # deliver and return
herdr-handoff send <target> "<task>" --reply        # block, print what it answers
```

Target by name, pane id (`w8:p2`), or directory basename. `list` covers every
running herdr session, not just this one; qualify a target with a session name
when a bare one is ambiguous (`work:fcc-monorepo`, `work:w12:p2`). Pane ids
collide across sessions, so prefer names.

Reach for it when the user asks to send work to, message or get an answer from
another space, pane, session or worktree, or when the work belongs in a
checkout other than this one.

The receiving agent gets your text and nothing else — no shared conversation.
State the goal, the constraints (what NOT to touch), and full paths.

Nothing is needed on the receiving side; the prompt carries the brief inline
and an absolute reply path. Never hand another agent a path under `~/.cache` to
read — a sandboxed harness will stop and ask permission to read outside its
working directory, and the handoff hangs on a dialog nobody is watching.

`herdr-handoff inbox`, `read <id>` and `reply <id> "…"` cover the other side.
