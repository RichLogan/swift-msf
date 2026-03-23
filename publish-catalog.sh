#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Use PATH lookup first, fall back to local build paths.
MSF_GEN="${MSF_GEN:-$(command -v msf-gen 2>/dev/null || echo "$SCRIPT_DIR/.build/debug/msf-gen")}"
QCLIENT="${QCLIENT:-$(command -v qclient 2>/dev/null || echo "$SCRIPT_DIR/../libquicr/build/cmd/examples/qclient")}"

RELAY="${RELAY:-${1:-moq://localhost:33435}}"
NAMESPACE="cisco.2ewebex.2ecom-nab-v1"

"$MSF_GEN" --namespace "$NAMESPACE" | jq -c . | "$QCLIENT" -r "$RELAY" --pub_namespace "cisco.webex.com,nab,v1" --pub_name catalog
