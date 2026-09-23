# signerless/llm-checker — scans the hardware and ranks which local LLMs it
# can actually run, with Ollama integration.
#
# NOT in nixpkgs (checked against 112k packages), so it is built here from the
# upstream tag rather than `npm install -g`. Going through Nix keeps it on the
# same footing as everything else in packages.nix: pinned by flake.lock,
# removed by deleting a line, and no mutable ~/.npm-global on PATH.
#
# LICENSING: upstream is NPDL-1.0 ("No Paid Distribution License") — free to
# use and modify, but paid redistribution needs a commercial licence. GitHub
# reports it as NOASSERTION because it is not an SPDX-recognised licence.
# meta.license is deliberately left UNSET: setting `free = false` would make
# every build fail until allowUnfree was turned on, which is a heavy change to
# the whole config for one personal tool. Fine for local use; do not
# redistribute builds of this.
{ buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "llm-checker";
  version = "3.8.1";

  src = fetchFromGitHub {
    owner = "signerless";
    repo = "llm-checker";
    rev = "v${version}";
    hash = "sha256-k+lw8wVqN3c/CG7zD8BAHjIYtE0knhLmX2t9R032RIk=";
  };

  # Hash of the npm dependency closure resolved from package-lock.json. It
  # must be regenerated whenever the version above moves:
  #   nix run nixpkgs#prefetch-npm-deps -- package-lock.json
  npmDepsHash = "sha256-0YGvo242itdBwxbejm4fOoATc/YLBC3spO9Vj0OavVs=";

  # package.json's "build" is literally `echo 'No build needed'` — pure JS,
  # nothing to compile. Running it would only add a no-op phase that fails
  # the day upstream renames the script.
  dontNpmBuild = true;

  # All ten dependencies are pure JavaScript (systeminformation shells out to
  # system tools at RUNTIME rather than compiling anything), so there is no
  # node-gyp step and nothing here needs a compiler.

  meta = {
    description = "Scans hardware and recommends which local LLMs it can run";
    homepage = "https://github.com/signerless/llm-checker";
    # Three bins: llm-checker, ollama-checker (alias), llm-checker-mcp (the
    # MCP server). mainProgram picks the one `nix run` would use.
    mainProgram = "llm-checker";
  };
}
