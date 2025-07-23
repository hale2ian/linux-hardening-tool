#!/bin/bash

# Filename: aide_configure.sh
# Title: Configure AIDE Module
# Description: Installs, initializes, and configures AIDE for filesystem integrity monitoring.
# Author: Jean Ian Panganiban
# Date: 20250723

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

# OS Detection
OS_ID=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$ID"
    echo "[*] Detected OS: $NAME $VERSION" | tee -a "$LOG_FILE"
fi

# === Common: Install AIDE if not installed ===
install_aide() {
    echo "[*] Installing AIDE if not present..." | tee -a "$LOG_FILE"
    if ! command -v aide >/dev/null 2>&1; then
        if [ "$OS_ID" == "ubuntu" ] || [ "$OS_ID" == "debian" ]; then
            sudo apt update
            sudo apt install -y aide
        elif [ "$OS_ID" == "centos" ] || [ "$OS_ID" == "rhel" ]; then
            sudo dnf install -y aide || sudo yum install -y aide
        elif [ "$OS_ID" == "opensuse-leap" ] || [ "$OS_ID" == "opensuse-tumbleweed" ] || [ "$OS_ID" == "sles" ]; then
            sudo zypper refresh
            sudo zypper install -y aide
        else
            echo "[!] Unsupported distribution. Please install AIDE manually." | tee -a "$LOG_FILE"
            exit 1
        fi
    else
        echo "[*] AIDE is already installed." | tee -a "$LOG_FILE"
    fi
}

# === Ubuntu/Debian handling ===
configure_ubuntu() {
    echo "[*] Configuring AIDE for Ubuntu/Debian..." | tee -a "$LOG_FILE"
    sudo aide --init -c /etc/aide/aide.conf | tee -a "$LOG_FILE"
    if [ -f /var/lib/aide/aide.db.new ]; then
        sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
        echo "[*] AIDE database moved: aide.db.new -> aide.db" | tee -a "$LOG_FILE"
    else
        echo "[!] AIDE initialization did not produce expected database file: aide.db.new" | tee -a "$LOG_FILE"
    fi
}

# === CentOS/RHEL handling ===
configure_centos() {
    echo "[*] Configuring AIDE for CentOS/RHEL..." | tee -a "$LOG_FILE"
    sudo aide --init -c /etc/aide.conf | tee -a "$LOG_FILE"
    if [ -f /var/lib/aide/aide.db.new.gz ]; then
        sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
        echo "[*] AIDE database moved: aide.db.new.gz -> aide.db.gz" | tee -a "$LOG_FILE"
    else
        echo "[!] AIDE initialization did not produce expected database file: aide.db.new.gz" | tee -a "$LOG_FILE"
    fi
}

# === OpenSUSE handling ===
configure_opensuse() {
    echo "[*] Configuring AIDE for OpenSUSE..." | tee -a "$LOG_FILE"
    sudo aide --init -c /etc/aide.conf | tee -a "$LOG_FILE"
    if [ -f /var/lib/aide/aide.db.new ]; then
        sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
        echo "[*] AIDE database moved: aide.db.new -> aide.db" | tee -a "$LOG_FILE"
    else
        echo "[!] AIDE initialization did not produce expected database file: aide.db.new" | tee -a "$LOG_FILE"
    fi
}

# === Cron Job Setup ===
setup_cron_job() {
    CRON_JOB="/etc/cron.daily/aide_check"

    # Determine correct config path
    if [ "$OS_ID" == "ubuntu" ] || [ "$OS_ID" == "debian" ]; then
        AIDE_CONF_PATH="/etc/aide/aide.conf"
    else
        AIDE_CONF_PATH="/etc/aide.conf"
    fi

    if [ ! -f "$CRON_JOB" ]; then
        echo "[*] Setting up daily AIDE cron job using config: $AIDE_CONF_PATH" | tee -a "$LOG_FILE"
        sudo bash -c "cat > $CRON_JOB" <<EOF
#!/bin/bash
/usr/bin/aide --check -c $AIDE_CONF_PATH
EOF
        sudo chmod +x "$CRON_JOB"
        echo "[*] Daily AIDE cron job created." | tee -a "$LOG_FILE"
    else
        echo "[*] Daily AIDE cron job already exists." | tee -a "$LOG_FILE"
    fi
}


# === Execution Flow ===
install_aide

case "$OS_ID" in
    ubuntu|debian)
        configure_ubuntu
        ;;
    centos|rhel)
        configure_centos
        ;;
    opensuse-leap|opensuse-tumbleweed|sles)
        configure_opensuse
        ;;
    *)
        echo "[!] Unsupported OS detected. Manual AIDE configuration may be required." | tee -a "$LOG_FILE"
        ;;
esac

setup_cron_job

echo "=== AIDE Installation and Configuration Completed at $(date) ===" | tee -a "$LOG_FILE"
echo "[*] Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"
