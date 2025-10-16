#!/usr/bin/env bash
# reminder.sh - prints reminders for current ASSIGNMENT

# Source environment and helpers (paths relative to app root)
# NOTE: this assumes reminder.sh is executed from the app root (./)
if [[ -f "./config/config.env" ]]; then
  # shellcheck disable=SC1090
  source ./config/config.env
else
  echo "Error: config/config.env not found (expected ./config/config.env)"
  exit 1
fi

if [[ -f "./modules/functions.sh" ]]; then
  # shellcheck disable=SC1090
  source ./modules/functions.sh
else
  echo "Error: modules/functions.sh not found"
  exit 1
fi

submissions_file="./assets/submissions.txt"

echo "Assignment: $ASSIGNMENT"
echo "Days remaining to submit: $DAYS_REMAINING days"
echo "--------------------------------------------"

check_submissions "$submissions_file"
