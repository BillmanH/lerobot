# LeRobot Telemetry (AKRI Connector)

This container reads SO101 robot arm telemetry from USB and exposes it via HTTP for Azure IoT Operations Data Flows integration. Acts as an AKRI-discoverable asset for AIO data processing pipelines.

## Quick Start - AIO Data Flows Integration

**Service Endpoint:**
```
http://lerobot-telemetry.default.svc.cluster.local:8080
```

**Usage:**
1. Poll the `/signals` endpoint to get real-time USB data
2. Process the signals through your AIO Data Flows pipeline
3. The service returns JSON with current robot arm positions and states

**Example Data Flow Source Configuration:**
```yaml
source:
  endpoint: http://lerobot-usb-listener.default.svc.cluster.local:8080/signals
  method: GET
  pollInterval: 100ms  # 10Hz sampling rate
```

## Prerequisites

### Common Requirements
- SO101 follower and leader arms connected via USB
- **Motor calibration files must be generated first:**
  - Run `03_configure_follower.py` (creates `configs/my_awesome_follower_arm.json`)
  - Run `04_configure_leader.py` (creates `configs/my_awesome_leader_arm.json`)

### For Docker Compose
- Docker and Docker Compose installed

### For Kubernetes (AIO environments)
- Kubernetes cluster (K3s, AKS Edge Essentials, or Azure IoT Operations)
- kubectl configured
- USB devices accessible on the target node
- AKRI configured for asset discovery (optional)

## Deployment Options

### Option 1: Kubernetes Deployment (Recommended for AIO)

This deployment exposes USB device signals via HTTP for Azure IoT Operations Data Flows.

**Prerequisites:**
1. Update the nodeSelector in `k8s-deployment.yaml` with your node name:
```bash
kubectl get nodes  # Find your node name
# Edit k8s-deployment.yaml and replace REPLACE_WITH_YOUR_NODE_NAME
```

**ACreate the ServiceAccount (if not already created):
```bash
kubectl apply -f serviceaccount.yaml
```

2. utomated deployment using the provided script:**

```bash
# On Linux/Mac
chmod +x k8s-deploy.sh
./k8s-deploy.sh

# On Windows (PowerShell)
.\k8s-deploy.ps1
2. Build the container image:
```bash
docker build -f containers/teleoperate_mqtt/Dockerfile -t lerobot-telemetry:latest .
```

3. Create the ConfigMaps:
```bash
kubectl create configmap lerobot-config --from-file=local_configurations.yaml -n default
kubectl create configmap lerobot-calibration --from-file=../../lerobot-edge/configs/ -n default
```

4. Deploy to Kubernetes:
```bash
kubectl apply -f k8s-deployment.yaml
```

5. Check status:
```bash
kubectl get pods -n default -l app=lerobot-telemetry
kubectl logs -f -n default -l app=lerobot-telemetry
```

6. Test the HTTP endpoint:
```bash
kubectl port-forward service/lerobot-telemetry 8080:8080 -n default
curl http://localhost:8080/signals
```

**Update calibration files after changes:**
```bash
kubectl create configmap lerobot-calibration --from-file=../../lerobot-edge/configs/ -n default --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deployment/lerobot-telemetry -n default
```

## HTTP API Endpoints

The container exposes the following endpoints for Data Flows integration:

- `GET /health` - Health check endpoint
- `GET /ready` - Readiness check (returns 200 when both USB devices connected)
- `GET /signals` - Current USB device signals in JSON format

Example response from `/signals`:
```json
{
  "follower_connected": true,
  "leader_connected": true,
  "last_action": [0.1, 0.2, 0.3, 0.4, 0.5, 0.6],
  "last_update": 1706342400.123
}
```

## Azure IoT Operations Data Flows Integration

**Service Endpoint:** `http://lerobot-telemetry.default.svc.cluster.local:8080`

### Integration Steps:

1. **Deploy this container** using the instructions below
2. **Configure your Data Flow** to poll the `/signals` endpoint
3. **Process the USB data** through your AIO Data Flows pipeline
4. The container is marked with `aio.akri.sh/asset: "true"` for AKRI discovery

### Data Flow Configuration Example:

```yaml
apiVersion: connectivity.iotoperations.azure.com/v1beta1
kind: DataFlow
metadata:
  name: lerobot-telemetry-dataflow
spec:
  source:
    type: http
    endpoint: http://lerobot-telemetry.default.svc.cluster.local:8080/signals
    pollIntervalMs: 100  # Poll every 100ms for real-time data
  destinations:
    - type: mqtt
      topic: lerobot/telemetry
  transformations:
    - type: enrichment
      # Add your transformations here
```

