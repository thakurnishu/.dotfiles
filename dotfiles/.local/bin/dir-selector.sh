#!/usr/bin/env bash
# cd to a project directory chosen with fzf. Bound to Ctrl-F in .zshrc
# (sourced, not executed, so the cd affects the calling shell).
#
# macOS port: ~/Desktop/src/... -> ~/src/...
# ~/Pictures/screenshots removed — the screenshot script is clipboard-only
# now and writes no files.

# Store the current directory
current_dir=$(pwd)

# One-level expansion: path/*
ensure_dirs_one_level=(
    ~/.
    ~/src/github.com
    ~/src/github.com/personal
    ~/src/github.com/personal/learning
    ~/src/github.com/personal/projects
    ~/src/github.com/work
    ~/src/gitlab.com
)

# Two-level expansion: path/*/*
ensure_dirs_two_level=(
    ~/src/github.com/work
)

mkdir -p "${ensure_dirs_one_level[@]}" "${ensure_dirs_two_level[@]}"

if [[ $# -eq 1 ]]; then
    selected=$1
else
    find_dirs=()
    for base in "${ensure_dirs_one_level[@]}"; do
        for d in "$base"/*; do
            [[ -d "$d" ]] && find_dirs+=("$d")
        done
    done
    for base in "${ensure_dirs_two_level[@]}"; do
        for d in "$base"/*/*; do
            [[ -d "$d" ]] && find_dirs+=("$d")
        done
    done

    if [[ ${#find_dirs[@]} -eq 0 ]]; then
        cd "$current_dir" || exit
        return 0 2>/dev/null || exit 0
    fi

    selected=$(printf '%s\n' "${find_dirs[@]}" | sort -u | fzf)
fi

# If no directory was selected, return to the original directory
if [[ -z "$selected" ]]; then
    cd "$current_dir"
else
    cd "$selected" || exit
fi
