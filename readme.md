# Linux Hardening Tool

## Overview
This project is developed as part of **COMP902 Advanced Information Technology Specialised Project May-Aug 2025**.

It automates Linux server hardening using modular Bash scripts and a Python CLI controller, covering:
- SSH Hardening
- Firewall Configuration
- Service Cleanup
- File Permissions Hardening
- Pre/Post Hardening Audits with Lynis

## Requirements
- Python/Python3
- Lynis
- Bash

## Compatibility
Ran and tested on the following Linux distributions:
- Ubuntu 25.04
- CentOS 9
- OpenSUSE 15.6

## Structure
- `bash-scripts/`: Contains modular hardening Bash scripts.
- `cli_controller.py`: Interactive Python CLI controller.
- `logs/`: Stores module execution logs.
- `reports/`: Stores Lynis audit reports.

## Usage
### Running the CLI Controller:
```bash
python3 cli_controller.py