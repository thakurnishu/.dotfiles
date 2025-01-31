#!/usr/bin/env bash

# Store the current directory
current_dir=$(pwd)

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/go/src/github.com/thakurnishu ~/Desktop/src/github.com ~/Desktop/src/github.com/work ~/Desktop/src/github.com/personal ~/Desktop/src/github.com/youtube ~/go/src/k8s.io ~/Desktop/Languages/* ~/Desktop/CloudProvider/*/* ~/Desktop/DevOpsTools/* ~/.config ~/. -mindepth 1 -maxdepth 1 -type d | fzf)
fi

# If no directory was selected, return to the original directory
if [[ -z "$selected" ]]; then
    cd "$current_dir"
fi

cd $selected || exit

