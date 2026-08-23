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
