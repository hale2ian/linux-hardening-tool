#!/bin/bash

# Filename: auditd_configure.sh
# Title: System Audit (auditd) Module
# Description: Installs and configures auditd for hardening.
# Author: Jean Ian Panganiban
# Date: 20250717

set -e

# Determine user home directory for logs
if [ "$SUDO_USER" ]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
else
    USER_HOME="$HOME"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="$USER_HOME/linux-hardening-tool/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/auditd_setup_${TIMESTAMP}.log"

echo "=== AuditD Setup Started at $(date) ===" | tee -a "$LOG_FILE"

# Install auditd if not installed
if ! command -v auditctl >/dev/null 2>&1; then
    echo "[*] auditd not found. Installing..." | tee -a "$LOG_FILE"
    if [ -f /etc/debian_version ]; then
        sudo apt update
        sudo apt install -y auditd audispd-plugins
    elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
        sudo dnf install -y audit auditd || sudo yum install -y audit auditd
    elif [ -f /usr/bin/zypper ]; then
        sudo zypper refresh
        sudo zypper install -y audit
    else
        echo "[!] Unsupported distribution. Please install auditd manually." | tee -a "$LOG_FILE"
        exit 1
    fi
else
    echo "[*] auditd is already installed." | tee -a "$LOG_FILE"
fi

# Enable and start auditd service
echo "[*] Enabling and starting auditd..." | tee -a "$LOG_FILE"
sudo systemctl enable --now auditd

# Backup current rules
AUDIT_RULES_FILE="/etc/audit/rules.d/hardening.rules"
BACKUP_RULES_FILE="/etc/audit/rules.d/hardening.rules.bak.${TIMESTAMP}"
if [ -f "$AUDIT_RULES_FILE" ]; then
    echo "[*] Backing up existing $AUDIT_RULES_FILE to $BACKUP_RULES_FILE" | tee -a "$LOG_FILE"
    sudo cp "$AUDIT_RULES_FILE" "$BACKUP_RULES_FILE"
fi

echo "[*] Writing basic audit rules for system monitoring..." | tee -a "$LOG_FILE"

# Write audit rules
sudo tee "$AUDIT_RULES_FILE" > /dev/null <<EOF
# AuditD Rules by linux-hardening-tool

# Monitor modifications to critical files
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/ssh/sshd_config -p wa -k sshd_config_changes

# Monitor privilege escalation
-w /etc/sudoers -p wa -k sudoers_changes

# Monitor use of chmod, chown, useradd, userdel, usermod
-a always,exit -F path=/bin/chmod -F perm=x -k chmod_exec
-a always,exit -F path=/bin/chown -F perm=x -k chown_exec
-a always,exit -F path=/usr/sbin/useradd -F perm=x -k useradd_exec
-a always,exit -F path=/usr/sbin/userdel -F perm=x -k userdel_exec
-a always,exit -F path=/usr/sbin/usermod -F perm=x -k usermod_exec

# Monitor unsuccessful attempts to access files
-a always,exit -F arch=b64 -S open,openat,creat,truncate,ftruncate -F exit=-EACCES -k access_denied
-a always,exit -F arch=b32 -S open,openat,creat,truncate,ftruncate -F exit=-EACCES -k access_denied
EOF

echo "[*] Reloading auditd rules..." | tee -a "$LOG_FILE"
sudo augenrules --load
sudo systemctl restart auditd

echo "=== AuditD Setup Completed at $(date) ===" | tee -a "$LOG_FILE"
