#!/usr/bin/env bash
#
# Deploys NCache OSS to the current kubectl cluster: the Discovery Service, then NCache.
#
# Usage: bash deploy-ncache.sh

set -euo pipefail

# Must be the raw link: kubectl apply needs the YAML file itself, and a github.com link returns the GitHub web page (HTML), which kubectl cannot read as a manifest.
MANIFESTS="https://raw.githubusercontent.com/Alachisoft/NCache-Kubernetes/main/ncache-oss"

if ! command -v kubectl > /dev/null; then echo "Error: kubectl is not installed." >&2; exit 1; fi

echo "Deploying NCache..."
if ! kubectl apply -f "$MANIFESTS/ncache.yaml"; then echo "Error: NCache deployment failed." >&2; exit 1; fi

echo "Deploying Discovery Service..."
if ! kubectl apply -f "$MANIFESTS/discoveryservice.yaml"; then echo "Error: Discovery Service deployment failed." >&2; exit 1; fi

echo "NCache OSS manifests applied. Pods may still be starting; check them with: kubectl get pods"

