#!/usr/bin/env bash
#
# Creates a GKE Standard cluster in the project's default network. GKE creates load balancers when the
# NCache Helm chart adds its LoadBalancer Services. Edit the values below;
# README.md lists which VM sizes to use if one is not available.
#
# Usage: bash create-cluster.sh

set -euo pipefail

CLUSTER_NAME="<CLUSTER_NAME>"
ZONE="<GCP_ZONE>"
PROJECT_ID="<PROJECT_ID>"
NODE_COUNT=2
MACHINE_TYPE="e2-standard-2"      # NCache ENT-8/2; if not available, see README.md#vm-sizes-machine_type

# Login to Google Cloud (only if not logged in already)
gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | grep -q . || gcloud auth login

# Enable required APIs
gcloud services enable container.googleapis.com compute.googleapis.com --project "$PROJECT_ID"

# Create GKE Standard cluster
echo "Creating cluster $CLUSTER_NAME in $ZONE ($NODE_COUNT x $MACHINE_TYPE). This takes 5-10 minutes; Ctrl+C does not stop it."
gcloud container clusters create "$CLUSTER_NAME" --project "$PROJECT_ID" --zone "$ZONE" --num-nodes "$NODE_COUNT" --machine-type "$MACHINE_TYPE" --disk-size 50 --disk-type pd-balanced --image-type COS_CONTAINERD --enable-ip-alias --release-channel regular

# Configure kubectl access
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT_ID"

# Verify worker nodes
kubectl get nodes -o wide