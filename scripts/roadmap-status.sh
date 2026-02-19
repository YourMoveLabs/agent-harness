#!/bin/bash
# roadmap-status.sh — Roadmap coverage report for Agent Fishbowl agents.
# Cross-references GitHub Project roadmap items against open/closed issues.
# Uses word-overlap matching to detect which items have corresponding issues.
# Outputs JSON to stdout. Uses GH_TOKEN from environment.
set -euo pipefail

# --- Defaults ---
PROJECT=1
OWNER="YourMoveLabs"
GAPS_ONLY=false
ACTIVE_ONLY=false
BOARD_HEALTH=false

# --- Help ---
usage() {
    cat <<'EOF'
Usage: scripts/roadmap-status.sh [OPTIONS]

Cross-reference GitHub Project roadmap items against issues.

Options:
  --gaps-only           Only show items without matching issues
  --active-only         Only show Active/Proposed items (skip Done/Deferred)
  --board-health        Check board hygiene (drafts, untracked issues, status mismatches)
  --project N           Project number (default: 1)
  --owner OWNER         Org owner (default: YourMoveLabs)
  --help                Show this help

Examples:
  # Full roadmap coverage report (PM use case)
  scripts/roadmap-status.sh

  # Find roadmap gaps for PO to create issues
  scripts/roadmap-status.sh --gaps-only --active-only

  # Check board hygiene (PM health check)
  scripts/roadmap-status.sh --board-health

Output: JSON with summary and per-item details (or board health report).
EOF
    exit 0
}

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --gaps-only) GAPS_ONLY=true; shift ;;
        --active-only) ACTIVE_ONLY=true; shift ;;
        --board-health) BOARD_HEALTH=true; shift ;;
        --project) PROJECT="$2"; shift 2 ;;
        --owner) OWNER="$2"; shift 2 ;;
        --help|-h) usage ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# --- Fetch roadmap items ---
ROADMAP_RAW=$(gh project item-list "$PROJECT" --owner "$OWNER" --format json --limit 50 2>/dev/null || echo '{"items":[]}')

# --- Fetch issues (open + recently closed) ---
OPEN_ISSUES=$(gh issue list --state open --json number,title,projectItems --limit 50 2>/dev/null || echo "[]")
CLOSED_ISSUES=$(gh issue list --state closed --json number,title --limit 30 2>/dev/null || echo "[]")

# --- Board health mode ---
if [[ "$BOARD_HEALTH" == "true" ]]; then
    echo "$ROADMAP_RAW" | jq \
        --argjson open_issues "$OPEN_ISSUES" '

    # Count draft items (content.type == "DraftIssue")
    [.items[] | select(.content.type == "DraftIssue")] as $drafts |

    # Non-draft items (real issues on the board)
    [.items[] | select(.content.type != "DraftIssue")] as $real_items |

    # Items with empty Status field (should be Todo/In Progress/Done)
    [$real_items[] | select(
        (.status // .Status // "") == "" or
        (.status // .Status // "") == "null"
    )] as $empty_status |

    # Items with empty Priority field (should have been set by PO or PM)
    [$real_items[] | select(
        (.priority // .Priority // "") == "" or
        (.priority // .Priority // "") == "null"
    )] as $empty_priority |

    # Count open issues NOT on the project board (empty projectItems)
    [$open_issues[] | select((.projectItems // []) | length == 0)] as $untracked |

    {
        board_health: {
            total_board_items: (.items | length),
            draft_items: ($drafts | length),
            draft_titles: [$drafts[] | .title],
            real_items: ($real_items | length),
            empty_status_items: ($empty_status | length),
            empty_status_titles: [$empty_status[] | .title],
            empty_priority_items: ($empty_priority | length),
            empty_priority_titles: [$empty_priority[] | .title],
            open_issues_total: ($open_issues | length),
            untracked_issues: ($untracked | length),
            untracked_issue_numbers: [$untracked[] | .number]
        }
    }'
    exit 0
fi

# --- Cross-reference using jq ---
echo "$ROADMAP_RAW" | jq \
    --argjson open_issues "$OPEN_ISSUES" \
    --argjson closed_issues "$CLOSED_ISSUES" \
    --argjson gaps_only "$GAPS_ONLY" \
    --argjson active_only "$ACTIVE_ONLY" '

# Normalize: lowercase, split on non-alpha, remove short words
def normalize:
    ascii_downcase
    | gsub("[^a-z0-9 ]"; " ")
    | split(" ")
    | map(select(length > 2))
    | unique;

# Compute similarity between two titles
def similarity($a; $b):
    ($a | normalize) as $words_a |
    ($b | normalize) as $words_b |
    ([$words_a[], $words_b[]] | unique | length) as $union |
    ([$words_a[] | select(. as $w | $words_b | index($w))] | length) as $intersection |
    if $union > 0 then ($intersection * 100 / $union | floor) else 0 end;

# Combine all issues
($open_issues + $closed_issues) as $all_issues |

# Process each roadmap item
[.items[] |
    # Extract custom field values
    . as $item |
    ($item | keys | map(select(startswith("Priority") or startswith("Goal") or startswith("Phase") or startswith("Roadmap Status") or startswith("Status")))) as $field_keys |

    # Try to find field values (gh returns lowercase field names in JSON)
    ($item["priority"] // $item["Priority"] // "unknown") as $priority |
    ($item["roadmap Status"] // $item["Roadmap Status"] // $item["roadmap_status"] // "unknown") as $roadmap_status |
    ($item["goal"] // $item["Goal"] // "unknown") as $goal |
    ($item["phase"] // $item["Phase"] // "unknown") as $phase |

    # Find matching issues (similarity > 50%)
    [($all_issues[] | select(similarity(.title; $item.title) > 50) | .number)] as $matching |

    {
        title: $item.title,
        priority: $priority,
        roadmap_status: $roadmap_status,
        goal: $goal,
        phase: $phase,
        matching_issues: $matching,
        covered: ($matching | length > 0)
    }
] |

# Apply filters
if $active_only then
    [.[] | select(.roadmap_status == "Proposed" or .roadmap_status == "Active")]
else . end |

if $gaps_only then
    [.[] | select(.covered == false)]
else . end |

# Build output with summary
. as $items |
{
    summary: {
        total: ($items | length),
        covered: ([$items[] | select(.covered)] | length),
        gaps: ([$items[] | select(.covered | not)] | length),
        by_status: ($items | group_by(.roadmap_status) | map({key: .[0].roadmap_status, value: length}) | from_entries)
    },
    items: $items
}'
