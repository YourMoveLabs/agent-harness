#!/bin/bash
# set-project-readme.sh — Set the GitHub Project description and README.
# Reads README content from docs/project-board-readme.md and applies it.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PROJECT="${PROJECT_NUMBER:-1}"
OWNER="${PROJECT_OWNER:-YourMoveLabs}"

README_FILE="$HARNESS_ROOT/docs/project-board-readme.md"
DESCRIPTION="AI agent team roadmap — planning, execution, and maintenance for Agent Fishbowl"

if [ ! -f "$README_FILE" ]; then
    echo "ERROR: $README_FILE not found"
    exit 1
fi

echo "Setting project short description..."
gh project edit "$PROJECT" --owner "$OWNER" \
  --description "$DESCRIPTION"

echo "Setting project README..."
gh project edit "$PROJECT" --owner "$OWNER" \
  --readme "$(cat "$README_FILE")"

echo "Done. Project description and README updated."
