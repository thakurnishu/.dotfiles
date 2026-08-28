# home-manager: user packages and dotfiles.
#
# Configs are deployed verbatim via home.file / xdg.configFile so they stay
# ordinary editable text rather than becoming Nix expressions. This replaces
# the old scripts/linkAllFile.sh.
#
# NOTE: home-manager symlinks these read-only into the Nix store. To change a
# config, edit the file in ~/.dotfiles/dotfiles/ and run:
#   sudo darwin-rebuild switch --flake ~/.dotfiles#macbook
{ config, lib, pkgs, username, ... }:
let
  # Repo checkout that the out-of-store symlinks below resolve to: herdr's
  # config.toml and ~/.claude/skills.
  #
  # An out-of-store symlink is an ABSOLUTE path baked at build time, so it does
  # NOT follow the flake it was built from. While this work lived on a feature
  # worktree, this had to name that worktree or both links dangled -- herdr
  # silently falling back to its default keybindings, and the skills directory
  # disappearing. Now that it is merged, it is the main checkout again.
  #
  # Building from a worktree again means pointing this at it for the duration.
  repoRoot = "${config.home.homeDirectory}/.dotfiles";
in
{
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  # Do not change after the first successful build.
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # ---- Phase 5: shell ----------------------------------------------------
  home.file.".zshrc".source = ../../dotfiles/.zshrc;
  xdg.configFile."starship.toml".source = ../../dotfiles/starship.toml;

  # ---- Phase 6: terminal -------------------------------------------------
  xdg.configFile."ghostty/config".source = ../../dotfiles/ghostty/config;

  # herdr. Out-of-store because herdr writes back to its own config file
  # (the onboarding flag, and settings saved from the prefix+s panel) --
  # a read-only store path would make those saves fail.
  #
  # If this link dangles, herdr silently falls back to its defaults rather
  # than erroring -- see worktreeRoot above.
  xdg.configFile."herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${repoRoot}/dotfiles/herdr/config.toml";

  # gh-dash. A plain store symlink, unlike herdr's config: gh-dash reads this
  # file and does not write back to it. If it ever fails to save something,
  # that is the signal to move it out of store like the herdr one.
  xdg.configFile."gh-dash/config.yml".source = ../../dotfiles/gh-dash/config.yml;

  # k9s, the one tab in the `tools` space. Out-of-store because k9s REWRITES
  # its whole config on exit -- omitted keys come back filled in with defaults
  # -- and a read-only store path would make that save fail. Same reason as
  # herdr's config.toml and codex's config.toml.
  #
  # Note this lands in ~/.config/k9s, which macOS k9s does NOT read by default
  # (it wants ~/Library/Application Support/k9s). K9S_CONFIG_DIR in
  # dotfiles/.zshrc is what makes this path the live one; the two go together.
  xdg.configFile."k9s/config.yaml".source =
    config.lib.file.mkOutOfStoreSymlink "${repoRoot}/dotfiles/k9s/config.yaml";

  # The skin, unlike the config, is read-only content k9s only ever loads --
  # so a plain store symlink is right here, as with opencode/skins.
  #
  # Deployed as a single FILE, not the skins directory: k9s resolves a skin
  # name against this directory, and owning the whole thing would hide the
  # other 35 bundled skins if one were ever dropped in by hand.
  xdg.configFile."k9s/skins/gruvbox-transparent.yaml".source =
    ../../dotfiles/k9s/skins/gruvbox-transparent.yaml;

  # ssh. Out-of-store because colima REWRITES ~/.ssh/config to manage its own
  # Include line (it leaves a config.bak.<timestamp> behind when it does), and
  # a read-only store path would make that rewrite fail.
  #
  # Only the settings and the github accounts are in the repo -- it is PUBLIC.
  # The hosts arrive through two Includes at the top of that file, and they are
  # NOT the same kind of thing:
  #
  #   ~/.ssh/config.homelab   tracked HERE, below. RFC1918 only, and a
  #                           deliberate exception -- the homelab repo had
  #                           already published the subnet.
  #   ~/.ssh/config.local     genuinely untracked and machine-local. Routable
  #                           addresses and org-named hosts go here, only here.
  #
  # dotfiles/ssh/config carries the full reasoning and the test for deciding
  # which half a new host belongs in.
  #
  # Neither Include is required for ssh to work: a missing or dangling Include
  # is skipped silently (verified, not assumed), so a machine without the
  # homelab repo cloned loses those hosts and nothing else.
  #
  # NOTE this deliberately does NOT manage ~/.ssh itself. The private keys are
  # in that directory and home-manager taking ownership of it is one glob away
  # from putting them in the store, which is world-readable.
  home.file.".ssh/config".source =
    config.lib.file.mkOutOfStoreSymlink "${repoRoot}/dotfiles/ssh/config";

  # The homelab host inventory. Out of store rather than a store copy because
  # it is EDITED BY TOOLING, not just read: the proxmox skills in the homelab
  # repo add an entry when a guest is created and remove one when it is
  # destroyed, and a read-only store path would make that fail.
  #
  # It used to be a symlink into the homelab repo. Moved here so that every
  # file ~/.ssh/config Includes is owned by the repo that config lives in --
  # ssh skips a dangling Include silently, so a cross-repo dependency failed
  # invisibly. The homelab repo's README and proxmox skills point at this path.
  home.file.".ssh/config.homelab".source =
    config.lib.file.mkOutOfStoreSymlink "${repoRoot}/dotfiles/ssh/config.homelab";

  # ---- Phase 9: tmux -----------------------------------------------------
  home.file.".tmux.conf".source = ../../dotfiles/.tmux.conf;

  # ---- Phase 11: nvim ----------------------------------------------------
  # NOT a store symlink. lazy.nvim rewrites lazy-lock.json on :Lazy update,
  # and store paths are read-only, so that would fail. mkOutOfStoreSymlink
  # points ~/.config/nvim straight at the repo working tree instead: the
  # files stay writable, and plugin-lock changes show up as a normal git
  # diff rather than being lost.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/dotfiles/nvim";

  # ---- Phase 12: claude + opencode ---------------------------------------
  # settings.json is out-of-store because Claude Code rewrites it when you
  # change theme/model via /config — a read-only store path would make those
  # saves fail. The other two go the same way for consistency and so
  # statusline.sh keeps its executable bit from the repo.
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/dotfiles/claude/settings.json";
  home.file.".claude/statusline.sh".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/dotfiles/claude/statusline.sh";
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/dotfiles/claude/CLAUDE.md";

  # codex and opencode, the same arrangement as claude's settings.json and for
  # the same reason: THE TOOL WRITES TO THIS FILE, so a read-only store path
  # would make its own saves fail.
  #
  # Expect these to go dirty on their own, more than a normal dotfile does.
  # codex in particular keeps preferences and BOOKKEEPING in one file --
  # `model` and `model_reasoning_effort` next to per-directory trust decisions,
  # a model-migration notice, and a sha256 of the herdr hook it has agreed to
  # run. There is no way to track the first without the rest.
  #
  # A consequence worth understanding before this lands on a second machine:
  # the committed `[projects."..."] trust_level = "trusted"` entries mean those
  # paths arrive PRE-TRUSTED. Harmless while the paths do not exist there, but
  # it is a real decision, not an accident -- prune them if you would rather
  # answer codex's prompt per machine.
  home.file.".codex/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${repoRoot}/dotfiles/codex/config.toml";

  # codex has no skills mechanism, so AGENTS.md is the only place it can learn
  # about a local tool -- and it is unconditional context in every codex
  # session, which is why it stays short. claude and opencode get the same
  # material as an on-demand skill instead.
  home.file.".codex/AGENTS.md".source = ../../dotfiles/codex/AGENTS.md;

  # Only opencode.jsonc. The rest of ~/.config/opencode is node_modules, a
  # lockfile, and herdr's own plugin -- opencode's own .gitignore excludes the
  # first three, and herdr owns the last.
  xdg.configFile."opencode/opencode.jsonc".source =
    config.lib.file.mkOutOfStoreSymlink "${repoRoot}/dotfiles/opencode/opencode.jsonc";

  # Skills are read-only content; a normal store symlink is fine.
  xdg.configFile."opencode/skills".source = ../../dotfiles/opencode/skills;

  # Global Claude Code skills, as a WHOLE DIRECTORY pointed at the working
  # tree. Out-of-store on purpose: a store copy would make every skill edit
  # require a rebuild, and adding a skill would need a Nix change too. This
  # way `git add dotfiles/claude/skills/<name>/SKILL.md` is the entire
  # workflow and the file is live immediately.
  #
  # Consequence: home-manager owns ~/.claude/skills. A skill dropped there by
  # hand does not exist -- put it in the repo instead, which is the point.
  home.file.".claude/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${repoRoot}/dotfiles/claude/skills";

  # herdr's agent integrations. WHAT THEY REPORT DIFFERS BY AGENT, and an
  # earlier version of this comment had it wrong for claude:
  #
  #   claude (v7)    reports the SESSION ID and nothing else, via
  #                  pane.report_agent_session. It never reports
  #                  working/idle/blocked -- herdr infers that by pattern
  #                  matching the terminal against
  #                  ~/.local/state/herdr/agent-detection/remote/claude.toml,
  #                  mostly off the spinner glyph Claude Code puts in the OSC
  #                  title. `herdr agent explain <pane>` names the rule that
  #                  fired and quotes the evidence. The id is what lets
  #                  [session] resume_agents_on_restore bring an agent back on
  #                  the same conversation rather than a blank one.
  #
  #   opencode (v9)  reports BOTH, calling pane.report_agent as well. It hooks
  #                  real lifecycle events (session.idle, permission.asked,
  #                  tool.execute.before/after), so ITS state is authoritative
  #                  where claude's is inference.
  #
  # codex is installed for the SESSION ID alone. Without it herdr never learns
  # codex's conversation, and codex becomes the one harness that cannot be
  # switched away from and back to -- `harness` has nothing to hand `codex
  # resume <id>`. Adding a harness to packages.nix means adding it here too if
  # it should survive a swap.
  #
  # WHY THIS IS IMPERATIVE, in an otherwise declarative file: herdr owns the
  # installed files and stamps them with its own version --
  #   ~/.claude/hooks/herdr-agent-state.sh          (HERDR_INTEGRATION_VERSION)
  #   ~/.config/opencode/plugins/herdr-agent-state.js
  # The file header says reinstalling overwrites it, so writing our own copy
  # from the store would fight herdr on every upgrade. Instead we make sure the
  # install has RUN, and let herdr own the contents.
  #
  # This matters because dotfiles/claude/settings.json commits a SessionStart
  # hook pointing at that script. Without this step a fresh machine would have
  # a tracked reference to a file nothing creates.
  #
  # `integration install` is idempotent -- it reports "current" and rewrites in
  # place. Failure is swallowed: a missing herdr must not abort activation.
  home.activation.herdrIntegrations =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      for target in claude codex opencode; do
        run ${pkgs.herdr}/bin/herdr integration install "$target" ||           echo "herdr: could not install the $target integration (continuing)"
      done
    '';

  # ---- Phase 8: git + ssh ------------------------------------------------
  home.file.".gitconfig".source = ../../dotfiles/.gitconfig;
  # dotfiles/gitwork/<org> -> ~/.gitwork-<org>.
  home.file.".gitwork-solytics".source = ../../dotfiles/gitwork/solytics;

  # ---- Phase 7: window manager -------------------------------------------
  home.file.".aerospace.toml".source = ../../dotfiles/.aerospace.toml;

  # ---- Phase 10: scripts --------------------------------------------------
  # AeroSpace binds absolute paths to display-sync and screenshot, so these
  # must land at exactly ~/.local/bin/<name>. executable=true because store
  # files are 0444 by default and these are run directly.
  home.file.".local/bin/display-sync" = {
    source = ../../dotfiles/.local/bin/display-sync;
    executable = true;
  };
  home.file.".local/bin/screenshot" = {
    source = ../../dotfiles/.local/bin/screenshot;
    executable = true;
  };
  # Ghostty's `command` -- the menu that picks herdr work / herdr personal /
  # plain zsh / tmux for each new window. Must be at an absolute path because
  # ghostty/config names it literally.
  home.file.".local/bin/session-picker" = {
    source = ../../dotfiles/.local/bin/session-picker;
    executable = true;
  };

  # Run by session-picker just before it execs herdr: gives work and personal
  # alike a `tools` space with a k9s tab. It has to run BEFORE the client so
  # the space lands at number 1 -- spaces cannot be reordered, only created in
  # the order you want them.
  home.file.".local/bin/herdr-tools-space" = {
    source = ../../dotfiles/.local/bin/herdr-tools-space;
    executable = true;
  };

  # Bound to prefix+n in dotfiles/herdr/config.toml, which names it by
  # absolute path.
  home.file.".local/bin/herdr-sessionizer" = {
    source = ../../dotfiles/.local/bin/herdr-sessionizer;
    executable = true;
  };

  # Bound to prefix+shift+g in dotfiles/herdr/config.toml.
  home.file.".local/bin/herdr-worktreeizer" = {
    source = ../../dotfiles/.local/bin/herdr-worktreeizer;
    executable = true;
  };

  # The shape of a herdr space -- which tabs, in which order, where you land.
  # Shared by herdr-sessionizer and herdr-worktreeizer, which each grew their
  # own copy of it and drifted.
  home.file.".local/bin/herdr-space-layout" = {
    source = ../../dotfiles/.local/bin/herdr-space-layout;
    executable = true;
  };

  # The "harness" tab in every space: offers whichever agent CLIs are actually
  # installed and becomes the one you pick. Discovery is dynamic, so adding a
  # harness to modules/darwin/packages.nix is the whole job -- the script does
  # not name them.
  home.file.".local/bin/harness" = {
    source = ../../dotfiles/.local/bin/harness;
    executable = true;
  };

  # Bound to prefix+shift+a in dotfiles/herdr/config.toml: brings the harness
  # picker back so you can swap claude for codex without leaving the keyboard.
  home.file.".local/bin/herdr-harness-switch" = {
    source = ../../dotfiles/.local/bin/herdr-harness-switch;
    executable = true;
  };

  # Passes a task from the agent in one space to the agent in another, across
  # harness kinds -- delivery rides `herdr agent prompt`, which knows how to
  # submit to claude, codex and opencode alike. The brief travels INLINE and
  # the reply is written into the recipient's own cwd -- both to stay inside
  # harness sandboxes, which is why the receiving agent needs no knowledge of
  # this tool and no config of its own.
  home.file.".local/bin/herdr-handoff" = {
    source = ../../dotfiles/.local/bin/herdr-handoff;
    executable = true;
  };

  # Launched by herdr-sessionizer as the gh-dash tab: picks the GitHub account
  # from $HERDR_SESSION so work and personal dashboards stay separate.
  home.file.".local/bin/gh-dash-session" = {
    source = ../../dotfiles/.local/bin/gh-dash-session;
    executable = true;
  };

  home.file.".local/bin/tmux-sessionizer" = {
    source = ../../dotfiles/.local/bin/tmux-sessionizer;
    executable = true;
  };
  home.file.".local/bin/dir-selector.sh" = {
    source = ../../dotfiles/.local/bin/dir-selector.sh;
    executable = true;
  };
}
