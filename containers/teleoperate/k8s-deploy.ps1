# PowerShell deployment script for lerobot-telemetry to Kubernetes
# For Windows environments

$ErrorActionPreference = "Stop"

$NAMESPACE = "default"  # Using default namespace for AIO environment
$IMAGE_NAME = "lerobot-telemetry:latest"
$CALIBRATION_DIR = "..\..\lerobot-edge\configs"

Write-Host "=== LeRobot Telemetry - Kubernetes Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build the Docker image
Write-Host "Step 1: Building Docker image..." -ForegroundColor Yellow
Push-Location ..\..
docker build -f containers/teleoperate_mqtt/Dockerfile -t $IMAGE_NAME .
Pop-Location
Write-Host "[OK] Image built successfully" -ForegroundColor Green
Write-Host ""

# Step 2: Check for required service account
Write-Host "Step 2: Checking for mqtt-client ServiceAccount..." -ForegroundColor Yellow
$serviceAccount = kubectl get serviceaccount mqtt-client -n $NAMESPACE 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] ServiceAccount 'mqtt-client' not found in namespace '$NAMESPACE'" -ForegroundColor Yellow
    Write-Host "This is required for Azure IoT Operations MQTT authentication."
    Write-Host "Please create it with: kubectl apply -f serviceaccount.yaml"
} else {
    Write-Host "[OK] ServiceAccount found" -ForegroundColor Green
}
Write-Host ""

# Step 3: Create/update config map from local configurations
Write-Host "Step 3: Creating configuration ConfigMap..." -ForegroundColor Yellow
kubectl create configmap lerobot-config `
  --from-file=local_configurations.yaml `
  -n $NAMESPACE `
  --dry-run=client -o yaml | kubectl apply -f -
Write-Host "[OK] Configuration ConfigMap created" -ForegroundColor Green
Write-Host ""

# Step 4: Create/update calibration config map
Write-Host "Step 4: Creating calibration ConfigMap..." -ForegroundColor Yellow
if (Test-Path $CALIBRATION_DIR) {
    $jsonFiles = Get-ChildItem -Path $CALIBRATION_DIR -Filter *.json -ErrorAction SilentlyContinue
    if ($jsonFiles.Count -gt 0) {
        kubectl create configmap lerobot-calibration `
            --from-file=$CALIBRATION_DIR `
            -n $NAMESPACE `
            --dry-run=client -o yaml | kubectl apply -f -
        Write-Host "[OK] Calibration ConfigMap created from $CALIBRATION_DIR" -ForegroundColor Green
    } else {
        Write-Host "[WARN] No calibration files found in $CALIBRATION_DIR" -ForegroundColor Yellow
        Write-Host "Please run 03_configure_follower.py and 04_configure_leader.py first"
        Write-Host "Then run this script again or manually update the ConfigMap:"
        Write-Host "  kubectl create configmap lerobot-calibration --from-file=$CALIBRATION_DIR -n $NAMESPACE -o yaml --dry-run=client | kubectl apply -f -"
    }
} else {
    Write-Host "[WARN] Calibration directory not found: $CALIBRATION_DIR" -ForegroundColor Yellow
}
Write-Host ""

# Step 5: Apply deployment
Write-Host "Step 5: Deploying to Kubernetes..." -ForegroundColor Yellow
kubectl apply -f k8s-deployment.yaml
Write-Host "[OK] Deployment applied" -ForegroundColor Green
Write-Host ""

# Step 6: Wait for deployment
Write-Host "Step 6: Waiting for deployment to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=60s deployment/lerobot-telemetry -n $NAMESPACE
Write-Host ""

# Step 7: Show status
Write-Host "=== Deployment Status ===" -ForegroundColor Cyan
kubectl get pods -n $NAMESPACE -l app=lerobot-telemetry
Write-Host ""

Write-Host "=== View Logs ===" -ForegroundColor Cyan
Write-Host "kubectl logs -f -n $NAMESPACE -l app=lerobot-telemetry"
Write-Host ""

Write-Host "=== Update Calibration Files ===" -ForegroundColor Cyan
Write-Host "kubectl create configmap lerobot-calibration --from-file=$CALIBRATION_DIR -n $NAMESPACE -o yaml --dry-run=client | kubectl apply -f -"
Write-Host "kubectl rollout restart deployment/lerobot-telemetry -n $NAMESPACE"
Write-Host ""

Write-Host "[OK] Deployment complete!" -ForegroundColor Green
