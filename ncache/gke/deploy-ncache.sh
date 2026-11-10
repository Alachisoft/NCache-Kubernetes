#!/usr/bin/env bash
#
# Deploys NCache  to the current kubectl cluster with the NCache Helm chart. Set NCACHE_KEY
# below, or export it before running the script.
#
# Usage: bash deploy-ncache.sh <aks|eks|gke|on-prem>

set -euo pipefail

NCACHE_KEY="xxxxxxxxxxxx"      # NCache installation key
CHART_VERSION="5.3.8"
PLATFORM="${1:-}"

case "$PLATFORM" in aks|eks|gke|on-prem) ;; *) echo "Error: no platform specified '$PLATFORM'. Usage: $0 <aks|eks|gke|on-prem>" >&2; exit 1 ;; esac

if [ -z "$NCACHE_KEY" ]; then echo "Error: NCACHE_KEY is not set. Set it at the top of this script or export it." >&2; exit 1; fi
if ! command -v helm > /dev/null; then echo "Error: helm is not installed." >&2; exit 1; fi

echo "Deploying NCache  $CHART_VERSION on $PLATFORM..."
if ! helm install ncache oci://registry-1.docker.io/alachisoft/ncache-helm --version "$CHART_VERSION" --set deployment.key="$NCACHE_KEY" --set deployment.platform="$PLATFORM"; then echo "Error: NCache  deployment failed." >&2; exit 1; fi

echo "NCache  Helm release installed. Pods may still be starting; check them with: kubectl get pods"