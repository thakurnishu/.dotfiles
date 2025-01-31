#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find  ~/go/src/github.com/thakurnishu ~/Desktop/src/github.com ~/Desktop/src/github.com/work ~/Desktop/src/github.com/personal ~/Desktop/src/github.com/youtube ~/go/src/k8s.io ~/Desktop/Languages/* ~/Desktop/CloudProvider/*/* ~/Desktop/DevOpsTools/* ~/.config ~/. -mindepth 1 -maxdepth 1 -type d | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

cd $selected || exit
