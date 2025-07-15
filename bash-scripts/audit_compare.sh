#!/bin/bash

# Filename: audit_compare.sh
# Title: Audit Report Comparison 
# Description: Compares two Lynis reports (pre and post hardening) and outputs structured differences.
# Author: Jean Ian Panganiban
# Date: 20250708

set -e

# === Determine correct user home directory ===
if [ "$SUDO_USER" ]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
else
    USER_HOME="$HOME"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="$USER_HOME/linux-hardening-tool/reports"
LOG_DIR="$USER_HOME/linux-hardening-tool/logs"
LOG_FILE="$LOG_DIR/compare_audit_reports_${TIMESTAMP}.log"
mkdir -p "$LOG_DIR"

echo "=== Audit Report Comparison Started at $(date) ===" | tee -a "$LOG_FILE"

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

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <pre_report_file> <post_report_file>" | tee -a "$LOG_FILE"
    exit 1
fi

# Accept input files
PRE_FILE="$1"
POST_FILE="$2"

if [ ! -f "$PRE_FILE" ]; then
    echo "[!] Pre-report file not found: $PRE_FILE" | tee -a "$LOG_FILE"
    exit 1
fi
if [ ! -f "$POST_FILE" ]; then
    echo "[!] Post-report file not found: $POST_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

# === Extract and compare hardening scores ===
PRE_SCORE=$(grep -i "hardening_index" "$PRE_FILE" | awk -F'=' '{print $2}')
POST_SCORE=$(grep -i "hardening_index" "$POST_FILE" | awk -F'=' '{print $2}')
IMPROVEMENT=$(echo "$POST_SCORE - $PRE_SCORE" | bc)

echo "" | tee -a "$LOG_FILE"
echo "=== Hardening Index ===" | tee -a "$LOG_FILE"
echo "Pre-hardening score:  $PRE_SCORE" | tee -a "$LOG_FILE"
echo "Post-hardening score: $POST_SCORE" | tee -a "$LOG_FILE"
echo "Improvement:          $IMPROVEMENT" | tee -a "$LOG_FILE"

# === Compare category-aligned warnings ===
echo "" | tee -a "$LOG_FILE"
echo "=== Category Analysis ===" | tee -a "$LOG_FILE"

extract_category_count() {
    local FILE="$1"
    local CATEGORY="$2"
    grep -i "$CATEGORY" "$FILE" | wc -l
}

print_category_comparison() {
    local CATEGORY="$1"
    local DESC="$2"
    PRE_COUNT=$(extract_category_count "$PRE_FILE" "$CATEGORY")
    POST_COUNT=$(extract_category_count "$POST_FILE" "$CATEGORY")
    DIFF=$(( PRE_COUNT - POST_COUNT ))
    echo "$DESC: $PRE_COUNT -> $POST_COUNT (Reduced by $DIFF)" | tee -a "$LOG_FILE"
}

print_category_comparison "ssh" "SSH-related warnings"
print_category_comparison "firewall" "Firewall-related warnings"
print_category_comparison "service" "Service-related warnings"
print_category_comparison "permission" "File Permissions warnings"
print_category_comparison "boot" "Bootloader-related warnings"
print_category_comparison "sudo" "Sudo-related warnings"

# === List resolved warnings/suggestions ===
echo "" | tee -a "$LOG_FILE"
echo "=== Resolved Warnings/Suggestions ===" | tee -a "$LOG_FILE"

grep "\[WARNING\]" "$PRE_FILE" | while read -r line; do
    ID=$(echo "$line" | awk -F'] ' '{print $2}')
    if ! grep -q "$ID" "$POST_FILE"; then
        echo "[RESOLVED] $ID" | tee -a "$LOG_FILE"
    fi
done

echo "" | tee -a "$LOG_FILE"
echo "=== Audit Report Comparison Completed at $(date) ===" | tee -a "$LOG_FILE"
