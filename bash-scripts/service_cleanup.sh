#!/bin/bash

# Filename: service_cleanup.sh
# Title: Service Cleanup Module for Linux Hardening Tool
# Author: Jean Ian Panganiban
# Date: 20250630
# Description: Detects and disables unnecessary or insecure services.

set -e

LOG_FILE="$HOME/linux-hardening-tool/logs/service_cleanup_$(date +%Y%m%d_%H%M%S).log"

echo "=== Service Cleanup Started at $(date) ===" | tee -a "$LOG_FILE"

# List of insecure/unused services to disable
SERVICES_TO_DISABLE=(
"telnet"
"ftp"
"rsh"
"rlogin"
"rexec"
"tftp"
"nfs-server"
"rpcbind"
"cups"
"cups-browsed"
"avahi-daemon"
"avahi-daemon.socket"
)


for SERVICE in "${SERVICES_TO_DISABLE[@]}"; do
    if systemctl list-unit-files | grep -q "^${SERVICE}"; then
        echo "[*] Disabling and stopping ${SERVICE}..." | tee -a "$LOG_FILE"
        sudo systemctl stop "${SERVICE}" || echo "[!] Failed to stop ${SERVICE}, it may not be running." | tee -a "$LOG_FILE"
		sudo systemctl disable "${SERVICE}" || echo "[!] Failed to disable ${SERVICE}."
		sudo systemctl mask "${SERVICE}" || echo "[!] Failed to mask ${SERVICE}."
    else
        echo "[*] ${SERVICE} not found on this system. Skipping." | tee -a "$LOG_FILE"
    fi
done

echo "=== Service Cleanup Completed at $(date) ===" | tee -a "$LOG_FILE"

exit 0