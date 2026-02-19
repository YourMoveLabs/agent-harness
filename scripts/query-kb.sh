#!/bin/bash
# query-kb.sh — Search the organizational knowledge base.
# Usage: scripts/query-kb.sh "search query" [--top N]
#
# Searches approved organizational insights — durable patterns about
# our business, audience, approach, and coordination.
#
# Requires: FISHBOWL_AI_SEARCH_KEY env var
set -euo pipefail

if [ "${1:-}" = "--help" ] || [ -z "${1:-}" ]; then
    cat <<'HELP'
Usage: scripts/query-kb.sh "search query" [--top N]

Search the organizational knowledge base for relevant insights.

Examples:
  scripts/query-kb.sh "audience content preferences"
  scripts/query-kb.sh "agent coordination patterns" --top 3

The KB contains curated business insights submitted by agents and
approved by the triage agent. Results are ranked by relevance.
HELP
    [ -z "${1:-}" ] && exit 1
    exit 0
fi

QUERY="$1"
TOP=5
shift
while [ $# -gt 0 ]; do
    case "$1" in
        --top) TOP="$2"; shift 2 ;;
        *) shift ;;
    esac
done

SEARCH_URL="${FISHBOWL_AI_SEARCH_URL:-https://fishbowl-ai-search.search.windows.net}"
KB_NAME="org-knowledge-kb"
API_VERSION="2025-11-01-Preview"

if [ -z "${FISHBOWL_AI_SEARCH_KEY:-}" ]; then
    echo "ERROR: FISHBOWL_AI_SEARCH_KEY not set" >&2
    exit 1
fi

# Try Knowledge Base MCP endpoint first (semantic search)
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "${SEARCH_URL}/knowledgebases/${KB_NAME}/mcp?api-version=${API_VERSION}" \
    -H "Content-Type: application/json" \
    -H "api-key: ${FISHBOWL_AI_SEARCH_KEY}" \
    -d "$(jq -n --arg q "$QUERY" --argjson top "$TOP" '{
        method: "tools/call",
        params: {
            name: "knowledge_base_retrieve",
            arguments: {query: $q, top: $top}
        }
    }')")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    # Parse MCP response
    echo "$BODY" | jq -r '
        if .result.content then
            .result.content[] |
            "---",
            .text,
            ""
        else
            "No results found for: '"$QUERY"'"
        end
    ' 2>/dev/null || echo "$BODY"
    exit 0
fi

# Fallback: direct index search
INDEX_NAME="org-knowledge-ks-index"
RESPONSE=$(curl -s -X POST \
    "${SEARCH_URL}/indexes/${INDEX_NAME}/docs/search?api-version=2024-07-01" \
    -H "Content-Type: application/json" \
    -H "api-key: ${FISHBOWL_AI_SEARCH_KEY}" \
    -d "$(jq -n --arg q "$QUERY" --argjson top "$TOP" '{
        search: $q,
        top: $top,
        select: "snippet,blob_url"
    }')")

echo "$RESPONSE" | jq -r '
    if .value and (.value | length) > 0 then
        .value[] |
        (.snippet | fromjson? // {insight: .snippet}) as $doc |
        "---",
        "Insight: \($doc.insight // "N/A")",
        "Author: \($doc.author_role // "unknown") | Date: \($doc.submitted_at // "unknown")",
        ""
    else
        "No results found for: '"$QUERY"'"
    end
' 2>/dev/null || echo "$RESPONSE"
