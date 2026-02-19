#!/bin/bash
# update-board-item.sh — Set project board fields on an issue.
# Ensures the issue is on the board (idempotent) then sets specified fields.
# Outputs JSON summary to stdout. Uses GH_TOKEN from environment.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Defaults ---
PROJECT="${PROJECT_NUMBER:-1}"
OWNER="${PROJECT_OWNER:-YourMoveLabs}"
ISSUE=""
REPO="${GITHUB_REPOSITORY:-}"

# Field values (empty = not specified)
F_STATUS=""
F_PRIORITY=""
F_ROADMAP_STATUS=""
F_GOAL=""
F_PHASE=""

# --- Help ---
usage() {
    cat <<'EOF'
Usage: scripts/update-board-item.sh --issue N [FIELD FLAGS] [OPTIONS]

Set project board fields on an issue. Adds the issue to the board if not already present.

Required:
  --issue N               Issue number

Field Flags (at least one required):
  --status VALUE          Built-in Status (Todo, In Progress, Done)
  --priority VALUE        Priority (P1 - Must Have, P2 - Should Have, P3 - Nice to Have)
  --roadmap-status VALUE  Roadmap Status (Proposed, Active, Done, Deferred)
  --goal VALUE            Goal field value
  --phase VALUE           Phase field value

Options:
  --project N             Project number (default: 1)
  --owner OWNER           Org owner (default: YourMoveLabs)
  --repo OWNER/REPO       Repository (default: $GITHUB_REPOSITORY or OWNER/agent-fishbowl)
  --help                  Show this help

Examples:
  # Engineer marks issue as in-progress
  scripts/update-board-item.sh --issue 42 --status "In Progress"

  # PO sets fields from roadmap draft
  scripts/update-board-item.sh --issue 42 \
    --status "Todo" --priority "P1 - Must Have" \
    --roadmap-status "Active" --goal "Goal 1" --phase "Foundation"

Output: JSON with item_id, issue number, fields_set, and any errors.
EOF
    exit 0
}

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --issue) ISSUE="$2"; shift 2 ;;
        --status) F_STATUS="$2"; shift 2 ;;
        --priority) F_PRIORITY="$2"; shift 2 ;;
        --roadmap-status) F_ROADMAP_STATUS="$2"; shift 2 ;;
        --goal) F_GOAL="$2"; shift 2 ;;
        --phase) F_PHASE="$2"; shift 2 ;;
        --project) PROJECT="$2"; shift 2 ;;
        --owner) OWNER="$2"; shift 2 ;;
        --repo) REPO="$2"; shift 2 ;;
        --help|-h) usage ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# --- Validate ---
if [[ -z "$ISSUE" ]]; then
    echo "Error: --issue is required" >&2
    exit 1
fi

if [[ -z "$F_STATUS" && -z "$F_PRIORITY" && -z "$F_ROADMAP_STATUS" && -z "$F_GOAL" && -z "$F_PHASE" ]]; then
    echo "Error: at least one field flag is required (--status, --priority, --roadmap-status, --goal, --phase)" >&2
    exit 1
fi

# --- Resolve repo ---
if [[ -z "$REPO" ]]; then
    REPO="${OWNER}/agent-fishbowl"
fi
ISSUE_URL="https://github.com/${REPO}/issues/${ISSUE}"

# --- Ensure item is on the board (idempotent) ---
ITEM_ID=$(gh project item-add "$PROJECT" \
    --owner "$OWNER" \
    --url "$ISSUE_URL" \
    --format json 2>/dev/null | jq -r '.id // empty')

if [[ -z "$ITEM_ID" ]]; then
    echo "{\"error\": \"Failed to add issue #${ISSUE} to project board\", \"issue\": ${ISSUE}}"
    exit 1
fi

# --- Get field mapping ---
FIELD_DATA=$("$SCRIPT_DIR/project-fields.sh" --project "$PROJECT" --owner "$OWNER" 2>/dev/null)

if [[ -z "$FIELD_DATA" ]] || echo "$FIELD_DATA" | jq -e '.error' >/dev/null 2>&1; then
    echo "{\"error\": \"Failed to fetch project field mapping\", \"issue\": ${ISSUE}, \"item_id\": \"${ITEM_ID}\"}"
    exit 1
fi

PROJECT_ID=$(echo "$FIELD_DATA" | jq -r '.project_id')

# --- Set fields ---
FIELDS_SET=()
ERRORS=()

set_field() {
    local field_name="$1"
    local option_value="$2"

    local field_id
    field_id=$(echo "$FIELD_DATA" | jq -r ".fields[\"${field_name}\"].id // empty")

    if [[ -z "$field_id" ]]; then
        echo "Warning: field '${field_name}' not found on project board" >&2
        ERRORS+=("\"field '${field_name}' not found\"")
        return
    fi

    local option_id
    option_id=$(echo "$FIELD_DATA" | jq -r ".fields[\"${field_name}\"].options[\"${option_value}\"] // empty")

    if [[ -z "$option_id" ]]; then
        echo "Warning: option '${option_value}' not found for field '${field_name}'" >&2
        ERRORS+=("\"option '${option_value}' not found for '${field_name}'\"")
        return
    fi

    if gh project item-edit \
        --id "$ITEM_ID" \
        --field-id "$field_id" \
        --project-id "$PROJECT_ID" \
        --single-select-option-id "$option_id" 2>/dev/null; then
        FIELDS_SET+=("\"${field_name}\"")
    else
        echo "Warning: failed to set ${field_name}=${option_value}" >&2
        ERRORS+=("\"failed to set ${field_name}\"")
    fi
}

[[ -n "$F_STATUS" ]]         && set_field "Status"         "$F_STATUS"
[[ -n "$F_PRIORITY" ]]       && set_field "Priority"       "$F_PRIORITY"
[[ -n "$F_ROADMAP_STATUS" ]] && set_field "Roadmap Status" "$F_ROADMAP_STATUS"
[[ -n "$F_GOAL" ]]           && set_field "Goal"           "$F_GOAL"
[[ -n "$F_PHASE" ]]          && set_field "Phase"          "$F_PHASE"

# --- Output ---
FIELDS_JSON=$(printf '%s\n' "${FIELDS_SET[@]}" 2>/dev/null | jq -s '.' 2>/dev/null || echo '[]')
ERRORS_JSON=$(printf '%s\n' "${ERRORS[@]}" 2>/dev/null | jq -s '.' 2>/dev/null || echo '[]')

echo "{\"item_id\": \"${ITEM_ID}\", \"issue\": ${ISSUE}, \"fields_set\": ${FIELDS_JSON}, \"errors\": ${ERRORS_JSON}}"

# Exit 0 if at least one field was set, 1 if all failed
if [[ ${#FIELDS_SET[@]} -gt 0 ]]; then
    exit 0
else
    exit 1
fi
