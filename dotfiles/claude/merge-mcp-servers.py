#!/usr/bin/env python3
"""Merge the repo's declared MCP servers into Claude Code's ~/.claude.json.

    merge-mcp-servers.py <target .claude.json> <declared mcp-servers.json>

Called from modules/home/default.nix on every switch. See the comment there
for why this is a merge and not a symlink: the target is Claude Code's STATE
file, rewritten on every startup, and tracking it whole would drag 90 KB of
churn plus account identifiers into git.

Merge rules, deliberately narrow:

  * only the top-level `mcpServers` key is ever touched;
  * declared servers win, so the tracked JSON is the source of truth for the
    names it lists;
  * undeclared servers are PRESERVED. Someone running `claude mcp add` for a
    one-off should not have it silently deleted by the next rebuild. The cost
    is that removing a server means both deleting it here and running
    `claude mcp remove <name>` once -- stated in the nix comment too.

Idempotent, and a no-op write when nothing changed, so repeated switches do
not churn the file's mtime.

A missing target is created with just `mcpServers`; Claude Code fills in the
rest on next start. Unparseable JSON is left ALONE and reported -- clobbering
the user's startup state to install two URLs is a bad trade.
"""

import json
import os
import sys
import tempfile


def main(argv):
    if len(argv) != 3:
        print(__doc__.strip().splitlines()[2].strip(), file=sys.stderr)
        return 2

    target, declared_path = argv[1], argv[2]

    with open(declared_path) as fh:
        declared = json.load(fh)
    if not isinstance(declared, dict):
        print(f"claude-mcp: {declared_path} is not a JSON object", file=sys.stderr)
        return 1

    if os.path.exists(target):
        try:
            with open(target) as fh:
                config = json.load(fh)
        except (json.JSONDecodeError, UnicodeDecodeError) as exc:
            # Not our file to repair. Say so and change nothing.
            print(f"claude-mcp: {target} is not valid JSON ({exc}); left untouched",
                  file=sys.stderr)
            return 1
        if not isinstance(config, dict):
            print(f"claude-mcp: {target} is not a JSON object; left untouched",
                  file=sys.stderr)
            return 1
    else:
        config = {}

    existing = config.get("mcpServers")
    if not isinstance(existing, dict):
        existing = {}

    merged = dict(existing)
    merged.update(declared)

    if merged == existing and "mcpServers" in config:
        print(f"claude-mcp: {len(declared)} declared server(s) already current")
        return 0

    config["mcpServers"] = merged

    # Write via a temp file in the same directory so the replace is atomic --
    # Claude Code may be running and reading this file right now.
    #
    # Preserve the mode: ~/.claude.json is 0600 and holds account state, and
    # mkstemp would otherwise hand it back as 0600 anyway -- but an existing
    # file's mode is copied rather than assumed, in case it was tightened.
    directory = os.path.dirname(os.path.abspath(target)) or "."
    fd, tmp = tempfile.mkstemp(dir=directory, prefix=".claude.json.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as fh:
            json.dump(config, fh, indent=2)
            fh.write("\n")
        if os.path.exists(target):
            os.chmod(tmp, os.stat(target).st_mode & 0o7777)
        else:
            os.chmod(tmp, 0o600)
        os.replace(tmp, target)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise

    added = sorted(set(declared) - set(existing))
    changed = sorted(k for k in declared if k in existing and existing[k] != declared[k])
    bits = []
    if added:
        bits.append("added " + ", ".join(added))
    if changed:
        bits.append("updated " + ", ".join(changed))
    print("claude-mcp: " + ("; ".join(bits) if bits else "wrote mcpServers"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
