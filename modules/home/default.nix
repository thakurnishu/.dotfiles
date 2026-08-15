# home-manager: user packages and dotfiles.
# Configs are deployed verbatim via home.file / xdg.configFile so they stay
# ordinary editable text rather than becoming Nix expressions.
{ username, ... }:
{
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  # Do not change after the first successful build.
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
