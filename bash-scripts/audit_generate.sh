#!/bin/bash

# Filename: audit_generate.sh
# Title: Audit Report Generator 
# Description: Generates Lynis audit report and stores log.
# Author: Jean Ian Panganiban
# Date: 20250708

set -e

REPORT_DIR="$HOME/linux-hardening-tool/reports"
LOG_DIR="$HOME/linux-hardening-tool/logs"
REPORT_FILE="$REPORT_DIR/lynis_${SCAN_TYPE}_hardening_${TIMESTAMP}.txt"
LOG_FILE="$LOG_DIR/lynis_${SCAN_TYPE}_hardening_${TIMESTAMP}.log"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=== Audit Report Generation Started at $(date) ===" | tee -a "$LOG_FILE"

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

# Prompt for scan type
read -pr "Is this a pre-hardening or post-hardening scan? (pre/post): " SCAN_TYPE
SCAN_TYPE=$(echo "$SCAN_TYPE" | tr '[:upper:]' '[:lower:]')

if [ "$SCAN_TYPE" != "pre" ] && [ "$SCAN_TYPE" != "post" ]; then
    echo "[!] Invalid scan type. Use 'pre' or 'post'." | tee -a "$LOG_FILE"
    exit 1
fi

echo "[*] Running Lynis system audit..." | tee -a "$LOG_FILE"
sudo lynis audit system --report-file "$REPORT_FILE" | tee -a "$LOG_FILE"

# Extract and record hardening index
HARDENING_INDEX=$(grep -i "hardening_index" "$REPORT_FILE" | awk -F'=' '{print $2}')
echo "[*] Hardening Index recorded: $HARDENING_INDEX" | tee -a "$LOG_FILE"
echo "=== Audit Report Generation Completed at $(date) ===" | tee -a "$LOG_FILE"
echo "[*] Report saved to: $REPORT_FILE" | tee -a "$LOG_FILE"
echo "[*] Lynis log saved to: $LOG_FILE" | tee -a "$LOG_FILE"
