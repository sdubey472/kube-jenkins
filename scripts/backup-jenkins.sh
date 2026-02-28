#!/bin/bash

# Script to backup Jenkins data

set -e

BACKUP_DIR="${1:-.}/jenkins-backups"
JENKINS_NAMESPACE="${2:-jenkins}"
JENKINS_PVC="${3:-jenkins}"

mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/jenkins-backup-$(date +%Y%m%d_%H%M%S).tar.gz"

echo "Backing up Jenkins to: $BACKUP_FILE"

# Create a temporary pod to access the PVC
kubectl run -it --rm --image=busybox --restart=Never \
    -n "$JENKINS_NAMESPACE" \
    backup-pod -- sh -c "
    tar czf - /var/jenkins_home
" > "$BACKUP_FILE"

echo "✓ Backup complete: $BACKUP_FILE"
echo ""
echo "Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"
