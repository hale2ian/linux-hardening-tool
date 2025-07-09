#!/bin/bash

# Filename: service_cleanup.sh
# Title: Service Cleanup Module for Linux Hardening Tool
# Author: Jean Ian Panganiban
# Date: 20250630
# Description: Detects and disables/removes unnecessary or insecure services.

set -e

LOG_FILE="$HOME/linux-hardening-tool/logs/service_cleanup_$(date +%Y%m%d_%H%M%S).log"

echo "=== Service Cleanup Started at $(date) ===" | tee -a "$LOG_FILE"

# List of services to check and optionally disable/remove
SERVICES_TO_CLEANUP=(
    "telnet"
    "ftp"
    "rsh"
    "rlogin"
    "rexec"
    "cups"
    "nfs-server"
    "rpcbind"
    "smb"
)

# Function to check if a service is installed
is_service_installed() {
    local service="$1"
    if systemctl list-unit-files | grep -q "^$service"; then
        return 0
    else
        return 1
    fi
}

# Function to disable and stop a service
disable_and_stop_service() {
    local service="$1"
    echo "[*] Disabling and stopping $service ..." | tee -a "$LOG_FILE"
    sudo systemctl disable "$service" || true
    sudo systemctl stop "$service" || true
}

# Function to remove a package if installed
remove_package_if_installed() {
    local package="$1"
    if command -v dpkg >/dev/null 2>&1; then
        if dpkg -l | grep -q "^ii.*$package"; then
            echo "[*] Removing package $package ..." | tee -a "$LOG_FILE"
            sudo apt-get remove --purge -y "$package"
        fi
    elif command -v rpm >/dev/null 2>&1; then
        if rpm -q "$package" >/dev/null 2>&1; then
            echo "[*] Removing package $package ..." | tee -a "$LOG_FILE"
            sudo dnf remove -y "$package" || sudo yum remove -y "$package"
        fi
    fi
}

# Iterate and clean up each target service
for SERVICE in "${SERVICES_TO_CLEANUP[@]}"; do
    echo "[*] Checking $SERVICE ..." | tee -a "$LOG_FILE"
    if is_service_installed "$SERVICE.service"; then
        disable_and_stop_service "$SERVICE.service"
    else
        echo "[*] $SERVICE.service not enabled, checking for installed package ..." | tee -a "$LOG_FILE"
    fi

    remove_package_if_installed "$SERVICE"
done

echo "=== Service Cleanup Completed at $(date) ===" | tee -a "$LOG_FILE"

exit 0
