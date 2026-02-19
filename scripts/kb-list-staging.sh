#!/bin/bash
# kb-list-staging.sh — List knowledge candidates awaiting curation.
# Returns one blob name per line, or nothing if staging is empty.
set -euo pipefail

az login --identity --client-id "$MANAGED_IDENTITY_CLIENT_ID" --output none 2>/dev/null || {
    echo "ERROR: Azure login failed" >&2; exit 1
}

az storage blob list \
    --account-name agentfishbowlstorage \
    --container-name org-knowledge \
    --prefix "staging/" \
    --auth-mode login \
    --output tsv \
    --query "[].name" 2>/dev/null
