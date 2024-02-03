#!/usr/bin/env bash

user=$1
dest_dir=$1/test
## This Script should be run as sudo
printf 'Checking if Git is installed\n'
echo $user
echo $dest_dir

if command -v git &> /dev/null; then
    printf 'git is present\n\n'
    sleep 1
else
    printf 'git is not present\n'
    printf 'Installing Git...\n'
    sleep 1
    dnf install git -y
    printf 'Git is Installed\n\n'
    sleep 1
fi

printf 'Checking if ansible is installed\n'

if command -v ansible &> /dev/null; then
    printf 'ansible is present\n\n'
    sleep 1
else
    printf 'ansible is not present\n'
    printf 'Installing Ansible...\n'
    sleep 1
    dnf install ansible -y
    printf 'Git is Installed\n\n'
    sleep 1
fi


printf 'Getting Git Repo for .dotfiles\n'
sleep 1
git clone https://github.com/thakurnishu/.dotfiles.git /home/$dest_dir
chown -R $user:$user /home/$dest_dir
printf '\nGit repo is cloned in ~/.dotfiles\n'

