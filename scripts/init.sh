#!/bin/bash

# This script initializes the Terraform workspace

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Jenkins on EKS Terraform Setup ==="
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "ERROR: Terraform is not installed"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "ERROR: AWS credentials not configured"
    exit 1
fi

echo "✓ Prerequisites check passed"
echo ""

# Copy example tfvars if it doesn't exist
if [ ! -f "terraform.tfvars" ]; then
    echo "Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "⚠ Please update terraform.tfvars with your configuration"
    echo ""
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

echo ""
echo "✓ Terraform initialization complete"
echo ""
echo "Next steps:"
echo "1. Update terraform.tfvars with your configuration"
echo "2. Run: terraform plan"
echo "3. Review the plan and run: terraform apply"
