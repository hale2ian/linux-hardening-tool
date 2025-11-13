#!/bin/bash

# Filename: ml_anomaly_scan.sh
# Title: ML-based Anomaly Detection Module (COMP903 Integration)
# Description: Calls the COMP903 ML detector to analyse logs and writes a report.

set -e

# Determine correct user home directory (same pattern as other modules)
if [ "$SUDO_USER" ]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
else
    USER_HOME="$HOME"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BASE_DIR="$USER_HOME/linux-hardening-tool"
LOG_DIR="$BASE_DIR/logs"
REPORT_DIR="$BASE_DIR/reports"
mkdir -p "$LOG_DIR" "$REPORT_DIR"

LOG_FILE="$LOG_DIR/ml_anomaly_scan_${TIMESTAMP}.log"
REPORT_FILE="$REPORT_DIR/ml_anomaly_report_${TIMESTAMP}.txt"

echo "=== ML Anomaly Detection Started at $(date) ===" | tee -a "$LOG_FILE"

# Path to your COMP903 project and virtualenv
COMP903_DIR="$USER_HOME/COMP903"
VENV_DIR="$COMP903_DIR/mlencode-env"
ML_SCRIPT="$COMP903_DIR/ml_detect_cli.py"

if [ ! -d "$COMP903_DIR" ]; then
    echo "[!] COMP903 directory not found at $COMP903_DIR" | tee -a "$LOG_FILE"
    exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
    echo "[!] Virtualenv not found at $VENV_DIR" | tee -a "$LOG_FILE"
    exit 1
fi

if [ ! -f "$ML_SCRIPT" ]; then
    echo "[!] ML detection script not found: $ML_SCRIPT" | tee -a "$LOG_FILE"
    exit 1
fi

echo "[*] Activating virtualenv: $VENV_DIR" | tee -a "$LOG_FILE"
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

# Example: analyse a fixed encoded dataset (you can change this later to real live logs)
ENCODED_DATASET="$COMP903_DIR/data/encoded_logs_Linux2kstructured.csv"

if [ ! -f "$ENCODED_DATASET" ]; then
    echo "[!] Encoded dataset not found at $ENCODED_DATASET" | tee -a "$LOG_FILE"
    echo "[!] Please update ENCODED_DATASET path in ml_anomaly_scan.sh" | tee -a "$LOG_FILE"
    deactivate
    exit 1
fi

echo "[*] Running ML detector on $ENCODED_DATASET ..." | tee -a "$LOG_FILE"

python "$ML_SCRIPT" \
    --input "$ENCODED_DATASET" \
    --output "$REPORT_FILE" \
    | tee -a "$LOG_FILE"

DETECT_EXIT=$?

deactivate

if [ $DETECT_EXIT -ne 0 ]; then
    echo "[!] ML detection script exited with status $DETECT_EXIT" | tee -a "$LOG_FILE"
    exit $DETECT_EXIT
fi

echo "[*] ML anomaly report saved to: $REPORT_FILE" | tee -a "$LOG_FILE"
echo "=== ML Anomaly Detection Completed at $(date) ===" | tee -a "$LOG_FILE"

exit 0
