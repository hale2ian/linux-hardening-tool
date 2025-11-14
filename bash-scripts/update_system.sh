#!/bin/bash

# Filename: update_system.sh
# Title: System Updates Module
# Description: Updates the system with the latest packages.
# Author: Jean Ian Panganiban
# Date: 20250717

set -e

# Determine user home directory for logs
if [ "$SUDO_USER" ]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
else
    USER_HOME="$HOME"
fi

LOG_DIR="$USER_HOME/linux-hardening-tool/logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/system_update_${TIMESTAMP}.log"

echo "=== System Updates Started at $(date) ===" | tee -a "$LOG_FILE"

# Detect OS and perform updates
if [ -f /etc/debian_version ]; then
    echo "[*] Detected Debian/Ubuntu system. Updating packages..." | tee -a "$LOG_FILE"
    sudo apt update | tee -a "$LOG_FILE"
    sudo apt upgrade -y | tee -a "$LOG_FILE"
    sudo apt autoremove -y | tee -a "$LOG_FILE"
elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
    echo "[*] Detected RHEL/CentOS/Fedora system. Updating packages..." | tee -a "$LOG_FILE"
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf check-update | tee -a "$LOG_FILE"
        sudo dnf upgrade -y | tee -a "$LOG_FILE"
    else
        sudo yum check-update | tee -a "$LOG_FILE"
        sudo yum update -y | tee -a "$LOG_FILE"
    fi
elif [ -f /usr/bin/zypper ]; then
    echo "[*] Detected OpenSUSE system. Updating packages..." | tee -a "$LOG_FILE"
    sudo zypper refresh | tee -a "$LOG_FILE"
    sudo zypper update -y | tee -a "$LOG_FILE"
else
    echo "[!] Unsupported distribution. Please update manually." | tee -a "$LOG_FILE"
    exit 1
fi

echo "[*] System updates completed successfully." | tee -a "$LOG_FILE"
echo "=== System Updates Completed at $(date) ===" | tee -a "$LOG_FILE"
