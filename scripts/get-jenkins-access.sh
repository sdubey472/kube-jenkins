#!/bin/bash

# Script to get Jenkins access information

set -e

JENKINS_NAMESPACE="${1:-jenkins}"

echo "=== Jenkins Access Information ==="
echo ""

echo "1. Getting Jenkins service LoadBalancer endpoint..."
echo ""

kubectl get svc -n "$JENKINS_NAMESPACE" jenkins

echo ""
echo "2. Waiting for external IP/hostname..."
echo "   (Press Ctrl+C to stop)"
echo ""

kubectl get svc -n "$JENKINS_NAMESPACE" jenkins -w

echo ""
echo "3. To get the Jenkins admin password:"
echo "   kubectl exec -it jenkins-0 -n $JENKINS_NAMESPACE -- cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
echo "4. View Jenkins controller logs:"
echo "   kubectl logs -f deployment/jenkins -n $JENKINS_NAMESPACE"
echo ""
echo "5. SSH into Jenkins pod for debugging:"
echo "   kubectl exec -it jenkins-0 -n $JENKINS_NAMESPACE -- /bin/bash"
