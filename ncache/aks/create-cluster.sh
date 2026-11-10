#!/usr/bin/env bash
#
# Creates an AKS cluster behind a Standard Azure load balancer. AKS creates the cluster's network
# itself. Edit the values below; README.md lists which VM sizes to use if one is not available.
#
# Usage: bash create-cluster.sh

set -euo pipefail

CLUSTER_NAME="<CLUSTER_NAME>"
REGION="<Azure_REGION>"
RESOURCE_GROUP="<RESOURCE_GROUP>"
NODE_COUNT=2
VM_SIZE="Standard_B2s"        # NCache ENT-4/2; if not available, see README.md#vm-sizes-vm_size

# Login to Azure (only if not logged in already)
az account show -o none 2>/dev/null || az login

# Create Resource Group
az group create --name "$RESOURCE_GROUP" --location "$REGION" -o none

# Create AKS cluster
echo "Creating AKS cluster $CLUSTER_NAME in $REGION ($NODE_COUNT x $VM_SIZE). This takes 5-10 minutes..."
az aks create --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --location "$REGION" --node-count "$NODE_COUNT" --node-vm-size "$VM_SIZE" --load-balancer-sku standard --generate-ssh-keys -o none

# Configure kubectl access
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing

# Verify worker nodes
kubectl get nodes -o wide