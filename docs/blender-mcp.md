# Blender + MCP for Claude Code

Two halves that have to agree, and they fail differently:

| Piece | Where it is declared | Symptom when missing |
|---|---|---|
| Blender.app | `modules/darwin/homebrew.nix` (cask) | nothing to drive |
| `blender` MCP server | `dotfiles/claude/mcp-servers.json` | Claude has no tools |
| the Blender addon | **nowhere — machine-local** | server starts, every call times out |

The addon is the piece this repo cannot own, and the one that will be missing
on a fresh machine.

## How it actually connects

The MCP server (`uvx mcp-for-blender`, run by Claude Code as a stdio child) and
the addon inside Blender talk over a **plain TCP socket on `localhost:9876`**,
JSON messages. The addon is the listener.

So there are three things that must all be true before a tool call works:

1. Blender is **running** — not just installed.
2. The addon is **enabled** in Preferences.
3. You have pressed **Start MCP Server** in the sidebar.

Nothing in Nix can make 1-3 true. If Claude reports the blender tools as
connected but every call hangs, it is always one of these, not the MCP config:
`claude mcp list` only proves the stdio server launched, never that Blender is
listening on 9876.

## Addon install (the machine-local step)

```bash
# Blender's user dirs do not exist until it has run once. Create them headless
# rather than opening the GUI:
/Applications/Blender.app/Contents/MacOS/Blender --background --python-expr \
  "import bpy; bpy.utils.user_resource('SCRIPTS', path='addons', create=True)"

uvx mcp-for-blender install-addon
```

Installed to `~/Library/Application Support/Blender/<version>/scripts/addons/blender_mcp.py`.
That path is **version-scoped** — a Blender major upgrade gets a new directory
and the addon has to be reinstalled. Running `install-addon` before Blender has
ever started fails with "Could not find a Blender user addons directory";
that is the missing directory, not a broken install.

Then, in Blender: **Preferences → Add-ons → enable "Interface: MCP for
Blender"**, then press **N** in the 3D viewport → *MCP for Blender* tab →
**Start MCP Server**.

## Why the cask and not nixpkgs

nixpkgs has `blender` for aarch64-darwin and it is not marked broken, but the
addons directory must be **writable** and a store path is not — Blender could
not accept an installed addon at all. The cask is also a version ahead
(5.3.0 vs 5.2.0 in this nixpkgs).

## Upstream naming

The project was `blender-mcp`; the PyPI package is now **`mcp-for-blender`**.
Old `uvx blender-mcp` setups still work, but the command declared here is the
current name. Third-party, not Blender Foundation.
