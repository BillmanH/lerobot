# LeRobot Separation of Concerns: Edge vs Cloud Architecture

**Document Version:** 1.0  
**Date:** December 19, 2025  
**Status:** Planning Phase

## Executive Summary

This document outlines the strategy for splitting the LeRobot library into two distinct modules:
- **lerobot-edge**: Lightweight runtime for robot control on edge devices
- **lerobot-cloud**: Full-featured environment for training, evaluation, and data processing

The goal is to create separation of concerns that allows edge devices to run robot control without heavy dependencies like PyTorch, while maintaining all training and ML capabilities in the cloud module.

---

## Current Architecture Analysis

### Heavy Dependencies (Cloud-Only)
The following dependencies are identified as "heavy" and only needed for training/evaluation:

1. **PyTorch/Torchvision** - Deep learning framework (~2GB+ with dependencies)
   - Used in: `policies/`, `scripts/train.py`, `processor/`, `utils/`
   - Required for: Model training, inference, dataset processing

2. **HuggingFace Ecosystem** - Transformers, Datasets, Hub
   - Used throughout for model loading, dataset management
   - Required for: Pretrained models, dataset downloads, model versioning

3. **Training Infrastructure**
   - Optimizers, schedulers, gradient scaling
   - Wandb/tensorboard for logging
   - Distributed training utilities

4. **Advanced Image Processing**
   - Complex transformations and augmentations
   - Video processing and encoding
   - Dataset visualization tools

### Lightweight Core (Edge-Only)
Essential components needed for robot operation:

1. **Motor Control** (`motors/`)
   - ✅ No torch dependencies found
   - Direct hardware communication
   - Motor calibration and configuration

2. **Camera Interface** (`cameras/`)
   - ✅ No torch dependencies found
   - Basic frame capture
   - Camera configuration

3. **Robot Abstractions** (`robots/`)
   - ✅ Minimal dependencies
   - Robot-specific implementations (SO101, SO100, etc.)
   - Configuration management

4. **Basic Utilities**
   - Port finding (`find_port.py`)
   - Camera enumeration (`find_cameras.py`)
   - Error definitions (`errors.py`)
   - Constants (`constants.py`)

5. **Control Scripts**
   - `setup_motors.py`
   - `calibrate.py`
   - `teleoperate.py`
   - `record.py` (edge version - basic recording)
   - `replay.py` (edge version - action replay)

---

## Proposed Module Structure

### lerobot-edge

```
lerobot-edge/
├── setup.py / pyproject.toml
├── requirements-edge.txt
├── README-edge.md
├── 01_setup_motors_follower.py    # Root-level setup scripts
├── 02_setup_motors_leader.py      # (convenience scripts for users)
├── 03_configure_follower.py
├── 04_configure_leader.py
├── local_configurations.yaml       # User config file
└── src/
    └── lerobot_edge/
        ├── __init__.py
        ├── __version__.py
        ├── constants.py
        ├── errors.py
        ├── find_port.py
        ├── find_cameras.py
        ├── motors/              # Complete motor control
        │   ├── __init__.py
        │   ├── feetech/
        │   ├── dynamixel/
        │   └── utils.py
        ├── cameras/             # Basic camera capture
        │   ├── __init__.py
        │   ├── opencv.py
        │   ├── utils.py
        │   └── configs.py
        ├── robots/              # Robot implementations
        │   ├── __init__.py
        │   ├── robot.py
        │   ├── config.py
        │   ├── utils.py
        │   ├── so101_follower/
        │   ├── so100_follower/
        │   └── [other robots]/
        ├── control/             # Renamed/simplified scripts
        │   ├── setup_motors.py
        │   ├── calibrate.py
        │   ├── teleoperate.py
        │   ├── record.py        # Simplified, no torch
        │   └── replay.py        # Simplified action replay
        ├── teleoperators/       # Teleoperation interfaces
        │   └── __init__.py
        ├── transport/           # Data serialization/communication
        │   └── __init__.py
        └── utils/               # Minimal utilities only
            ├── __init__.py
            └── robot_utils.py
```

