#!/bin/bash
# Cleanup script for lerobot-telemetry Kubernetes deployment

NAMESPACE="default"

echo "Removing lerobot-telemetry deployment from Kubernetes..."
kubectl delete -f k8s-deployment.yaml --ignore-not-found=true

echo ""
echo "ConfigMaps are preserved. To remove them:"
echo "  kubectl delete configmap lerobot-config -n ${NAMESPACE}"
echo "  kubectl delete configmap lerobot-calibration -n ${NAMESPACE}"
