#!/bin/bash

# Filename: filepermissions_hardening.sh
# Title: File Permissions Hardening Module for Linux Hardening Tool
# Author: Jean Ian Panganiban
# Date: 20250708
# Description: Secures sensitive files and directories by enforcing correct permissions and ownership.
#!/bin/bash

set -e

LOG_FILE="$HOME/linux-hardening-tool/logs/file_permissions_$(date +%Y%m%d_%H%M%S).log"

echo "=== File Permissions Hardening Started at $(date) ===" | tee -a "$LOG_FILE"

# Function to secure a file with specific permissions and ownership
secure_file() {
    local FILE_PATH=$1
    local PERMISSIONS=$2
    local OWNER=$3
    local GROUP=$4

    if [ -e "$FILE_PATH" ]; then
        CURRENT_INFO=$(stat -c "%A %U %G" "$FILE_PATH")
        echo "[*] BEFORE: $FILE_PATH permissions: $CURRENT_INFO" | tee -a "$LOG_FILE"
        echo "[*] Securing $FILE_PATH: perms=$PERMISSIONS owner=$OWNER group=$GROUP" | tee -a "$LOG_FILE"
        sudo chmod "$PERMISSIONS" "$FILE_PATH"
        sudo chown "$OWNER":"$GROUP" "$FILE_PATH"
        UPDATED_INFO=$(stat -c "%A %U %G" "$FILE_PATH")
        echo "[*] AFTER: $FILE_PATH permissions: $UPDATED_INFO" | tee -a "$LOG_FILE"
    else
        echo "[!] $FILE_PATH not found. Skipping." | tee -a "$LOG_FILE"
    fi
}

# Function to secure a directory with specific permissions and ownership
secure_directory() {
    local DIR_PATH=$1
    local PERMISSIONS=$2
    local OWNER=$3
    local GROUP=$4

    if [ -d "$DIR_PATH" ]; then
        CURRENT_INFO=$(stat -c "%A %U %G" "$DIR_PATH")
        echo "[*] BEFORE: $DIR_PATH permissions: $CURRENT_INFO" | tee -a "$LOG_FILE"
        echo "[*] Securing directory $DIR_PATH: perms=$PERMISSIONS owner=$OWNER group=$GROUP" | tee -a "$LOG_FILE"
        sudo chmod "$PERMISSIONS" "$DIR_PATH"
        sudo chown "$OWNER":"$GROUP" "$DIR_PATH"
        UPDATED_INFO=$(stat -c "%A %U %G" "$DIR_PATH")
        echo "[*] AFTER: $DIR_PATH permissions: $UPDATED_INFO" | tee -a "$LOG_FILE"
    else
        echo "[!] Directory $DIR_PATH not found. Skipping." | tee -a "$LOG_FILE"
    fi
}

# --- Secure system authentication files ---
secure_file "/etc/passwd" 644 root root
secure_file "/etc/shadow" 000 root root
secure_file "/etc/group" 644 root root
secure_file "/etc/gshadow" 000 root root

# --- Secure SSH configurations ---
secure_file "/etc/ssh/sshd_config" 600 root root
secure_directory "/etc/ssh" 700 root root

# Secure SSH host keys
for KEY in /etc/ssh/ssh_host_*; do
    if [ -f "$KEY" ]; then
        if [[ "$KEY" == *.pub ]]; then
            secure_file "$KEY" 644 root root
        else
            secure_file "$KEY" 600 root root
        fi
    fi
done

# --- Secure bootloader configs ---
secure_file "/boot/grub2/grub.cfg" 600 root root
secure_file "/boot/grub/grub.cfg" 600 root root

# --- Secure root home and SSH keys ---
secure_directory "/root" 700 root root
secure_directory "/root/.ssh" 700 root root
secure_file "/root/.ssh/authorized_keys" 600 root root

# --- Secure cron configuration ---
secure_file "/etc/crontab" 600 root root
secure_directory "/etc/cron.hourly" 700 root root
secure_directory "/etc/cron.daily" 700 root root
secure_directory "/etc/cron.weekly" 700 root root
secure_directory "/etc/cron.monthly" 700 root root
secure_directory "/etc/cron.d" 700 root root

# --- Secure sudoers configuration ---
secure_file "/etc/sudoers" 440 root root
secure_directory "/etc/sudoers.d" 750 root root
for FILE in /etc/sudoers.d/*; do
    if [ -f "$FILE" ]; then
        secure_file "$FILE" 440 root root
    fi
done

# --- Secure /etc/fstab ---
secure_file "/etc/fstab" 644 root root

# --- Secure PAM configuration directory ---
secure_directory "/etc/pam.d" 755 root root
for FILE in /etc/pam.d/*; do
    if [ -f "$FILE" ]; then
        secure_file "$FILE" 644 root root
    fi
done

# --- Secure /var/log ---
secure_directory "/var/log" 750 root root
# Secure key log files
LOG_FILES=("/var/log/auth.log" "/var/log/secure")
for FILE in "${LOG_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        secure_file "$FILE" 600 root root
    fi
done

echo "=== File Permissions Hardening Completed at $(date) ===" | tee -a "$LOG_FILE"

exit 0

