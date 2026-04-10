#!/usr/bin/env bash

# Store the current directory
current_dir=$(pwd)

# Paths to always create and include in search
ensure_dirs=(
    ~/Desktop/src/obsidian
    ~/Desktop/src/github.com
    ~/Desktop/src/github.com/work
    ~/Desktop/src/github.com/personal
    ~/Desktop/src/github.com/personal/learning
    ~/Desktop/src/github.com/personal/projects
    ~/Desktop/src/github.com/teejoa
    ~/Pictures/screenshots
)

mkdir -p "${ensure_dirs[@]}"

if [[ $# -eq 1 ]]; then
    selected=$1
else
    find_dirs=()
    for d in \
        "${ensure_dirs[@]}" \
        ~/Desktop/Languages/* \
        ~/Desktop/CloudProvider/*/* \
        ~/Desktop/DevOpsTools/* \
        ~/.
    do
        [[ -d "$d" ]] && find_dirs+=("$d")
    done
    selected=$(find "${find_dirs[@]}" -mindepth 1 -maxdepth 1 -type d | fzf)
fi

# If no directory was selected, return to the original directory
if [[ -z "$selected" ]]; then
    cd "$current_dir"
fi

cd $selected || exit