### Available Data:

The `/signals` endpoint returns:
```json
{
  "follower_connected": true,
  "leader_connected": true,
  "last_action": [0.1, 0.2, 0.3, 0.4, 0.5, 0.6],  // 6-DOF joint positions
  "last_update": 1706342400.123  // Unix timestamp
}
```

**Update calibration files after changes:**
```bash
kubectl create configmap lerobot-calibration --from-file=../../lerobot-edge/configs/ -n lerobot --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deployment/teleoperate-mqtt -n lerobot
```

**Undeploy:**
```bash
kubectl delete -f k8s-deployment.yaml
# Or use the cleanup script
./k8s-undeploy.sh
```

### Option 2: Docker Compose

**Build and run:**
```bash
cd containers/teleoperate_mqtt
docker-compose up
```

To run in detached mode:
```bash
docker-compose up -d
```

To stop:
```bash
docker-compose down
```

### Option 3: Docker Run

```bash
docker build -f containers/teleoperate_mqtt/Dockerfile -t lerobot-telemetry .
docker run -it --rm \
  --privileged \
  --device=/dev/ttyACM0 \
  --device=/dev/ttyACM1 \
  -v $(pwd)/local_configurations.yaml:/app/local_configurations.yaml:ro \
  -v $(pwd)/../../lerobot-edge/configs:/app/configs:ro \
  lerobot-telemetry
```

## Configuration

### USB Ports
Edit `local_configurations.yaml` to set the correct USB ports:

```yaml
follower_port: "/dev/ttyACM0"
leader_port: "/dev/ttyACM1"
```

### Motor Calibration Files

The container expects calibration JSON files generated by scripts 03 and 04. There are two approaches:

**Option 1: Mount the lerobot-edge/configs directory (Recommended)**

This is already configured in `docker-compose.yml`:
```yaml
volumes:
  - ../../lerobot-edge/configs:/app/configs:ro
environment:
  - HF_LEROBOT_CALIBRATION=/app/configs
```

The container will look for:
- `/app/configs/my_awesome_follower_arm.json`
- `/app/configs/my_awesome_leader_arm.json`

**Option 2: Use default cache location**

Comment out the `HF_LEROBOT_CALIBRATION` environment variable and mount your home cache:
```yaml
volumes:
  - ~/.cache/huggingface/lerobot/calibration:/home/lerobot/.cache/huggingface/lerobot/calibration:ro
```

The container will look in the default location:
- `Kubernetes-Specific Notes

### USB Device Access
The deployment uses `privileged: true` and mounts `/dev` from the host. For production environments, consider using:
- USB device plugins for Kubernetes
- Node affinity to ensure the pod runs on the correct node with USB devices

### Node Selection
**REQUIRED**: USB devices are connected to a specific node. Update the nodeSelector in `k8s-deployment.yaml`:
```yaml
nodeSelector:
  kubernetes.io/hostname: your-actual-node-name
```

Find your node name with: `kubectl get nodes`
as an AKRI connector for Azure IoT Operations:
- Runs in the `default` namespace alongside other AIO workloads
- Exposes USB signals via HTTP for Data Flows
- Uses ConfigMaps for configuration updates without rebuilds
- Supports host network for direct USB device access
- Includes liveness and readiness probes
- Marked with AKRI labels for asset discovery
- Service endpoint: `http://lerobot-telemetry.default.svc.cluster.local:8080`s
- `lerobot/teleoperate/action` - Real-time action data
- `lerobot/teleoperate/state` - Robot state information

## Future Enhancements

- [ ] MQTT client integration
- [ ] Remote teleoperation over MQTT
- [ ] WebSocket support for real-time streaming
- [ ] gRPC endpoint for high-performance data transfer
- [ ] Metrics export (Prometheus format)
- [ ] USB device plugin for better device management
- [ ] AKRI configuration for automatic discovery
   ```bash
   ls -la /dev/ttyACM*
   ```

2. Ensure devices have proper permissions:
   ```bash
   sudo chmod 666 /dev/ttyACM0 /dev/ttyACM1
   ```

3. Update `docker-compose.yml` with correct device paths

### Permission Denied

The container needs privileged access for USB devices. Make sure:
- `privileged: true` is set in docker-compose.yml
- Or use `--privileged` flag with docker run

### Container Exits Immediately

Check logs:
```bash
docker-compose logs
```

Or for docker run:
```bash
docker logs lerobot-teleoperate-mqtt
```

## Future Enhancements

- [ ] MQTT client integration
- [ ] Remote teleoperation over MQTT
- [ ] Health monitoring and status reporting
- [ ] Configuration via environment variables
