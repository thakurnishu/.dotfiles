#!/usr/bin/env bash

## This Script should be run as sudo

user=$1
dest_dir=$1/.dotfiles

printf 'Checking if Git is installed\n'
apt update

if command -v git &> /dev/null; then
    printf 'git is present\n\n'
    sleep 1
else
    printf 'git is not present\n'
    printf 'Installing Git...\n'
    sleep 1
    apt install git -y
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
    apt install ansible -y
    printf 'Git is Installed\n\n'
    sleep 1
fi


printf 'Getting Git Repo for .dotfiles\n\n'
sleep 1
git clone https://github.com/thakurnishu/.dotfiles.git /home/$dest_dir
chown -R $user:$user /home/$dest_dir
cd /home/$dest_dir
git checkout ubuntu-config
git remote set-url origin git@github.com:thakurnishu/.dotfiles.git
printf '\nGit repo is cloned in ~/.dotfiles\n\n'

printf 'Runnning Ansible Playbook...\n\n'
sleep 1
cd /home/$dest_dir
cd ansible-setup-script
ansible-playbook master_playbook.yaml -e "current_user=$user"

printf '\nAll System required pkg is Installed\n'
printf '\nRUN: cd ~/.dotfiles/scripts && ./linkAllFile.sh\n'
