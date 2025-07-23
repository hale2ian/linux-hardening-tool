#!/bin/bash

# Filename: aide_install_configure.sh
# Title: AIDE Installation and Configuration Module
# Description: Installs, initializes, and configures AIDE for filesystem integrity monitoring.
# Author: Jean Ian Panganiban
# Date: 20250717

set -e

# === Determine correct user home directory ===
if [ "$SUDO_USER" ]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
else
    USER_HOME="$HOME"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="$USER_HOME/linux-hardening-tool/logs"
LOG_FILE="$LOG_DIR/aide_configure_${TIMESTAMP}.log"
mkdir -p "$LOG_DIR"

echo "=== AIDE Installation and Configuration Started at $(date) ===" | tee -a "$LOG_FILE"

# OS detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "[*] Detected OS: $NAME $VERSION" | tee -a "$LOG_FILE"
fi

# Install AIDE if not installed
if ! command -v aide >/dev/null 2>&1; then
    echo "[*] Installing AIDE..." | tee -a "$LOG_FILE"
    if [ -f /etc/debian_version ]; then
        sudo apt update
        sudo apt install -y aide
    elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
        sudo dnf install -y aide || sudo yum install -y aide
    elif [ -f /usr/bin/zypper ]; then
        sudo zypper refresh
        sudo zypper install -y aide
    else
        echo "[!] Unsupported distribution. Please install AIDE manually." | tee -a "$LOG_FILE"
        exit 1
    fi
else
    echo "[*] AIDE is already installed." | tee -a "$LOG_FILE"
fi

# Initialize AIDE database
echo "[*] Initializing AIDE database. This may take several minutes..." | tee -a "$LOG_FILE"
sudo aide --init | tee -a "$LOG_FILE"

# Move initialized database to active database location
if [ -f /var/lib/aide/aide.db.new.gz ]; then
    sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
    echo "[*] AIDE database initialized and moved to active location." | tee -a "$LOG_FILE"
else
    echo "[!] AIDE initialization did not produce expected database file." | tee -a "$LOG_FILE"
fi

# Schedule daily cron job if not present
CRON_JOB="/etc/cron.daily/aide_check"
if [ ! -f "$CRON_JOB" ]; then
    echo "[*] Creating daily AIDE cron job for integrity checks..." | tee -a "$LOG_FILE"
    sudo bash -c "cat > $CRON_JOB" <<EOF
#!/bin/bash
/usr/bin/aide --check
EOF
    sudo chmod +x "$CRON_JOB"
    echo "[*] Daily AIDE cron job created." | tee -a "$LOG_FILE"
else
    echo "[*] Daily AIDE cron job already exists." | tee -a "$LOG_FILE"
fi

echo "=== AIDE Installation and Configuration Completed at $(date) ===" | tee -a "$LOG_FILE"
echo "[*] AIDE module setup completed successfully." | tee -a "$LOG_FILE"
echo "[*] Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"
