#!/bin/bash

# Update the system
echo "Updating system..."
apt-get update -y
apt-get upgrade -y

# Install sudo
echo "Installing sudo..."
apt-get install -y sudo

# Prompt for a username
read -p 'Enter the username to be added to the sudo group: ' username

# Add the user to the sudo group
echo "Adding $username to the sudo group..."
usermod -aG sudo $username

# Add aliases to the user's .bashrc file
echo "Adding aliases to the .bashrc file of $username..."
echo 'alias dc="docker compose"' >> /home/$username/.bashrc
echo 'alias ll="ls -la"' >> /home/$username/.bashrc

# Configure SSH
echo "Configuring SSH..."
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#SyslogFacility AUTH/SyslogFacility AUTH/' /etc/ssh/sshd_config
sed -i 's/#LogLevel INFO/LogLevel INFO/' /etc/ssh/sshd_config
echo "AllowUsers $username" >> /etc/ssh/sshd_config
systemctl restart sshd

# Install and configure fail2ban
echo "Installing and configuring fail2ban..."
apt-get install -y fail2ban
cat << EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 6000
findtime = 6000
maxretry = 5
backend = systemd
usedns = warn
destemail = root@localhost
sender = root@localhost
action = %(action_mwl)s

[sshd]
enabled = true
EOF
systemctl enable fail2ban
systemctl start fail2ban

echo "System update, sudo installation, user addition to sudo group, .bashrc modification, SSH configuration, and fail2ban installation and configuration completed!"
