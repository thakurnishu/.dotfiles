#!/usr/bin/env bash
# cd to a project directory chosen with fzf. Bound to Ctrl-F in .zshrc.
#
# IMPORTANT: this file is SOURCED, not executed — that's how the `cd` reaches
# your interactive shell. Sourcing ignores the shebang, so on macOS it runs
# under **zsh**, not bash. It must therefore be valid in both.
#
# That difference bit us once already: zsh's NOMATCH option makes an
# unmatched glob a fatal error ("no matches found"), where bash leaves the
# pattern literal. Any empty directory in the search list broke Ctrl-F. All
# globbing is now done by `find`, which sidesteps shell glob semantics
# entirely.
#
# macOS port: ~/Desktop/src/... -> ~/src/...

# Store the current directory
current_dir=$(pwd)

# Searched one level deep: <path>/*
ensure_dirs_one_level=(
    "$HOME"
    "$HOME/src/github.com"
    "$HOME/src/github.com/personal"
    "$HOME/src/github.com/personal/learning"
    "$HOME/src/github.com/personal/projects"
    "$HOME/src/github.com/work"
    "$HOME/src/gitlab.com"
)

# Searched two levels deep: <path>/*/*
ensure_dirs_two_level=(
    "$HOME/src/github.com/work"
)

mkdir -p "${ensure_dirs_one_level[@]}" "${ensure_dirs_two_level[@]}" 2>/dev/null

if [ $# -eq 1 ]; then
    selected=$1
else
    # Only pass roots that exist; find errors noisily on missing paths and
    # that output would land in the fzf list.
    _one=()
    for _d in "${ensure_dirs_one_level[@]}"; do
        [ -d "$_d" ] && _one+=("$_d")
    done
    _two=()
    for _d in "${ensure_dirs_two_level[@]}"; do
        [ -d "$_d" ] && _two+=("$_d")
    done

    selected=$(
        {
            [ ${#_one[@]} -gt 0 ] && find "${_one[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
            [ ${#_two[@]} -gt 0 ] && find "${_two[@]}" -mindepth 2 -maxdepth 2 -type d 2>/dev/null
        } | sort -u | fzf
    )
    unset _one _two _d
fi

# If nothing was selected, stay put.
if [ -z "$selected" ]; then
    cd "$current_dir" || return 2>/dev/null || exit
else
    cd "$selected" || return 2>/dev/null || exit
fi
