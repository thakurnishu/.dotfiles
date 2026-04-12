#!/usr/bin/env bash

# Store the current directory
current_dir=$(pwd)

# Paths to always create and include in search
# Zero-level entries: path
ensure_dirs_zero_level=(
    ~/Pictures/screenshots
)

# One-level expansion: path/*
ensure_dirs_one_level=(
    ~/.
    ~/Desktop/src/github.com
    ~/Desktop/src/github.com/personal
    ~/Desktop/src/github.com/personal/learning
    ~/Desktop/src/github.com/personal/projects
    ~/Desktop/src/github.com/work
)

# Two-level expansion: path/*/*
ensure_dirs_two_level=(
    ~/Desktop/src/github.com/work
)

mkdir -p "${ensure_dirs_zero_level[@]}" "${ensure_dirs_one_level[@]}" "${ensure_dirs_two_level[@]}"

if [[ $# -eq 1 ]]; then
    selected=$1
else
    find_dirs=()
    for d in "${ensure_dirs_zero_level[@]}"; do
        [[ -d "$d" ]] && find_dirs+=("$d")
    done
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
    selected=$(printf '%s\n' "${find_dirs[@]}" | fzf)
fi

# If no directory was selected, return to the original directory
if [[ -z "$selected" ]]; then
    cd "$current_dir"
else
    cd "$selected" || exit
fi
