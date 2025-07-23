#!/bin/bash

# Filename: audit_generate.sh
# Title: Generate Lynis Report Module
# Description: Generates Lynis audit report and stores log.
# Author: Jean Ian Panganiban
# Date: 20250708

# === Determine correct user home directory ===
if [ "$SUDO_USER" ]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
else
    USER_HOME="$HOME"
fi

# Accept scan type as an argument
SCAN_TYPE="$1"
SCAN_TYPE=$(echo "$SCAN_TYPE" | tr '[:upper:]' '[:lower:]')

if [ "$SCAN_TYPE" != "pre" ] && [ "$SCAN_TYPE" != "post" ]; then
    echo "[!] Invalid or missing scan type. Usage: $0 pre|post"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="$USER_HOME/linux-hardening-tool/reports"
LOG_DIR="$USER_HOME/linux-hardening-tool/logs"
REPORT_FILE="$REPORT_DIR/lynis_${SCAN_TYPE}_hardening_${TIMESTAMP}.txt"
LOG_FILE="$LOG_DIR/lynis_${SCAN_TYPE}_hardening_${TIMESTAMP}.log"
mkdir -p "$REPORT_DIR" "$LOG_DIR"

echo "=== Audit Report Generation Started at $(date) ===" | tee -a "$LOG_FILE"

echo "[*] Using user home directory: $USER_HOME" | tee -a "$LOG_FILE"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "[*] Detected OS: $NAME $VERSION" | tee -a "$LOG_FILE"
fi

# Check if Lynis is installed
if ! command -v lynis >/dev/null 2>&1; then
    echo "[!] bc not found. Installing..." | tee -a "$LOG_FILE"
    if [ -f /etc/debian_version ]; then
        sudo apt update
        sudo apt install -y lynis
    elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
        sudo dnf install -y lynis || sudo yum install -y lynis
	elif [ -f /usr/bin/zypper ]; then
		sudo zypper refresh
		sudo zypper install -y lynis
    else
        echo "[!] Unsupported distribution. Install bc manually." | tee -a "$LOG_FILE"
        exit 1
    fi
fi

# Check if bc is installed.
if ! command -v bc >/dev/null 2>&1; then
	echo "[!] bc not found. Installing..." | tee -a "$LOG_FILE"
    if [ -f /etc/debian_version ]; then
        sudo apt update
        sudo apt install -y bc
    elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
        sudo dnf install -y bc || sudo yum install -y bc
	elif [ -f /usr/bin/zypper ]; then
		sudo zypper refresh
		sudo zypper install -y bc
    else
        echo "[!] Unsupported distribution. Install bc manually." | tee -a "$LOG_FILE"
        exit 1
    fi
fi

echo "[*] Running Lynis system audit..." | tee -a "$LOG_FILE"
sudo lynis audit system --report-file "$REPORT_FILE" | tee -a "$LOG_FILE"

# Fix ownership of the report and log files
if [ "$SUDO_USER" ]; then
    sudo chown "$SUDO_USER:$SUDO_USER" "$REPORT_FILE"
fi

# Extract and record hardening index
HARDENING_INDEX=$(grep -i "hardening_index" "$REPORT_FILE" | awk -F'=' '{print $2}')
echo "[*] Hardening Index recorded: $HARDENING_INDEX" | tee -a "$LOG_FILE"
echo "=== Audit Report Generation Completed at $(date) ===" | tee -a "$LOG_FILE"
echo "[*] Report saved to: $REPORT_FILE" | tee -a "$LOG_FILE"
echo "[*] Lynis log saved to: $LOG_FILE" | tee -a "$LOG_FILE"
