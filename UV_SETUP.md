# UV Setup Guide for LeRobot

This guide covers installation and usage of UV, the fast Python package manager for LeRobot.

## Why UV?

- ⚡ **10-100x faster** than pip/conda
- 📦 **Smaller footprint** - perfect for edge devices
- 🔒 **Better dependency resolution** with lock files
- 🎯 **Pip-compatible** - works with PyPI

---

## Installation

### Windows (Development Machine)

```powershell
# Option 1: Via pip (if you have Python)
pip install uv

# Option 2: Standalone installer
irm https://astral.sh/uv/install.ps1 | iex

# Verify installation
uv --version
```

### Linux/Mac (Edge Device)

```bash
# Install UV
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add to PATH (add to ~/.bashrc for persistence)
export PATH="$HOME/.cargo/bin:$PATH"

# Verify installation
uv --version
```

---

## Quick Start

### For Edge Devices (Robot Control Only)

```bash
# Clone the repository
git clone https://github.com/huggingface/lerobot.git
cd lerobot

# Create virtual environment
uv venv

# Activate environment
source .venv/bin/activate  # Linux/Mac
# or
.venv\Scripts\activate     # Windows

# Install edge dependencies only
uv pip install -r requirements-edge.txt

# Or install with edge optional dependencies
uv pip install -e ".[edge]"

# Configure your robot
nano local_configurations.yaml

# Run setup scripts
python 01_setup_motors_follower.py
python 02_setup_motors_leader.py
```

### For Cloud/Training (Full ML Stack)

```bash
# Create virtual environment
uv venv

# Activate environment
source .venv/bin/activate  # Linux/Mac

# Install all dependencies
uv pip install -e ".[all]"

# Verify GPU access (if available)
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

---

## Common UV Commands

### Environment Management

```bash
# Create new virtual environment
uv venv

# Create with specific Python version
uv venv --python 3.10

# Activate environment
source .venv/bin/activate  # Linux/Mac
.venv\Scripts\activate     # Windows

# Deactivate
deactivate
```

### Package Installation

```bash
# Install from pyproject.toml
uv pip install -e .

# Install with optional dependencies
uv pip install -e ".[edge]"      # Edge only
uv pip install -e ".[all]"       # Full stack
uv pip install -e ".[dev]"       # Development tools

# Install from requirements file
uv pip install -r requirements-edge.txt

# Install specific package
uv pip install numpy opencv-python
```

### Package Management

```bash
# List installed packages
uv pip list

# Show package info
uv pip show torch

# Uninstall package
uv pip uninstall package-name

# Freeze dependencies
uv pip freeze > requirements.txt

# Sync with lock file (if uv.lock exists)
uv pip sync
```

---

## Edge Device Optimization

### Minimal Installation (for constrained devices)

```bash
# Install without cache to save space
uv pip install --no-cache-dir -r requirements-edge.txt

# Use binary wheels only (no compilation)
uv pip install --only-binary :all: opencv-python

# Check environment size
du -sh .venv/  # Linux/Mac
```

### Cleanup

```bash
# Remove cache
rm -rf ~/.cache/uv  # Linux/Mac
rmdir /s %USERPROFILE%\.cache\uv  # Windows

# Remove virtual environment
rm -rf .venv/  # Linux/Mac
rmdir /s .venv  # Windows
```

---

## Troubleshooting

### UV not found after installation

**Linux/Mac:**
```bash
# Add to PATH
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Windows:**
- Restart your terminal/PowerShell
- Or manually add to PATH via System Environment Variables

### Slow installation on edge device

```bash
# Use local PyPI mirror if available
uv pip install --index-url http://local-mirror/simple/ -r requirements-edge.txt

# Or install without building from source
uv pip install --only-binary :all: -r requirements-edge.txt
```

### Missing scservo_sdk / motor SDK

```bash
# Install the Feetech motor SDK
uv pip install SCServo_Python

# Or for Dynamixel motors
uv pip install dynamixel-sdk
```

### Limited disk space

```bash
# Install without cache
uv pip install --no-cache-dir -e ".[edge]"

# Clean up after installation
rm -rf ~/.cache/uv
```

---

## Migrating from Conda

If you're currently using conda:

```bash
# Deactivate conda environment
conda deactivate

# Install UV
pip install uv  # or use standalone installer

# Create UV environment
uv venv

# Activate UV environment
source .venv/bin/activate

# Install dependencies
uv pip install -e ".[edge]"  # or [all]
```

---

## Project Structure with UV

```
lerobot/
├── .venv/                      # Virtual environment (gitignored)
├── uv.lock                     # Dependency lock file (gitignored)
├── pyproject.toml              # Project config with dependencies
├── requirements-edge.txt       # Edge-only dependencies
├── requirements-ubuntu.txt     # Full dependencies (Ubuntu)
├── requirements-macos.txt      # Full dependencies (macOS)
├── 01-04_*.py                  # Setup scripts
├── local_configurations.yaml   # User config
└── src/lerobot/                # Source code
```

---

## Performance Comparison

| Operation | Conda | UV | Speedup |
|-----------|-------|-----|---------|
| Create env | 2-5 min | 5-10 sec | 10-30x |
| Install edge deps | 10-15 min | 30-60 sec | 10-15x |
| Install full deps | 30-45 min | 3-5 min | 10x |
| Disk space (edge) | ~8-10 GB | ~200-300 MB | 30x smaller |

---

## Next Steps

1. **For Edge Development**: Use `requirements-edge.txt` or `pyproject.toml` with `[edge]` extras
2. **For Cloud/Training**: Use `[all]` extras for complete ML stack
3. **For Contributing**: Use `[dev]` extras for development tools

For more information, see:
- UV Documentation: https://docs.astral.sh/uv/
- LeRobot Documentation: https://github.com/huggingface/lerobot
- Separation of Concerns Doc: `separation_of_concerns.md`
