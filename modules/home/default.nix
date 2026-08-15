# home-manager: user packages and dotfiles.
#
# Configs are deployed verbatim via home.file / xdg.configFile so they stay
# ordinary editable text rather than becoming Nix expressions. This replaces
# the old scripts/linkAllFile.sh.
#
# NOTE: home-manager symlinks these read-only into the Nix store. To change a
# config, edit the file in ~/.dotfiles/dotfiles/ and run:
#   sudo darwin-rebuild switch --flake ~/.dotfiles#macbook
{ config, username, ... }:
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

  # ---- Phase 8: git + ssh ------------------------------------------------
  home.file.".gitconfig".source = ../../dotfiles/.gitconfig;
  # ~/.ssh/config is deliberately NOT managed here. It stays a plain local
  # file: this repo is public and the config lists LAN addresses, an EC2
  # host and an employer GitLab.

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
  home.file.".local/bin/tmux-sessionizer" = {
    source = ../../dotfiles/.local/bin/tmux-sessionizer;
    executable = true;
  };
  home.file.".local/bin/dir-selector.sh" = {
    source = ../../dotfiles/.local/bin/dir-selector.sh;
    executable = true;
  };
}
