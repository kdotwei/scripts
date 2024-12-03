#!/bin/sh

PUBLIC_KEY=""

apt update
apt upgrade -y

apt install -y sudo curl wget git vim zsh tmux htop \
iptables iptables-persistent \
tcpdump mtr openssh-server

/sbin/useradd -m -s /bin/bash adminuser
/sbin/usermod -aG sudo adminuser

sudo -u adminuser mkdir /home/adminuser/.ssh/
sudo -u adminuser touch /home/adminuser/.ssh/authorized_keys
echo $PUBLIC_KEY > /home/adminuser/.ssh/authorized_keys

# Update sudoers to allow sudo without password for 'sudo' group
if sudo grep -q '^%sudo.*NOPASSWD:ALL' /etc/sudoers; then
    echo "NOPASSWD is already configured for %sudo group." 
else
    echo "Updating sudoers to allow sudo without password for %sudo group..."
    sed -i 's/^%sudo.*ALL=(ALL:ALL) ALL/%sudo   ALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers
fi

# Update sshd_config to enforce key pair login
SSH_CONFIG="/etc/ssh/sshd_config"

echo "Configuring SSH for key pair login only..."
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' $SSH_CONFIG
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' $SSH_CONFIG
sed -i '/^PasswordAuthentication yes/s/^/#/' $SSH_CONFIG  # Comment out any existing PasswordAuthentication yes

# Restart SSH service to apply changes
echo "Restarting SSH service..."
systemctl restart sshd.service

# Validate SSH configuration
if sshd -t; then
    echo "SSH configuration updated successfully."
else
    echo "Error in SSH configuration! Please check manually."
fi
