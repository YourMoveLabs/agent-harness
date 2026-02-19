#!/bin/bash
# kb-read.sh — Read a knowledge candidate blob.
# Usage: scripts/kb-read.sh BLOB_NAME
set -euo pipefail

BLOB_NAME="${1:?Usage: kb-read.sh BLOB_NAME}"

az login --identity --client-id "$MANAGED_IDENTITY_CLIENT_ID" --output none 2>/dev/null || {
    echo "ERROR: Azure login failed" >&2; exit 1
}

az storage blob download \
    --account-name agentfishbowlstorage \
    --container-name org-knowledge \
    --name "$BLOB_NAME" \
    --auth-mode login \
    --file /dev/stdout 2>/dev/null
