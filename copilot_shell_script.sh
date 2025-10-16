#!/usr/bin/env bash
set -euo pipefail

# copilot_shell_script.sh - update ASSIGNMENT inside chosen submission_reminder_* folder

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find matching app directories
candidates=()
for d in "$SCRIPT_DIR"/submission_reminder_* ; do
  if [[ -d "$d" ]]; then
    candidates+=("$d")
  fi
done

if [[ ${#candidates[@]} -eq 0 ]]; then
  echo "No submission_reminder_* directories found in $SCRIPT_DIR"
  echo "Run create_environment.sh first or run this from the repo root."
  exit 1
fi

echo "Found the following app directories:"
for i in "${!candidates[@]}"; do
  printf "  [%d] %s\n" $((i+1)) "$(basename "${candidates[$i]}")"
done

if [[ ${#candidates[@]} -eq 1 ]]; then
  chosen="${candidates[0]}"
  echo "Selecting the only candidate: $(basename "$chosen")"
else
  read -r -p "Enter the number of the directory to update: " sel
  if ! [[ "$sel" =~ ^[0-9]+$ ]] || (( sel < 1 || sel > ${#candidates[@]} )); then
    echo "Invalid selection."
    exit 1
  fi
  chosen="${candidates[$((sel-1))]}"
fi

config_file="$chosen/config/config.env"
if [[ ! -f "$config_file" ]]; then
  echo "Error: config file not found at $config_file"
  exit 1
fi

read -r -p "Enter the new assignment name: " new_assignment
if [[ -z "$new_assignment" ]]; then
  echo "Empty assignment name. Aborting."
  exit 1
fi

echo "Current ASSIGNMENT in $config_file:"
grep -E '^ASSIGNMENT=' "$config_file" || true

# Escape the value
escaped="$(printf '%s' "$new_assignment" | sed 's/[&/\]/\\&/g')"

# Try GNU sed, otherwise fallback to portable awk replace
if sed --version >/dev/null 2>&1; then
  sed -i.bak -E "s|^ASSIGNMENT=.*|ASSIGNMENT=\"$escaped\"|" "$config_file"
else
  # BSD/mac sed also accepts -i '', but some systems differ; try safe fallback
  if sed -i '' -E "s|^ASSIGNMENT=.*|ASSIGNMENT=\"$escaped\"|" "$config_file" 2>/dev/null; then
    :
  else
    # Fallback using awk to rewrite file
    tmp="$(mktemp)"
    awk -v val="$escaped" 'BEGIN{FS=OFS=""} /^ASSIGNMENT=/{print "ASSIGNMENT=\"" val "\""; next} {print}' "$config_file" > "$tmp"
    mv "$tmp" "$config_file"
    chmod --reference="$config_file".bak "$config_file" 2>/dev/null || true
  fi
fi

echo "Updated ASSIGNMENT in $config_file:"
grep -E '^ASSIGNMENT=' "$config_file" || true

# Make startup executable if present
if [[ -f "$chosen/startup.sh" ]]; then
  chmod +x "$chosen/startup.sh" || true
fi

read -r -p "Run startup.sh for $(basename "$chosen") now? (y/N): " runit
runit=${runit:-N}
if [[ "$runit" =~ ^[Yy]$ ]]; then
  (cd "$chosen" && ./startup.sh)
else
  echo "To run it later: cd \"${chosen}\" && ./startup.sh"
fi