**Key Dependencies (Edge):**
- numpy (for basic array operations)
- opencv-python (camera capture)
- pyserial (motor communication)
- pyyaml (configuration)
- pyusb (USB device access)
- draccus (configuration management)

**Estimated Size:** ~200-300MB with dependencies

### lerobot-cloud

```
lerobot-cloud/
├── setup.py / pyproject.toml
├── requirements-cloud.txt
├── README-cloud.md
└── src/
    └── lerobot/              # Keep original name
        ├── __init__.py
        ├── __version__.py
        ├── [all current files]
        ├── policies/         # All ML policies
        ├── datasets/         # Dataset management
        ├── envs/            # Simulation environments
        ├── model/           # Model architectures
        ├── processor/       # Data processing
        ├── optim/           # Optimizers
        ├── scripts/         # Training/eval scripts
        │   ├── train.py
        │   ├── eval.py
        │   └── server/
        └── utils/           # Full utilities
```

**Key Dependencies (Cloud):**
- torch + torchvision
- transformers
- datasets (HuggingFace)
- All current dependencies from requirements.in

**Estimated Size:** 5-10GB+ with dependencies

---

## Shared Components Strategy

### Option A: Duplication (Recommended for Phase 1)
- Duplicate lightweight components in both modules
- Pros: Complete independence, no cross-dependencies
- Cons: Code duplication, need to sync bug fixes

### Option B: Common Core Package
- Create `lerobot-common` with shared code
- Both edge and cloud depend on it
- Pros: DRY principle, single source of truth
- Cons: Adds dependency management complexity

### Option C: Code Generation
- Generate edge code from cloud codebase automatically
- Strip out heavy dependencies programmatically
- Pros: No duplication, single codebase
- Cons: Complex build process, testing challenges

**Recommendation:** Start with **Option A** for simplicity, migrate to **Option B** once stable.

---

## Migration Strategy

### Phase 0: Migrate from Conda to UV (Week 0)

**Rationale:** UV is a fast, modern Python package manager that's ideal for both edge and cloud deployments. It's faster than conda, has better dependency resolution, and creates lighter environments perfect for edge devices.

1. **Install UV**
   
   **On Edge Device (Bash):**
   ```bash
   # Install uv
   curl -LsSf https://astral.sh/uv/install.sh | sh
   
   # Add to PATH (add to ~/.bashrc or ~/.zshrc for persistence)
   export PATH="$HOME/.cargo/bin:$PATH"
   
   # Verify installation
   uv --version
   ```
   
   **On Cloud/Development Machine (Windows PowerShell):**
   ```powershell
   # Install uv via pip or standalone installer
   pip install uv
   # Or use: irm https://astral.sh/uv/install.ps1 | iex
   
   # Verify installation
   uv --version
   ```

2. **Convert Project Structure**
   - [ ] Create `pyproject.toml` for both edge and cloud modules
   - [ ] Remove conda `environment.yml` files (or deprecate)
   - [ ] Update `.gitignore` for UV cache (`.venv/`, `uv.lock`)
   - [ ] Document UV workflow in README

3. **Create UV Configuration**
   
   **For Edge Module** (`lerobot-edge/pyproject.toml`):
   ```toml
   [project]
   name = "lerobot-edge"
   version = "0.1.0"
   description = "Lightweight robot control for edge devices"
   requires-python = ">=3.9"
   dependencies = [
       "numpy>=1.24.0",
       "opencv-python>=4.8.0",
       "pyserial>=3.5",
       "pyyaml>=6.0",
       "draccus>=0.7.0",
   ]
   
   [build-system]
   requires = ["hatchling"]
   build-backend = "hatchling.build"
   ```
   
   **For Cloud Module** (`lerobot-cloud/pyproject.toml`):
   ```toml
   [project]
   name = "lerobot"
   version = "2.0.0"
   description = "Robot learning toolkit - Cloud/Training module"
   requires-python = ">=3.9"
   dependencies = [
       "torch>=2.0.0",
       "torchvision>=0.15.0",
       "transformers>=4.30.0",
       # ... all current dependencies
   ]
   ```

