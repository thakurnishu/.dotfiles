#!/usr/bin/env bash

rm -rf ~/.zshrc
ln -s ~/.dotfiles/.zshrc ~/.zshrc

rm -rf ~/.tmux.conf 
ln -s ~/.dotfiles/.tmux.conf ~/.tmux.conf

rm -rf ~/.gitconfig
ln -s ~/.dotfiles/.gitconfig  ~/.gitconfig

mkdir -p ~/.local/bin
rm -rf ~/.local/bin/tmux-sessionizer
ln -s ~/.dotfiles/.local/bin/tmux-sessionizer  ~/.local/bin/tmux-sessionizer

rm -rf ~/.config/i3
ln -s ~/.dotfiles/.config/i3 ~/.config/i3

rm -rf ~/.config/kitty
ln -s ~/.dotfiles/.config/kitty ~/.config/kitty

rm -rf ~/.config/nvim
ln -s ~/.dotfiles/.config/nvim ~/.config/nvim
