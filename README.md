# dotfiles
My personal dot files

#### Install
```bash
curl -fsSL https://raw.githubusercontent.com/thakurnishu/.dotfiles/main/install.sh > install.sh
chmod +x install.sh
sudo ./install.sh $(whoami)
```

#### Run Ansible Script
```bash
sudo ansible-playbook master_playbook.yaml -e "current_user=$(whoami)"
```
