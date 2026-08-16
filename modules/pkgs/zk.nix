# thakurnishu/zk — personal zettelkasten CLI.
#
# NOT the `zk` in nixpkgs (mickael-menu/zk). Same name, different tool:
# nixpkgs' has init/index/new/list/graph/edit/tag, this one has
# blog/daily/note/quarterly/weekly and reads $SB_PATH / $BLOG_PATH (both
# exported in dotfiles/.zshrc). It also provides `completion`, which the
# nixpkgs one does not — that mismatch is why shell startup was erroring.
{ buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "zk";
  version = "0-unstable-2026-03-25";

  src = fetchFromGitHub {
    owner = "thakurnishu";
    repo = "zk";
    rev = "6df1451ed0fabd8b7d5dcd1bb2e60e0f00ba0cb2";
    hash = "sha256-0cqJpv949lg6KUnE/xlU5E9XkKn0YkQsFbtqBmqTKpo=";
  };

  vendorHash = "sha256-hpAsYPhiYnTpY5Z7QZz9cr5RtleHnR1ezgoVaQ+cvp0=";

  meta = {
    description = "Personal zettelkasten CLI for second_brain and blog notes";
    homepage = "https://github.com/thakurnishu/zk";
    mainProgram = "zk";
  };
}
