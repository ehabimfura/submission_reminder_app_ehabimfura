#!/usr/bin/env bash
set -euo pipefail

# create_environment.sh - portable version (works on Linux, macOS w/ Git Bash, WSL)
# Usage: ./create_environment.sh

echo "=== Submission Reminder App environment builder ==="

read -r -p "Enter your name (used in directory name): " username

# Portable lowercase + sanitize (works on macOS and Linux)
lower_username="$(printf '%s' "$username" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '_')"
sanitized_name="$(printf '%s' "$lower_username" | tr -cd 'A-Za-z0-9_')"
if [[ -z "$sanitized_name" ]]; then
  echo "Error: sanitized name is empty. Use letters or numbers in your name."
  exit 1
fi

dirname="submission_reminder_${sanitized_name}"
echo "Creating app directory: $dirname"

# Remove old directory if present (confirm)
if [[ -d "$dirname" ]]; then
  echo "Directory $dirname already exists."
  read -r -p "Overwrite it? (y/N): " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm -rf "$dirname"
  else
    echo "Aborting."
    exit 0
  fi
fi

# Create directories
mkdir -p "$dirname"/{app,modules,assets,config}

# Write config.env
cat > "$dirname/config/config.env" <<'EOF'
# This is the config file
ASSIGNMENT="Shell Navigation"
DAYS_REMAINING=2
EOF

# Write functions.sh
cat > "$dirname/modules/functions.sh" <<'EOF'
#!/usr/bin/env bash
# functions.sh - helper functions for submission reminder app

# Function to read submissions file and output students who have not submitted
function check_submissions {
    local submissions_file="$1"
    echo "Checking submissions in $submissions_file"

    # Skip the header and iterate through the lines
    while IFS=, read -r student assignment status; do
        # Trim whitespace
        student="$(printf '%s' "$student" | awk '{$1=$1;print}')"
        assignment="$(printf '%s' "$assignment" | awk '{$1=$1;print}')"
        status="$(printf '%s' "$status" | awk '{$1=$1;print}')"

        # Compare case-insensitive for robustness and check status
        if [[ "${assignment,,}" == "${ASSIGNMENT,,}" && "${status,,}" == "not submitted" ]]; then
            echo "Reminder: $student has not submitted the $ASSIGNMENT assignment!"
        fi
    done < <(tail -n +2 "$submissions_file") # Skip header
}
EOF

# Write reminder.sh
cat > "$dirname/app/reminder.sh" <<'EOF'
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
EOF

# Create submissions.txt (with at least 5 new students appended)
cat > "$dirname/assets/submissions.txt" <<'EOF'
student, assignment, submission status
Chinemerem, Shell Navigation, not submitted
Chiagoziem, Git, submitted
Divine, Shell Navigation, not submitted
Anissa, Shell Basics, submitted
Eric, Git, not submitted
Aline, Shell Basics, not submitted
Peace, Git, not submitted
Samson, Shell Permissions, submitted
Marie, Shell Permissions, not submitted
Patrick, Shell Navigation, submitted
Joy, Git, not submitted
EOF

# Create startup.sh (robust)
cat > "$dirname/startup.sh" <<'EOF'
#!/usr/bin/env bash
# startup.sh - start the submission reminder app

set -euo pipefail

# Ensure all .sh files are executable (on systems supporting chmod)
if command -v find >/dev/null 2>&1; then
  find . -type f -name "*.sh" -exec chmod +x {} \; || true
else
  chmod +x ./app/reminder.sh ./modules/functions.sh ./startup.sh || true
fi

# Basic file checks
if [[ ! -f "./config/config.env" ]]; then
  echo "Missing ./config/config.env"
  exit 1
fi
if [[ ! -f "./modules/functions.sh" ]]; then
  echo "Missing ./modules/functions.sh"
  exit 1
fi
if [[ ! -f "./assets/submissions.txt" ]]; then
  echo "Missing ./assets/submissions.txt"
  exit 1
fi

# Source config to display summary
# shellcheck disable=SC1090
source ./config/config.env

echo "Assignment loaded: $ASSIGNMENT"
echo "Days remaining: $DAYS_REMAINING"
echo "--------------------------------------------"

# Run the reminder
./app/reminder.sh

echo "--------------------------------------------"
echo "Reminder check completed."
EOF

# Make scripts executable (best effort)
if command -v find >/dev/null 2>&1; then
  find "$dirname" -type f -name "*.sh" -exec chmod +x {} \;
else
  chmod +x "$dirname"/app/reminder.sh "$dirname"/modules/functions.sh "$dirname"/startup.sh || true
fi

echo "Environment created at: $dirname"
echo "To run:"
echo "  cd $dirname"
echo "  ./startup.sh"