4. **Setup Development Environments**
   
   **Edge Development (Bash):**
   ```bash
   # Navigate to edge module
   cd lerobot-edge
   
   # Create virtual environment and install dependencies
   uv venv
   source .venv/bin/activate
   
   # Install in development mode
   uv pip install -e .
   
   # Verify installation
   python -c "import lerobot_edge; print('Edge module ready!')"
   ```
   
   **Cloud Development (PowerShell/Bash):**
   ```bash
   # Navigate to cloud module
   cd lerobot-cloud
   
   # Create virtual environment
   uv venv
   source .venv/bin/activate  # or .venv\Scripts\activate on Windows
   
   # Install with all dependencies
   uv pip install -e ".[all]"
   
   # Verify installation
   python -c "import lerobot; print('Cloud module ready!')"
   ```

5. **Benefits of UV Migration**
   - ⚡ **10-100x faster** than pip/conda for installations
   - 📦 **Smaller disk footprint** - no conda base environment overhead
   - 🔒 **Better dependency locking** with `uv.lock`
   - 🎯 **Perfect for edge devices** - minimal resource usage
   - 🔄 **Compatible with pip** - can still use PyPI packages
   - 🚀 **Fast cold starts** - ideal for edge deployment

6. **Migration Checklist**
   - [ ] Install UV on all development machines
   - [ ] Create `pyproject.toml` for current monorepo
   - [ ] Test UV installation with current codebase
   - [ ] Document UV commands in README
   - [ ] Update CI/CD to use UV instead of conda
   - [ ] Create UV-based Docker images

### Phase 1: Edge Module Creation (Weeks 1-2)

1. **Setup Package Structure**
   - [ ] Create `lerobot-edge/` directory
   - [ ] Setup `pyproject.toml` with UV-compatible configuration
   - [ ] Create UV virtual environment

2. **Copy Core Components**
   - [ ] Copy `motors/` (verify no torch imports)
   - [ ] Copy `cameras/` (basic implementation only)
   - [ ] Copy `robots/` (strip any ML-related code)
   - [ ] Copy `teleoperators/` (for leader-follower setup)
   - [ ] Copy essential utilities

3. **Migrate Root-Level Setup Scripts**
   - [ ] Copy `01_setup_motors_follower.py` to edge root
   - [ ] Copy `02_setup_motors_leader.py` to edge root
   - [ ] Copy `03_configure_follower.py` to edge root
   - [ ] Copy `04_configure_leader.py` to edge root
   - [ ] Copy `local_configurations.yaml` template to edge root
   - [ ] Update import paths in scripts (lerobot → lerobot_edge)
   - [ ] Verify all scripts work with edge-only dependencies

4. **Create Simplified Control Scripts (in src/lerobot_edge/control/)**
   - [ ] Adapt `setup_motors.py` for edge
   - [ ] Adapt `calibrate.py` for edge
   - [ ] Create basic `record.py` (data collection without processing)
   - [ ] Create basic `replay.py` (action playback)
   - [ ] Simplify `teleoperate.py`

4. **Testing**
   - [ ] Test motor control on target edge device
   - [ ] Test camera capture
   - [ ] Verify all imports work without torch
   - [ ] Test root-level setup scripts (01-04) on edge device
   - [ ] Test complete workflow: setup → calibrate → record → replay
   - [ ] Verify `local_configurations.yaml` works correctly

### Phase 2: Cloud Module Refinement (Weeks 3-4)

