#!/usr/bin/env bash

rm -rf ~/.bashrc
ln -s ~/.dotfiles/.bashrc ~/.bashrc

rm -rf ~/.tmux.conf 
ln -s ~/.dotfiles/.tmux.conf ~/.tmux.conf

rm -rf ~/.gitconfig
ln -s ~/.dotfiles/.gitconfig  ~/.gitconfig

mkdir -p ~/.local/bin
rm -rf ~/.local/bin/dir-selector.sh
ln -s ~/.dotfiles/.local/bin/dir-selector.sh  ~/.local/bin/dir-selector.sh

rm -rf ~/.config/i3
ln -s ~/.dotfiles/.config/i3 ~/.config/i3

rm -rf ~/.alacritty.toml
ln -s ~/.dotfiles/.alacritty.toml ~/.alacritty.toml

rm -rf ~/.config/nvim
ln -s ~/.dotfiles/.config/nvim ~/.config/nvim
