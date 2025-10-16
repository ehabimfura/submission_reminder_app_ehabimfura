#!/usr/bin/env bash
# startup.sh - start the Submission Reminder application
# Portable, defensive script with helpful messages for beginners.
# Place this file at: submission_reminder_<yourName>/startup.sh

set -euo pipefail

# Resolve the directory where this script lives (app root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$SCRIPT_DIR"

echo "============================================"
echo "Starting Submission Reminder App (root: $APP_ROOT)"
echo "============================================"

# Required files (relative to APP_ROOT)
required=(
  "$APP_ROOT/config/config.env"
  "$APP_ROOT/modules/functions.sh"
  "$APP_ROOT/app/reminder.sh"
  "$APP_ROOT/assets/submissions.txt"
)

# Check required files
missing=0
for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "Error: required file not found -> $f"
    missing=1
  fi
done
if [[ $missing -eq 1 ]]; then
  echo "Please run create_environment.sh or restore the missing files."
  exit 1
fi

# Make .sh files executable (best-effort)
if command -v find >/dev/null 2>&1; then
  find "$APP_ROOT" -type f -name "*.sh" -exec chmod +x {} \; || true
else
  # Fallback: attempt chmod on known scripts (some Windows environments may ignore chmod)
  chmod +x "$APP_ROOT/startup.sh" "$APP_ROOT/app/reminder.sh" "$APP_ROOT/modules/functions.sh" 2>/dev/null || true
fi

# Source config variables so we can print a summary
# shellcheck disable=SC1090
source "$APP_ROOT/config/config.env"

echo "Assignment loaded: $ASSIGNMENT"
echo "Days remaining: $DAYS_REMAINING"
echo "--------------------------------------------"

# Run the reminder from APP_ROOT so relative paths inside reminder.sh work
pushd "$APP_ROOT" >/dev/null
  # Use the script in app/ — it will source config and functions via relative paths
  if [[ -x "./app/reminder.sh" ]]; then
    ./app/reminder.sh
  else
    # attempt to run via bash if execute bit not honored on this filesystem
    bash ./app/reminder.sh
  fi
popd >/dev/null

echo "--------------------------------------------"
echo "✅ Reminder check completed."
echo "============================================"