1. **Package Current Codebase**
   - [ ] Rename to `lerobot-cloud` (or keep as `lerobot`)
   - [ ] Create `pyproject.toml` with full dependencies
   - [ ] Setup UV environment for cloud development
   - [ ] Update documentation
   - [ ] Add edge module as optional dependency for testing

2. **Create Integration Interface**
   - [ ] Design data format for edge→cloud data transfer
   - [ ] Create validation tools
   - [ ] Document data pipeline

3. **Testing**
   - [ ] Verify all existing functionality works
   - [ ] Test training with edge-collected data
   - [ ] Verify model export for edge inference (if needed)

### Phase 3: Integration & Documentation (Week 5)

1. **End-to-End Workflow**
   - [ ] Document edge deployment process with UV
   - [ ] Document data collection workflow
   - [ ] Document training workflow
   - [ ] Create example projects
   - [ ] Create UV-based quickstart guides

2. **Optimization**
   - [ ] Profile edge module size with UV environment
   - [ ] Identify and remove unnecessary dependencies
   - [ ] Optimize startup time
   - [ ] Compare UV vs conda performance metrics

3. **CI/CD**
   - [ ] Setup separate tests for edge/cloud
   - [ ] Create docker images using UV for both
   - [ ] Setup automated releases with UV build
   - [ ] Migrate GitHub Actions from conda to UV

---

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      EDGE DEVICE (Robot)                     │
├─────────────────────────────────────────────────────────────┤
│  lerobot-edge:                                              │
│    • Motor Control                                          │
│    • Camera Capture                                         │
│    • Teleoperation                                          │
│    • Basic Recording (raw data)                             │
│    • Action Replay                                          │
│                                                             │
│  Output: Raw episodes (actions, observations, metadata)     │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ Transfer (USB/Network/Cloud Storage)
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                    CLOUD/SERVER (Training)                   │
├─────────────────────────────────────────────────────────────┤
│  lerobot-cloud:                                             │
│    • Dataset Processing & Validation                        │
│    • Data Augmentation                                      │
│    • Model Training (PyTorch)                               │
│    • Evaluation & Visualization                             │
│    • Model Versioning & Export                              │
│                                                             │
│  Output: Trained models, metrics, visualizations            │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ Optional: Deploy policy
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              EDGE DEVICE (Autonomous Operation)              │
├─────────────────────────────────────────────────────────────┤
│  Optional lerobot-edge-inference:                           │
│    • Lightweight inference (ONNX/TFLite/quantized)          │
│    • Or: Remote inference via API                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Configuration Management

### Edge Configuration
```yaml
# edge_config.yaml
robot:
  type: "so101_follower"
  port: "/dev/ttyACM0"
  calibration_dir: "./calibrations"

cameras:
  wrist:
    index: 0
    width: 640
    height: 480
    fps: 30

recording:
  output_dir: "./episodes"
  fps: 30
  episode_buffer_size: 1000

teleoperation:
  leader_port: "/dev/ttyACM1"
  control_frequency: 50
```

### Cloud Configuration
Keep existing configuration system but add:
```yaml
# cloud_config.yaml
data:
  edge_data_dir: "./edge_episodes"
  processed_data_dir: "./datasets"
  validation_rules: "strict"

training:
  # Existing training config
  ...
```

---

## API Compatibility

### Edge API (Public Interface)
```python
# Essential for edge usage
from lerobot_edge.robots import SO101Follower, SO101FollowerConfig
from lerobot_edge.motors import MotorCalibration
from lerobot_edge.cameras import OpenCVCamera
from lerobot_edge.control import setup_motors, calibrate, record, replay
from lerobot_edge.teleoperators import BimanualTeleoperator

# Root-level convenience scripts (users can run directly):
# python 01_setup_motors_follower.py
# python 02_setup_motors_leader.py
# python 03_configure_follower.py
# python 04_configure_leader.py
```

