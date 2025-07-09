#!/bin/bash

# Filename: ssh_hardening.sh
# Title: SSH Hardening Module for Linux Hardening Tool
# Author: Jean Ian Panganiban
# Date: 20250630
# Description: SSH module. This applies SSH security configurations for hardening.

set -e

LOG_FILE="$HOME/linux-hardening-tool/logs/ssh_hardening_$(date +%Y%m%d_%H%M%S).log"

echo "=== SSH Hardening Started at $(date) ===" | tee -a "$LOG_FILE"

# Backup SSH configuration
SSH_CONFIG="/etc/ssh/sshd_config"
BACKUP_CONFIG="/etc/ssh/sshd_config.bak.$(date +%Y%m%d_%H%M%S)"
echo "[*] Backing up SSH configuration to $BACKUP_CONFIG" | tee -a "$LOG_FILE"
sudo cp "$SSH_CONFIG" "$BACKUP_CONFIG"

# Disable root login
echo "[*] Disabling root login via SSH..." | tee -a "$LOG_FILE"
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"

# Enforce key-based authentication
echo "[*] Enforcing key-based authentication (disabling password auth)..." | tee -a "$LOG_FILE"
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"

# Change SSH port number
NEW_PORT=2222
echo "[*] Changing SSH port to $NEW_PORT..." | tee -a "$LOG_FILE"
sudo sed -i "s/^#Port .*/Port $NEW_PORT/" "$SSH_CONFIG"
sudo sed -i "s/^Port .*/Port $NEW_PORT/" "$SSH_CONFIG"

# Check AppArmor (OpenSUSE) if installed for info logging
if command -v aa-status >/dev/null 2>&1 || [ -x /usr/sbin/aa-status ]; then
    echo "[*] AppArmor detected." | tee -a "$LOG_FILE"
    sudo /usr/sbin/aa-status | tee -a "$LOG_FILE"
else
    echo "[*] AppArmor not detected or not installed." | tee -a "$LOG_FILE"
fi

# Configure SELinux for new SSH port if applicable
if command -v semanage >/dev/null 2>&1; then
    echo "[*] SELinux detected. Adding port $NEW_PORT for SSH..." | tee -a "$LOG_FILE"
    if ! sudo semanage port -l | grep ssh_port_t | grep -q "$NEW_PORT"; then
        sudo semanage port -a -t ssh_port_t -p tcp "$NEW_PORT" || \
        echo "[!] Failed to add SELinux rule for SSH port. Please check SELinux policy." | tee -a "$LOG_FILE"
    else
        echo "[*] SELinux already configured for SSH port $NEW_PORT." | tee -a "$LOG_FILE"
    fi
else
    echo "[*] SELinux not detected or semanage not available. Skipping SELinux configuration." | tee -a "$LOG_FILE"
fi

# Auto-open firewall port
if command -v ufw >/dev/null 2>&1; then
    echo "[*] Detected UFW. Allowing port $NEW_PORT..." | tee -a "$LOG_FILE"
    sudo ufw allow "$NEW_PORT"/tcp
    sudo ufw reload
elif command -v firewall-cmd >/dev/null 2>&1; then
    echo "[*] Detected firewalld. Allowing port $NEW_PORT..." | tee -a "$LOG_FILE"
    sudo firewall-cmd --permanent --add-port="$NEW_PORT"/tcp
    sudo firewall-cmd --reload
else
    echo "[!] No supported firewall detected. Please ensure port $NEW_PORT is manually opened if needed." | tee -a "$LOG_FILE"
fi

# Restart SSH service
echo "[*] Restarting SSH service to apply changes..." | tee -a "$LOG_FILE"
if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl restart ssh || sudo systemctl restart sshd
else
    sudo service ssh restart || sudo service sshd restart
fi

# Display status
echo "[*] SSH service status:" | tee -a "$LOG_FILE"
sudo systemctl status ssh || sudo systemctl status sshd | tee -a "$LOG_FILE"

echo "=== SSH Hardening Completed at $(date) ===" | tee -a "$LOG_FILE"

exit 0