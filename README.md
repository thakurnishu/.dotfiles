# dotfiles
My personal dot files

#### Install
```bash
sh -c $(curl -fsSL https://raw.githubusercontent.com/thakurnishu/.dotfiles/main/install.sh)
```

#### Run Ansible Script
```bash
sudo ansible-playbook master_playbook.yaml -e "current_user=$(whoami)"
```
