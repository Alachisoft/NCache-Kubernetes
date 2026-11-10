#!/usr/bin/env bash
#
# Creates an EKS cluster with no load balancer setup, in existing subnets with an existing IAM role.
# Edit the values below; README.md lists the IAM role it needs.
#
# Usage: bash create-eks-cluster.sh

set -euo pipefail

CLUSTER_NAME="<CLUSTER_NAME>"
REGION="<AWS_REGION>"
SUBNET_IDS="<SUBNET_ID_1> <SUBNET_ID_2>"   # public, in at least 2 zones
IAM_ROLE="<IAM_ROLE_NAME>"
NODE_COUNT=2
NODE_TYPE="m5.large"

ROLE_ARN=$(aws iam get-role --role-name "$IAM_ROLE" --query Role.Arn --output text)

# Create EKS cluster (skipped if an earlier run already created it)
echo "Creating EKS cluster $CLUSTER_NAME in $REGION. This takes 10-15 minutes..."
aws eks describe-cluster --region "$REGION" --name "$CLUSTER_NAME" > /dev/null 2>&1 || aws eks create-cluster --region "$REGION" --name "$CLUSTER_NAME" --role-arn "$ROLE_ARN" --resources-vpc-config "subnetIds=${SUBNET_IDS// /,}" > /dev/null
aws eks wait cluster-active --region "$REGION" --name "$CLUSTER_NAME"

# Create worker nodes (skipped if an earlier run already created them)
echo "Creating $NODE_COUNT x $NODE_TYPE nodes. This takes 3-5 minutes..."
aws eks describe-nodegroup --region "$REGION" --cluster-name "$CLUSTER_NAME" --nodegroup-name ncache-nodes > /dev/null 2>&1 || aws eks create-nodegroup --region "$REGION" --cluster-name "$CLUSTER_NAME" --nodegroup-name ncache-nodes --node-role "$ROLE_ARN" --subnets $SUBNET_IDS --instance-types "$NODE_TYPE" --scaling-config "minSize=$NODE_COUNT,maxSize=$NODE_COUNT,desiredSize=$NODE_COUNT" > /dev/null
aws eks wait nodegroup-active --region "$REGION" --cluster-name "$CLUSTER_NAME" --nodegroup-name ncache-nodes

# Configure kubectl access
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

# Verify worker nodes
kubectl get nodes -o wide