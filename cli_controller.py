#!/usr/bin/env python3

"""
Filename: cli_controller.py
Title: Python CLI Controller for Linux Hardening Tool
Author: Jean Ian Panganiban
Date: 2025-07-08
Description: Allows modular execution of hardening and audit modules via an interactive CLI.
"""

import os
import subprocess
import sys

BASE_DIR = os.path.expanduser("~/linux-hardening-tool")
SCRIPTS_DIR = os.path.join(BASE_DIR, "bash-scripts")
LOGS_DIR = os.path.join(BASE_DIR, "logs")
REPORTS_DIR = os.path.join(BASE_DIR, "reports")

os.makedirs(LOGS_DIR, exist_ok=True)
os.makedirs(REPORTS_DIR, exist_ok=True)


def run_script(script_name):
    script_path = os.path.join(SCRIPTS_DIR, script_name)
    if not os.path.exists(script_path):
        print(f"[!] Script not found: {script_path}")
        return
    try:
        print(f"[*] Running {script_name}...")
        subprocess.run(["sudo", script_path], check=True)
        print(f"[*] {script_name} completed.\n")
    except subprocess.CalledProcessError as e:
        print(f"[!] Error while running {script_name}: {e}")


def compare_reports():
    pre_file = input("Enter the full path to the PRE-hardening report: ").strip()
    post_file = input("Enter the full path to the POST-hardening report: ").strip()
    script_path = os.path.join(SCRIPTS_DIR, "audit_compare.sh")
    if not os.path.exists(script_path):
        print(f"[!] Comparison script not found: {script_path}")
        return
    try:
        subprocess.run([script_path, pre_file, post_file], check=True)
        print("[*] Comparison completed.\n")
    except subprocess.CalledProcessError as e:
        print(f"[!] Error during comparison: {e}")


def main_menu():
    while True:
        print("="*60)
        print("Linux Hardening Tool CLI Controller")
        print("="*60)
        print("1) Run SSH Hardening Module")
        print("2) Run Firewall Module")
        print("3) Run Service Cleanup Module")
        print("4) Run File Permissions Module")
        print("5) Run Kernel Hardening Module")
        print("6) Run System Audit (auditd) Module")
        print("7) Run System Update Module")
        print("8) Run Generate Lynis Report Module")
        print("9) Run Compare Lynis Reports Module")
        print("10) Exit")
        choice = input("Select an option (1-10): ").strip()

        if choice == '1':
            run_script("ssh_hardening.sh")
        elif choice == '2':
            run_script("firewall_hardening.sh")
        elif choice == '3':
            run_script("service_cleanup.sh")
        elif choice == '4':
            run_script("filepermissions_hardening.sh")
        elif choice == '5':
            run_script("kernel_hardening.sh")
        elif choice == '6':
            run_script("auditd_configure.sh")
        elif choice == '7':
            run_script("update_system.sh")
        elif choice == '8':
            scan_type = input("Enter scan type (pre/post): ").strip().lower()
            if scan_type in ["pre", "post"]:
                subprocess.run(["sudo", os.path.join(SCRIPTS_DIR, "audit_generate.sh"), scan_type], check=True)
            else:
                print("[!] Invalid scan type. Skipping execution.\n")
        elif choice == '9':
            compare_reports()
        elif choice == '10':
            print("Exiting Linux Hardening Tool CLI Controller.")
            sys.exit(0)
        else:
            print("[!] Invalid selection. Please choose a valid option.\n")


if __name__ == "__main__":
    try:
        main_menu()
    except KeyboardInterrupt:
        print("\n[!] Interrupted by user. Exiting...")
        sys.exit(0)