### Cloud API (Public Interface)
```python
# Everything from edge, plus:
from lerobot.policies import ACTPolicy
from lerobot.datasets import LeRobotDataset
from lerobot.scripts import train, evaluate
from lerobot.envs import make_env
```

### Migration Path for Existing Code
- **Scripts using only robot control** → Minimal changes:
  - Update imports: `from lerobot.robots` → `from lerobot_edge.robots`
  - Root scripts (01-04) remain at root level with updated imports
  - `local_configurations.yaml` stays at root for easy access
- **Scripts using ML features** → Use `lerobot-cloud`, no changes needed
- **Mixed scripts** → Separate into edge and cloud components

---

## Deployment Scenarios

### Scenario 1: Pure Edge (Data Collection)
**Hardware:** Raspberry Pi 4, Jetson Nano, or similar  
**Software:** lerobot-edge only  
**Package Manager:** UV  
**Use Case:** Teleoperation and data collection

**Setup Commands (Bash):**
```bash
# On fresh edge device
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"

# Clone and setup
git clone https://github.com/yourusername/lerobot-edge.git
cd lerobot-edge

# Create environment and install
uv venv
source .venv/bin/activate
uv pip install -e .

# Verify installation
python -c "import lerobot_edge; print('Ready!')"

# Configure your robot ports
nano local_configurations.yaml  # Edit follower_port and leader_port

# Run setup scripts
python 01_setup_motors_follower.py
python 02_setup_motors_leader.py
python 03_configure_follower.py
python 04_configure_leader.py
```

**Workflow:**
1. Setup and calibrate robot using root scripts (01-04)
2. Teleoperate to collect demonstrations
3. Save episodes to storage
4. Transfer to cloud for training

### Scenario 2: Cloud Training
**Hardware:** GPU workstation or cloud instance  
**Software:** lerobot-cloud  
**Package Manager:** UV  
**Use Case:** Model training and evaluation

**Setup Commands:**
```bash
# On cloud/workstation
pip install uv  # or use installer

# Clone and setup
git clone https://github.com/yourusername/lerobot.git
cd lerobot

# Create environment with GPU support
uv venv
source .venv/bin/activate
uv pip install -e ".[all]"

# Verify GPU access
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"
```

**Workflow:**
1. Load episodes from edge device
2. Process and augment data
3. Train policy
4. Evaluate and visualize

### Scenario 3: Hybrid (Edge Inference)
**Hardware:** More powerful edge device (Jetson Xavier, etc.)  
**Software:** lerobot-edge + lightweight inference runtime  
**Package Manager:** UV  
**Use Case:** Autonomous robot operation

**Setup Commands (Bash):**
```bash
# Install edge module
uv venv
source .venv/bin/activate
uv pip install -e ".[inference]"  # With ONNX runtime

# Download trained model
python -m lerobot_edge.download_model --model-id "your-model"
```

**Workflow:**
1. Deploy trained model to edge
2. Run inference locally
3. Execute actions on robot

---

## Testing Strategy

### Edge Module Tests
```python
# tests/test_edge_motors.py
def test_motor_connection():
    """Test motor connection without torch"""
    pass

# tests/test_edge_cameras.py
def test_camera_capture():
    """Test camera capture without torch"""
    pass

# tests/test_edge_recording.py
def test_record_episode():
    """Test episode recording without ML processing"""
    pass
```

### Integration Tests
```python
# tests/test_integration.py
def test_edge_to_cloud_data_format():
    """Verify edge data can be loaded by cloud"""
    pass

def test_cloud_trained_model_export():
    """Verify cloud models can be exported for edge"""
    pass
```

### Continuous Integration
- Edge tests run on lightweight runner (no GPU)
- Cloud tests run on GPU-enabled runner
- Cross-compatibility tests run on both

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Code duplication leads to bugs | High | Establish sync process, automated testing |
| Breaking changes in edge affect cloud | Medium | Versioned data format, compatibility tests |
| Edge module still too heavy | High | Regular profiling, dependency audits |
| Incompatible data formats | High | Strict schema validation, migration tools |
| Community confusion about which to use | Medium | Clear documentation, decision tree |

