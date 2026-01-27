#!/bin/bash
# Deployment script for lerobot-telemetry to Kubernetes

set -e

NAMESPACE="default"  # Using default namespace for AIO environment
IMAGE_NAME="lerobot-telemetry:latest"
CALIBRATION_DIR="../../lerobot-edge/configs"

echo "=== LeRobot Telemetry - Kubernetes Deployment ==="
echo ""

# Step 1: Build the Docker image
echo "Step 1: Building Docker image..."
cd ../..
docker build -f containers/teleoperate_mqtt/Dockerfile -t ${IMAGE_NAME} .
cd containers/teleoperate_mqtt
echo "✓ Image built successfully"
echo ""

# Step 2: Load image to k3s/microk8s if needed
# Uncomment the appropriate line for your K8s distribution:
# k3s ctr images import $(docker save ${IMAGE_NAME} | k3s ctr images import -)
# microk8s ctr image import $(docker save ${IMAGE_NAME})
# For standard k8s, ensure image is available in the cluster

# Step 2: Check for required service account
echo "Step 2: Checking for mqtt-client ServiceAccount..."
if ! kubectl get serviceaccount mqtt-client -n ${NAMESPACE} &> /dev/null; then
    echo "⚠ Warning: ServiceAccount 'mqtt-client' not found in namespace '${NAMESPACE}'"
    echo "This is required for Azure IoT Operations MQTT authentication."
    echo "Please create it with: kubectl apply -f serviceaccount.yaml"
else
    echo "✓ ServiceAccount found"
fi
echo ""

# Step 4: Create/update config map from local configurations
echo "Step 3: Creating configuration ConfigMap..."
kubectl create configmap lerobot-config \
  --from-file=local_configurations.yaml \
  -n ${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -
echo "✓ Configuration ConfigMap created"
echo ""

# Step 5: Create/update calibration config map
echo "Step 4: Creating calibration ConfigMap..."
if [ -d "${CALIBRATION_DIR}" ] && [ "$(ls -A ${CALIBRATION_DIR}/*.json 2>/dev/null)" ]; then
  kubectl create configmap lerobot-calibration \
    --from-file=${CALIBRATION_DIR}/ \
    -n ${NAMESPACE} \
    --dry-run=client -o yaml | kubectl apply -f -
  echo "✓ Calibration ConfigMap created from ${CALIBRATION_DIR}"
else
  echo "⚠ Warning: No calibration files found in ${CALIBRATION_DIR}"
  echo "Please run 03_configure_follower.py and 04_configure_leader.py first"
  echo "Then run this script again or manually update the ConfigMap:"
  echo "  kubectl create configmap lerobot-calibration --from-file=${CALIBRATION_DIR}/ -n ${NAMESPACE} -o yaml --dry-run=client | kubectl apply -f -"
fi
echo ""

# Step 6: Apply deployment
echo "Step 5: Deploying to Kubernetes..."
kubectl apply -f k8s-deployment.yaml
echo "✓ Deployment applied"
echo ""

# Step 7: Wait for deployment
echo "Step 6: Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/teleoperate-mqtt -n ${NAMESPACE} || true
echo ""

# Step 8: Show status
echo "=== Deployment Status ==="
kubectl get pods -n ${NAMESPACE} -l app=teleoperate-mqtt
echo ""

echo "=== View Logs ==="
echo "kubectl logs -f -n ${NAMESPACE} -l app=teleoperate-mqtt"
echo ""

echo "=== Update Calibration Files ==="
echo "kubectl create configmap lerobot-calibration --from-file=${CALIBRATION_DIR}/ -n ${NAMESPACE} -o yaml --dry-run=client | kubectl apply -f -"
echo "kubectl rollout restart deployment/teleoperate-mqtt -n ${NAMESPACE}"
echo ""

echo "✓ Deployment complete!"
