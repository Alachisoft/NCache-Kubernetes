#!/usr/bin/env bash
#
# Creates an EKS cluster in an existing VPC and subnets with an existing IAM role, and installs the
# AWS Load Balancer Controller the NCache Helm chart needs. Edit the values below;
# README.md lists the IAM role it needs and which VM sizes to use if one is not available.
#
# Usage: bash create-cluster.sh

set -euo pipefail

CLUSTER_NAME="<CLUSTER_NAME>"
REGION="<AWS_REGION>"
VPC_ID="<VPC_ID>"
SUBNET_IDS="<SUBNET_ID_1> <SUBNET_ID_2>"   # public, in at least 2 zones
IAM_ROLE="<IAM_ROLE_NAME>"
NODE_COUNT=2
NODE_TYPE="m5.large"              # NCache ENT-8/2; if not available, see README.md#vm-sizes-node_type

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

# Let load balancers use the subnets
aws ec2 create-tags --region "$REGION" --resources $SUBNET_IDS --tags Key=kubernetes.io/role/elb,Value=1 Key=kubernetes.io/role/internal-elb,Value=1

# Install the AWS Load Balancer Controller (uses the node role's permissions)
helm upgrade --install aws-load-balancer-controller aws-load-balancer-controller --repo https://aws.github.io/eks-charts --namespace kube-system --set clusterName="$CLUSTER_NAME" --set region="$REGION" --set vpcId="$VPC_ID" --set hostNetwork=true --wait

# Verify worker nodes
kubectl get nodes -o wide