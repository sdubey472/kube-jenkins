#!/bin/bash

# Script to destroy Jenkins infrastructure

set -e

echo "⚠ WARNING: This will destroy Jenkins and all associated resources!"
echo ""
read -p "Are you sure? Type 'yes' to continue: " -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cancelled"
    exit 1
fi

echo "Destroying Terraform resources..."
terraform destroy
