#!/bin/bash
# kb-reject.sh — Reject a knowledge candidate (delete from staging).
# Usage: scripts/kb-reject.sh STAGING_BLOB_NAME
set -euo pipefail

BLOB_NAME="${1:?Usage: kb-reject.sh STAGING_BLOB_NAME}"

az login --identity --client-id "$MANAGED_IDENTITY_CLIENT_ID" --output none 2>/dev/null || {
    echo "ERROR: Azure login failed" >&2; exit 1
}

az storage blob delete \
    --account-name agentfishbowlstorage \
    --container-name org-knowledge \
    --name "$BLOB_NAME" \
    --auth-mode login 2>/dev/null

echo "Rejected: $BLOB_NAME deleted from staging"
