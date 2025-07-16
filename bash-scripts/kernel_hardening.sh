#!/bin/bash

# Filename: kernel_hardening.sh
# Title: Kernel Hardening Module for Linux Hardening Tool
# Description: Kernel hardening module. This applies kernel security configurations
# Author: Jean Ian Panganiban
# Date: 20250716

set -e

# Determine user home directory for logs
if [ "$SUDO_USER" ]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
else
    USER_HOME="$HOME"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="$USER_HOME/linux-hardening-tool/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/kernel_hardening_${TIMESTAMP}.log"

echo "=== Kernel Hardening Started at $(date) ===" | tee -a "$LOG_FILE"

# Backup /etc/sysctl.conf
SYSCTLCONF_FILE="/etc/sysctl.conf"
BACKUP_SYSCTLCONF_FILE="/etc/sysctl.conf.bak.$(date +%Y%m%d_%H%M%S)"
if [ -f "$SYSCTLCONF_FILE" ]; then
    echo "[*] Backing up $SYSCTLCONF_FILE to $BACKUP_SYSCTLCONF_FILE" | tee -a "$LOG_FILE"
    sudo cp "$SYSCTLCONF_FILE" "$BACKUP_SYSCTLCONF_FILE"
else
    echo "[*] $SYSCTLCONF_FILE not found. Skipping backup of $SYSCTLCONF_FILE." | tee -a "$LOG_FILE"
fi

# Backup current kernel parameters
SYSCTL_BACKUP_FILE="$LOG_DIR/sysctl_backup_${TIMESTAMP}.txt"
echo "[*] Backing up current kernel parameters using 'sysctl -a' to $SYSCTL_BACKUP_FILE" | tee -a "$LOG_FILE"
sudo sysctl -a > "$SYSCTL_BACKUP_FILE" 2>/dev/null

# Apply recommended kernel hardening parameters
echo "[*] Applying recommended kernel hardening parameters..." | tee -a "$LOG_FILE"

KERNEL_HARDEN_FILE="/etc/sysctl.d/99-hardening.conf"
sudo tee "$KERNEL_HARDEN_FILE" > /dev/null <<EOF
# Kernel Hardening Parameters by linux-hardening-tool

# Enable SYN cookies
net.ipv4.tcp_syncookies = 1

# Enable reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable IP source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# Ignore ICMP broadcasts and bogus error responses
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Disable sending ICMP redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Harden BPF JIT
net.core.bpf_jit_harden = 2

# Restrict kernel pointers
kernel.kptr_restrict = 2

# Disable loading TTY line discipline modules automatically
dev.tty.ldisc_autoload = 0

# Enable protection of FIFOs and regular files
fs.protected_fifos = 2
fs.protected_hardlinks = 1
fs.protected_regular = 2
fs.protected_symlinks = 1

# Disable dumping of suid processes
fs.suid_dumpable = 0

# Disable SysRq
kernel.sysrq = 0

# Restrict unprivileged BPF
kernel.unprivileged_bpf_disabled = 1

# Kernel core uses PID for coredumps
kernel.core_uses_pid = 1

# Disable Ctrl-Alt-Del reboot
kernel.ctrl-alt-del = 0

# Restrict dmesg
kernel.dmesg_restrict = 1

# Enable address space layout randomization
kernel.randomize_va_space = 2

# Harden perf_event
kernel.perf_event_paranoid = 2

# Note: kernel.modules_disabled = 1 is not applied to preserve functionality
EOF

echo "[*] Kernel hardening configuration written to $KERNEL_HARDEN_FILE" | tee -a "$LOG_FILE"

echo "[*] Loading kernel settings from system configuration files with sysctl --system..." | tee -a "$LOG_FILE"
sudo sysctl --system | tee -a "$LOG_FILE"

echo "=== Kernel Hardening Completed at $(date) ===" | tee -a "$LOG_FILE"