---

## Success Metrics

### Edge Module
- [ ] Package size < 300MB with dependencies
- [ ] Memory usage < 500MB during operation
- [ ] Startup time < 5 seconds
- [ ] Works on Raspberry Pi 4 / Jetson Nano
- [ ] No torch dependencies

### Cloud Module
- [ ] All existing functionality preserved
- [ ] Can process edge-collected data
- [ ] Training performance unchanged
- [ ] Clear upgrade path documented

### Integration
- [ ] End-to-end workflow documented
- [ ] Sample data collection + training project
- [ ] < 5 steps to go from edge data to trained model

---

## Open Questions

1. **Inference on Edge**: Do we need a third module `lerobot-edge-inference` for running trained models on edge devices?
   - Options: ONNX, TensorRT, TFLite, or remote API calls

2. **Configuration Compatibility**: Should edge and cloud share configuration format?
   - Recommendation: Compatible subset, cloud is superset of edge

3. **Version Synchronization**: How to ensure edge data is compatible with cloud versions?
   - Recommendation: Semantic versioning + data format version field

4. **Package Naming**: Should cloud keep name `lerobot` or rename to `lerobot-cloud`?
   - Recommendation: Keep `lerobot` for cloud (default), `lerobot-edge` is specialized

5. **Backwards Compatibility**: How to handle existing users?
   - Recommendation: `lerobot` becomes alias for `lerobot-cloud`, deprecation warnings for edge usage

---

## Next Steps

### Immediate Actions (This Week)
1. Review and approve this document
2. **Install UV** on development and edge machines
3. **Create initial `pyproject.toml`** for current monorepo
4. **Test UV workflow** with existing codebase
5. Create feature branch: `feature/edge-cloud-separation`
6. Setup basic `lerobot-edge/` directory structure
7. Inventory all imports and dependencies in core modules

### Short Term (Next 2 Weeks)
1. Complete Phase 0: UV migration
2. Implement Phase 1: Edge module creation
3. Test on actual edge hardware with UV environment
4. Document any blockers or issues
5. Create UV-based installation guides

### Medium Term (Weeks 3-5)
1. Implement Phase 2: Cloud module refinement
2. Implement Phase 3: Integration and documentation
3. Create example workflows with UV commands
4. Performance benchmarks: UV vs conda

### Long Term
1. Community feedback and iteration
2. Consider `lerobot-edge-inference` if needed
3. Optimize and stabilize both modules
4. Publish to PyPI for easy `uv pip install lerobot-edge`

---

## References

- Current codebase: `c:\Users\willi\repos\lerobot`
- Similar projects: ROS1 vs ROS2, TensorFlow vs TensorFlow Lite
- Edge ML frameworks: ONNX Runtime, TensorRT, TFLite
- **UV Documentation**: https://docs.astral.sh/uv/
- **UV vs Conda Performance**: https://astral.sh/blog/uv
- **UV GitHub**: https://github.com/astral-sh/uv

---

## Appendix A: Dependency Analysis

### Current Heavy Dependencies (Conda)
```
torch>=2.0.0
torchvision>=0.15.0
transformers>=4.30.0
datasets>=2.13.0
huggingface_hub>=0.15.0
wandb>=0.15.0
```

### Proposed Edge Dependencies (UV)
```toml
# pyproject.toml
dependencies = [
    "numpy>=1.24.0",
    "opencv-python>=4.8.0",
    "pyserial>=3.5",
    "pyyaml>=6.0",
    "draccus>=0.7.0",
]
```

### Size Comparison
- Current install (conda): ~8-10GB
- Proposed edge (UV): ~200-300MB
- **Reduction: ~97%**

### Installation Speed Comparison (Estimated)
- Conda: ~10-15 minutes (edge), ~30-45 minutes (cloud)
- UV: ~30-60 seconds (edge), ~3-5 minutes (cloud)
- **Speed improvement: 10-20x faster**

