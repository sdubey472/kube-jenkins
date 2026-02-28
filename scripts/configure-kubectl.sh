#!/bin/bash

# Script to configure kubectl to access the EKS cluster

set -e

CLUSTER_NAME="${1:-jenkins-eks-cluster}"
AWS_REGION="${2:-us-east-1}"

echo "Configuring kubectl for EKS cluster: $CLUSTER_NAME"

# Update kubeconfig
aws eks update-kubeconfig \
    --region "$AWS_REGION" \
    --name "$CLUSTER_NAME"

echo "✓ kubectl configured successfully"
echo ""
echo "Test connection:"
echo "kubectl get nodes"
