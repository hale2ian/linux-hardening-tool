#!/bin/bash

# Filename: ml_anomaly_scan.sh
# Title: ML-based Anomaly Detection Module (COMP903 Integration)
# Description: Calls the COMP903 ML detector to analyse logs and writes a report.

set -e
set -o pipefail

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

# Path to COMP903 project and virtualenv directory
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

# Choose which encoded dataset to analyse on this machine
# For your dev VM you might use encoded_logs_COMP903DEVUBUNTUVM.csv
# For COMP902 Ubuntu VM: encoded_logs_COMP902UBUNTUVM.csv, etc.
# For now we try several in order of preference.

POSSIBLE_DATASETS=(
  "$COMP903_DIR/datasets/encoded_logs_COMP903DEVUBUNTUVM.csv"
  "$COMP903_DIR/datasets/encoded_logs_COMP902UBUNTUVM.csv"
  "$COMP903_DIR/datasets/encoded_logs_COMP902CENTOSVM.csv"
  "$COMP903_DIR/datasets/encoded_logs_COMP902OPENSUSEVM.csv"
  "$COMP903_DIR/datasets/encoded_logs_Linux2k.csv"
  "$COMP903_DIR/datasets/encoded_logs_Linux25k.csv"
)

ENCODED_DATASET=""

for ds in "${POSSIBLE_DATASETS[@]}"; do
    if [ -f "$ds" ]; then
        ENCODED_DATASET="$ds"
        break
    fi
done

if [ -z "$ENCODED_DATASET" ]; then
    echo "[!] No encoded dataset found in COMP903 directory." | tee -a "$LOG_FILE"
    echo "[!] Checked:" | tee -a "$LOG_FILE"
    for ds in "${POSSIBLE_DATASETS[@]}"; do
        echo "    - $ds" | tee -a "$LOG_FILE"
    done
    exit 1
fi

echo "[*] Using encoded dataset: $ENCODED_DATASET" | tee -a "$LOG_FILE"

echo "[*] Activating virtualenv: $VENV_DIR" | tee -a "$LOG_FILE"
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

echo "[*] Running ML detector..." | tee -a "$LOG_FILE"

# Change to COMP903 directory so relative paths (models/...) resolve correctly
cd "$COMP903_DIR"

python "$ML_SCRIPT" \
    --input "$ENCODED_DATASET" \
    --output "$REPORT_FILE" \
    | tee -a "$LOG_FILE"

DETECT_EXIT=$?

deactivate

# Go back to the base dir (optional, but tidy)
cd "$BASE_DIR"

if [ $DETECT_EXIT -ne 0 ]; then
    echo "[!] ML detection script exited with status $DETECT_EXIT" | tee -a "$LOG_FILE"
    exit $DETECT_EXIT
fi

if [ ! -f "$REPORT_FILE" ]; then
    echo "[!] ML detection did not produce report file: $REPORT_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

echo "[*] ML anomaly report saved to: $REPORT_FILE" | tee -a "$LOG_FILE"
echo "=== ML Anomaly Detection Completed at $(date) ===" | tee -a "$LOG_FILE"

exit 0
EOF
