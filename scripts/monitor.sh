#!/bin/bash

# Script to monitor cluster and Jenkins deployment

set -e

JENKINS_NAMESPACE="${1:-jenkins}"

echo "=== Monitoring EKS Cluster and Jenkins ==="
echo ""

echo "1. EKS Nodes Status:"
echo "   kubectl get nodes -o wide"
echo ""
kubectl get nodes -o wide

echo ""
echo "2. Jenkins Pods Status:"
echo "   kubectl get pods -n $JENKINS_NAMESPACE -o wide"
echo ""
kubectl get pods -n "$JENKINS_NAMESPACE" -o wide

echo ""
echo "3. Jenkins Resource Usage:"
echo "   kubectl top pods -n $JENKINS_NAMESPACE"
echo ""
kubectl top pods -n "$JENKINS_NAMESPACE" 2>/dev/null || echo "Metrics server may not be ready yet"

echo ""
echo "4. Pod Events:"
echo "   kubectl get events -n $JENKINS_NAMESPACE --sort-by='.lastTimestamp'"
echo ""
kubectl get events -n "$JENKINS_NAMESPACE" --sort-by='.lastTimestamp' | tail -20

echo ""
echo "5. PVC Status:"
echo "   kubectl get pvc -n $JENKINS_NAMESPACE"
echo ""
kubectl get pvc -n "$JENKINS_NAMESPACE"

echo ""
echo "Real-time monitoring:"
echo "kubectl get pods -n $JENKINS_NAMESPACE -w"