---

## Appendix B: File Organization Checklist

### Files for Edge Module
- [x] `motors/` - No torch dependencies ✅
- [x] `cameras/` - No torch dependencies ✅
- [x] `robots/` - Minimal dependencies ✅
- [x] `teleoperators/` - Leader-follower control ✅
- [x] Core utilities (find_port, find_cameras, etc.) ✅
- [x] Root setup scripts (01-04) ✅
- [x] `local_configurations.yaml` ✅
- [ ] Simplified recording/replay
- [ ] Basic teleoperation
- [ ] UV `pyproject.toml` configuration

### Files for Cloud Module Only
- [x] `policies/` - Heavy torch usage
- [x] `datasets/` - HuggingFace datasets
- [x] `envs/` - Simulation environments
- [x] `scripts/train.py` - Training infrastructure
- [x] `processor/` - Data processing with torch
- [x] `model/` - Model architectures
- [ ] UV `pyproject.toml` with full dependencies

### Shared/Need Review
- [ ] `transport/` - Data serialization (evaluate for edge)
- [ ] `utils/` - Split into edge and cloud utils
- [ ] `teleoperators/` - May need simplification for edge

### UV Migration Checklist
- [ ] Install UV on all development machines
- [ ] Install UV on edge devices (bash script)
- [ ] Create root `pyproject.toml` for current monorepo
- [ ] Test UV with current dependencies
- [ ] Create `.gitignore` entries for `.venv/` and `uv.lock`
- [ ] Update CI/CD workflows to use UV
- [ ] Create UV-based Docker images
- [ ] Document UV commands in all READMEs
- [ ] Create UV troubleshooting guide

---

## Appendix C: UV Quick Reference

### Essential UV Commands

**Environment Management:**
```bash
# Create virtual environment
uv venv

# Activate environment
source .venv/bin/activate  # Linux/Mac
.venv\Scripts\activate     # Windows

# Install dependencies
uv pip install -e .
uv pip install -e ".[dev]"
uv pip install -e ".[all]"

# Install specific package
uv pip install numpy torch
```

**Package Management:**
```bash
# List installed packages
uv pip list

# Freeze dependencies
uv pip freeze > requirements.txt

# Install from requirements
uv pip install -r requirements.txt

# Sync with lock file
uv pip sync
```

**Edge Device Specific:**
```bash
# Fast installation on Raspberry Pi
uv pip install --no-cache-dir -e .

# Install without build dependencies (use wheels)
uv pip install --only-binary :all: opencv-python

# Check environment size
du -sh .venv/
```

**Cloud/Training Specific:**
```bash
# Install with CUDA support
uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118

# Install with all optional dependencies
uv pip install -e ".[all,dev,test]"
```

### UV vs Conda Comparison

| Feature | UV | Conda |
|---------|-------|-------|
| Speed | ⚡ 10-100x faster | Baseline |
| Disk Space | 📦 Minimal (~200MB edge) | Large (~8GB edge) |
| Cross-platform | ✅ Python-focused | ✅ Multi-language |
| Edge-friendly | ✅ Perfect | ⚠️ Too heavy |
| Ecosystem | PyPI | Conda-forge + PyPI |
| Learning Curve | Easy (pip-like) | Moderate |

### Troubleshooting UV on Edge

**Issue: UV not found after install**
```bash
# Add to PATH permanently
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Issue: Slow network on edge device**
```bash
# Use local PyPI mirror or cache
uv pip install --index-url http://local-mirror/simple/ -e .
```

**Issue: Limited disk space**
```bash
# Install without cache
uv pip install --no-cache-dir -e .

# Clean UV cache
rm -rf ~/.cache/uv
```

---

**Document Owner:** Development Team  
**Last Updated:** December 19, 2025  
**Next Review:** After Phase 1 completion
