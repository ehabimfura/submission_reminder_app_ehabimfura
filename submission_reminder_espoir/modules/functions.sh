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
