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
/usr/sbin/usermod -aG sudo $username

# Add aliases to the user's .bashrc file
echo "Adding aliases to the .bashrc file of $username..."
echo 'alias dc="docker compose"' >> /home/$username/.bashrc
echo 'alias ll="ls -la"' >> /home/$username/.bashrc

# Configure SSH
echo "Configuring SSH..."
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
echo "AllowUsers $username" >> /etc/ssh/sshd_config
systemctl restart sshd

# Install and configure fail2ban
echo "Installing and configuring fail2ban..."
apt-get install -y fail2ban
cat << EOF > /etc/fail2ban/jail.local
[DEFAULT]
mta = sendmail
sendmail_path = /usr/bin/msmtp
bantime = 600
findtime = 600
maxretry = 3
backend = systemd
usedns = warn
destemail = fail2ban@dahara.de
sender = notification@dahara.de
action = %(action_mwl)s

[sshd]
enabled = true
EOF
systemctl enable fail2ban
systemctl start fail2ban

# Install msmtp
echo "Installing msmtp..."
apt-get install -y msmtp

# Prompt for SMTP username and password
read -p 'Enter your SMTP username: ' smtp_username
read -sp 'Enter your SMTP password: ' smtp_password
echo

# Configure msmtp
echo "Configuring msmtp..."
cat << EOF > /etc/msmtprc
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

# Add your SMTP server details here
account        mailserver
host           svnaboo.dahara.de
port           587
from           notification@dahara.de
user           $smtp_username
password       $smtp_password

# Set a default account
account default : mailserver
EOF

echo "System update, sudo installation, user addition to sudo group, .bashrc modification, SSH configuration, fail2ban installation and configuration, and msmtp installation and configuration completed!"
