#!/bin/bash

# Filename: audit_module.sh
# Title: Audit Module for Linux Hardening Toolkit
# Author: Jean Ian Panganiban
# Date: 20250708
# Description: Performs pre- and post-hardening security audits using Lynis and generates comparative reports.

set -e

LOG_DIR="$HOME/linux-hardening-tool/logs"
REPORT_DIR="$HOME/linux-hardening-tool/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$LOG_DIR"
mkdir -p "$REPORT_DIR"

LOG_FILE="$LOG_DIR/audit_module_${TIMESTAMP}.log"

echo "=== Audit Module Started at $(date) ===" | tee -a "$LOG_FILE"

# Check if Lynis is installed
if ! command -v lynis >/dev/null 2>&1; then
    echo "[!] Lynis not found. Installing Lynis..." | tee -a "$LOG_FILE"
    if [ -f /etc/debian_version ]; then
        sudo apt update
        sudo apt install -y lynis
    elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
        sudo dnf install -y lynis || sudo yum install -y lynis
    else
        echo "[!] Unsupported distribution. Install Lynis manually." | tee -a "$LOG_FILE"
        exit 1
    fi
fi

# Perform pre-hardening scan if requested
read -pr "Run pre-hardening scan? (y/n): " PRE_SCAN
if [[ "$PRE_SCAN" == "y" || "$PRE_SCAN" == "Y" ]]; then
    echo "[*] Running pre-hardening Lynis scan..." | tee -a "$LOG_FILE"
    sudo lynis audit system --quiet --no-colors --logfile "$LOG_DIR/lynis_pre_${TIMESTAMP}.log" | tee "$REPORT_DIR/lynis_pre_${TIMESTAMP}.txt"
    echo "[*] Pre-hardening scan completed. Report saved to $REPORT_DIR/lynis_pre_${TIMESTAMP}.txt" | tee -a "$LOG_FILE"
fi

# Perform post-hardening scan if requested
read -pr "Run post-hardening scan? (y/n): " POST_SCAN
if [[ "$POST_SCAN" == "y" || "$POST_SCAN" == "Y" ]]; then
    echo "[*] Running post-hardening Lynis scan..." | tee -a "$LOG_FILE"
    sudo lynis audit system --quiet --no-colors --logfile "$LOG_DIR/lynis_post_${TIMESTAMP}.log" | tee "$REPORT_DIR/lynis_post_${TIMESTAMP}.txt"
    echo "[*] Post-hardening scan completed. Report saved to $REPORT_DIR/lynis_post_${TIMESTAMP}.txt" | tee -a "$LOG_FILE"
fi

# Attempt to extract and compare Lynis hardening scores if both reports exist
PRE_SCORE_FILE="$REPORT_DIR/lynis_pre_${TIMESTAMP}.txt"
POST_SCORE_FILE="$REPORT_DIR/lynis_post_${TIMESTAMP}.txt"

if [ -f "$PRE_SCORE_FILE" ] && [ -f "$POST_SCORE_FILE" ]; then
    PRE_SCORE=$(grep "Hardening index" "$PRE_SCORE_FILE" | awk '{print $3}')
    POST_SCORE=$(grep "Hardening index" "$POST_SCORE_FILE" | awk '{print $3}')
    echo "[*] Pre-hardening score: $PRE_SCORE" | tee -a "$LOG_FILE"
    echo "[*] Post-hardening score: $POST_SCORE" | tee -a "$LOG_FILE"
    echo "[*] Improvement: $(echo "$POST_SCORE - $PRE_SCORE" | bc)" | tee -a "$LOG_FILE"
else
    echo "[!] Could not find both pre and post hardening reports to compare scores." | tee -a "$LOG_FILE"
fi

echo "=== Audit Module Completed at $(date) ===" | tee -a "$LOG_FILE"

exit 0
