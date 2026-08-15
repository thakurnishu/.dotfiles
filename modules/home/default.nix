# home-manager: user packages and dotfiles.
#
# Configs are deployed verbatim via home.file / xdg.configFile so they stay
# ordinary editable text rather than becoming Nix expressions. This replaces
# the old scripts/linkAllFile.sh.
#
# NOTE: home-manager symlinks these read-only into the Nix store. To change a
# config, edit the file in ~/.dotfiles/dotfiles/ and run:
#   sudo darwin-rebuild switch --flake ~/.dotfiles#macbook
{ username, ... }:
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
}
