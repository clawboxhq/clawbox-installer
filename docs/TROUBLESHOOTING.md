# Troubleshooting Guide

Common issues and solutions for NemoClaw macOS installation.

## Table of Contents

1. [Architecture Issues](#architecture-issues)
2. [Prerequisites Issues](#prerequisites-issues)
3. [Homebrew Issues](#homebrew-issues)
4. [Node.js Issues](#nodejs-issues)
5. [Docker Issues](#docker-issues)
6. [OpenShell Issues](#openshell-issues)
7. [NemoClaw Issues](#nemoclaw-issues)
8. [API Key Issues](#api-key-issues)
9. [Sandbox Issues](#sandbox-issues)
10. [Network Issues](#network-issues)

---

## Architecture Issues

### "Unsupported architecture: x86_64"

**Problem**: You're running on an Intel Mac.

**Solution**: Intel Macs (x86_64) are not supported by OpenShell. Options:
- Use a cloud VM with ARM architecture (AWS Graviton, etc.)
- Install standard OpenClaw without sandboxing:
  ```bash
  curl -fsSL https://openclaw.ai/install.sh | bash
  ```

### "Apple Silicon detected but still failing"

**Problem**: Running under Rosetta or in a translated environment.

**Solution**: 
```bash
# Check architecture
uname -m
# Should output: arm64

# If it shows x86_64, you're running in translation
# Run terminal natively (not under Rosetta)
arch -arm64 /bin/bash
```

---

## Prerequisites Issues

### "Insufficient disk space"

**Problem**: Less than 20GB free.

**Solution**:
```bash
# Check disk space
df -h ~

# Clean up Homebrew
brew cleanup --prune=all

# Clean up Docker
docker system prune -a --volumes
```

### "Low memory detected"

**Problem**: Less than 8GB RAM.

**Solution**: Configure swap:
```bash
# Create 8GB swap file (requires sudo)
sudo sysctl vm.swapusage
```

---

## Homebrew Issues

### "Homebrew installation requires an Administrator account"

**Problem**: Current user is not in the admin group.

**Solution**:
```bash
# Have an admin add you to the group
sudo dseditgroup -o edit -a $(whoami) -t user admin

# Sign out and back in, then retry
```

### "brew: command not found"

**Problem**: Homebrew installed but not on PATH.

**Solution**:
```bash
# Add to PATH for current session
eval "$(/opt/homebrew/bin/brew shellenv)"

# Or for zsh permanently
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

---

## Node.js Issues

### "Node.js version < 22"

**Problem**: Old Node.js version installed.

**Solution**:
```bash
# Install Node 22 via Homebrew
brew install node@22
brew link node@22 --force --overwrite

# Verify
node -v  # Should be v22.x.x

# If still showing old version, check PATH
which node
```

### "node: command not found"

**Problem**: Node.js not installed or not on PATH.

**Solution**:
```bash
# Install via Homebrew
brew install node@22

# Link it
brew link node@22 --force --overwrite

# Add to PATH
export PATH="$(brew --prefix node@22)/bin:$PATH"
```

### "npm install fails"

**Problem**: npm cannot install packages.

**Solution**:
```bash
# Clear npm cache
npm cache clean --force

# Update npm
npm install -g npm@latest

# Check for proxy issues
npm config get proxy
npm config get https-proxy
```

---

## Docker Issues

### "Docker did not start within 60 seconds"

**Problem**: Docker Desktop not launching.

**Solution**:
```bash
# Open Docker Desktop manually
open -a Docker

# Check if it's running
docker info

# If stuck, reset Docker
# Docker Desktop > Troubleshoot > Reset
```

### "docker: command not found"

**Problem**: Docker not installed.

**Solution**:
```bash
# Install via Homebrew
brew install --cask docker

# Open it
open -a Docker

# Wait for it to start
```

### "Cannot connect to Docker daemon"

**Problem**: Docker daemon not running.

**Solution**:
```bash
# Start Docker Desktop
open -a Docker

# Wait for daemon
while ! docker info &>/dev/null; do sleep 1; done

# Check Docker Desktop logs
# ~/Library/Containers/com.docker.docker/Data/log/
```

### "Docker out of disk space"

**Problem**: Docker images filling disk.

**Solution**:
```bash
# Clean unused resources
docker system prune -a --volumes

# Check disk usage
docker system df

# Reduce Docker disk limit in Docker Desktop settings
```

---

## OpenShell Issues

### "openshell: command not found"

**Problem**: OpenShell binary not on PATH.

**Solution**:
```bash
# Check if installed
ls -la ~/.local/bin/openshell

# Add to PATH
export PATH="$HOME/.local/bin:$PATH"

# Add permanently
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

### "OpenShell sandbox create fails"

**Problem**: Cannot create sandbox.

**Solution**:
```bash
# Check Docker
docker info

# Check gateway
openshell gateway status

# Restart gateway
openshell gateway stop
openshell gateway start

# Check logs
openshell logs
```

### "Gateway not starting"

**Problem**: OpenShell gateway won't start.

**Solution**:
```bash
# Stop existing gateway
openshell gateway stop

# Check for port conflicts
lsof -i :8080

# Restart
openshell gateway start

# If still failing, reset
rm -rf ~/.openshell
openshell gateway start
```

---

## NemoClaw Issues

### "nemoclaw: command not found"

**Problem**: NemoClaw not installed or not on PATH.

**Solution**:
```bash
# Install
npm install -g git+https://github.com/NVIDIA/NemoClaw.git

# Check npm global bin
npm config get prefix

# Add to PATH
export PATH="$(npm config get prefix)/bin:$PATH"

# Or use the shim
ln -sf "$(npm config get prefix)/bin/nemoclaw" ~/.local/bin/nemoclaw
```

### "openclaw nemoclaw: unknown command"

**Problem**: OpenClaw plugin not registered.

**Solution**:
```bash
# Inside sandbox, reinstall plugin
openclaw plugins install /opt/nemoclaw

# Verify
openclaw nemoclaw status
```

---

## API Key Issues

### "No API key provided"

**Problem**: NVIDIA_API_KEY not set.

**Solution**:
```bash
# Get key from
open https://build.nvidia.com/settings/api-keys

# Set in environment
export NVIDIA_API_KEY=nvapi-xxx

# Or add to config
echo "NVIDIA_API_KEY=nvapi-xxx" >> config/.env
```

### "API key validation failed"

**Problem**: Invalid or expired API key.

**Solution**:
```bash
# Test manually
curl -H "Authorization: Bearer $NVIDIA_API_KEY" \
  https://integrate.api.nvidia.com/v1/models

# If 401 Unauthorized, get a new key
open https://build.nvidia.com/settings/api-keys
```

### "403 Forbidden"

**Problem**: API key lacks permissions or rate limited.

**Solution**:
```bash
# Check key status at
open https://build.nvidia.com/settings/api-keys

# Verify key has correct scopes
# May need to regenerate
```

---

## Sandbox Issues

### "Sandbox already exists"

**Problem**: Sandbox with same name exists.

**Solution**:
```bash
# Delete existing
openshell sandbox delete my-assistant

# Or connect to existing
nemoclaw my-assistant connect
```

### "Cannot connect to sandbox"

**Problem**: Sandbox not running or inaccessible.

**Solution**:
```bash
# List sandboxes
openshell sandbox list

# Check status
openshell sandbox get my-assistant

# Restart sandbox
openshell sandbox stop my-assistant
openshell sandbox start my-assistant

# Or recreate
openshell sandbox delete my-assistant
./scripts/09-create-sandbox.sh
```

### "Volume mount not working"

**Problem**: Files not persisting.

**Solution**:
```bash
# Check volume mounts
openshell sandbox get my-assistant | grep volume

# Verify local directories exist
ls -la openclaw-data/

# Recreate sandbox with correct paths
openshell sandbox delete my-assistant
openshell sandbox create \
  --from ghcr.io/nvidia/openshell-community/sandboxes/openclaw:latest \
  --name my-assistant \
  --volume "$(pwd)/openclaw-data/.openclaw:/sandbox/.openclaw" \
  --volume "$(pwd)/openclaw-data/workspace:/sandbox/workspace" \
  --forward 18789
```

---

## Network Issues

### "Network blocked"

**Problem**: Outbound connection blocked by policy.

**Solution**:
```bash
# Check current policy
openshell policy get my-assistant

# Add endpoint to policy (edit config/sandbox-policy.yaml)
openshell policy set my-assistant --policy config/sandbox-policy.yaml
```

### "Cannot reach NVIDIA API"

**Problem**: Network firewall blocking NVIDIA endpoints.

**Solution**:
```bash
# Test connectivity
curl -v https://integrate.api.nvidia.com/v1/models

# If blocked, check firewall/proxy
# May need to configure HTTP_PROXY
export HTTP_PROXY=http://proxy:port
export HTTPS_PROXY=http://proxy:port
```

### "Gateway port in use"

**Problem**: Port 18789 already in use.

**Solution**:
```bash
# Check what's using the port
lsof -i :18789

# Kill the process or use different port
openshell sandbox create --forward 18889 ...
```

---

## Getting More Help

1. **Check logs**:
   ```bash
   nemoclaw my-assistant logs --follow
   openshell logs
   ```

2. **Run diagnostics**:
   ```bash
   # Inside sandbox
   openclaw doctor --fix
   ```

3. **Verbose installation**:
   ```bash
   ./install.sh --verbose
   ```

4. **Community support**:
   - Discord: https://discord.gg/XFpfPv9Uvx
   - GitHub Issues: https://github.com/NVIDIA/NemoClaw/issues

5. **Documentation**:
   - OpenClaw: https://docs.openclaw.ai
   - OpenShell: https://docs.nvidia.com/openshell/latest/
   - NemoClaw: https://docs.nvidia.com/nemoclaw/latest/
