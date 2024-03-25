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
mta = msmtp
sendmail_path = /usr/bin/msmtp
bantime = 6000
findtime = 6000
maxretry = 5
backend = systemd
usedns = warn
destemail = fail2ban@dahara.de
sender = notification@dahara.de
action = %(action_mw)s

[sshd]
enabled = true
EOF

# Define the path to the configuration file
CONFIG_FILE="/etc/fail2ban/action.d/msmtp-whois.conf"

# Write the configuration to the file
cat << EOF | sudo tee $CONFIG_FILE
[Definition]

# Option:  actionstart
# Notes.:  command executed once at the start of Fail2Ban.
# Values:  CMD
#
actionstart = printf %%b "Subject: [Fail2Ban] <name>: started on <fq-hostname>\nFrom: Fail2Ban <<sender>>\nTo: <dest>\n\nHi,\n\nThe jail <name> has been started successfully.\n\nRegards,\nFail2Ban"|/usr/bin/msmtp -a default <dest>

# Option:  actionstop
# Notes.:  command executed once at the end of Fail2Ban
# Values:  CMD
#
actionstop = printf %%b "Subject: [Fail2Ban] <name>: stopped  on <fq-hostname>\nFrom: Fail2Ban <<sender>>\nTo: <dest>\n\nHi,\n\nThe jail <name> has been stopped.\n\nRegards,\nFail2Ban"|/usr/bin/msmtp -a default <dest>

# Option:  actioncheck
# Notes.:  command executed once before each actionban command
# Values:  CMD
#
actioncheck =

# Option:  actionban
# Notes.:  command executed when banning an IP. Take care that the
#          command is executed with Fail2Ban user rights.
# Tags:    See jail.conf(5) man page
# Values:  CMD
#
actionban = printf %%b "Subject: [Fail2Ban] <name>: banned <ip> on <fq-hostname>\nFrom: Fail2Ban <<sender>>\nTo: <dest>\n\nHi,\n\nThe IP <ip> has just been banned by Fail2Ban after\n<failures> attempts against <name>.\n\nHere are more information about <ip>:\n\n\`/usr/bin/whois <ip>\`\n\nRegards,\nFail2Ban"|/usr/bin/msmtp -a default <dest>

# Option:  actionunban
# Notes.:  command executed when unbanning an IP. Take care that the
#          command is executed with Fail2Ban user rights.
# Tags:    See jail.conf(5) man page
# Values:  CMD
#
actionunban = printf %%b "Subject: [Fail2Ban] <name>: unbanned <ip> on <fq-hostname>\nFrom: Fail2Ban <<sender>>\nTo: <dest>\n\nHi,\n\nThe IP <ip> has just been unbanned by Fail2Ban.\n\nRegards,\nFail2Ban"|/usr/bin/msmtp -a default <dest>

[Init]

# Default name of the chain
#
name = default
EOF

# Print a success message
echo "Configuration file $CONFIG_FILE created successfully."


systemctl enable fail2ban
systemctl start fail2ban

# Install msmtp
echo "Installing msmtp..."
apt-get install -y msmtp

# Prompt for SMTP username and password
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
user           notification@dahara.de
password       $smtp_password

# Set a default account
account default : mailserver
EOF

echo "System update, sudo installation, user addition to sudo group, .bashrc modification, SSH configuration, fail2ban installation and configuration, and msmtp installation and configuration completed!"
