# 🦞 ClawBox

**Secure AI Assistant in a Box**

One-click cross-platform installer for OpenShell + NemoClaw + OpenClaw with secure sandboxing and persistent volume mounting.

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20WSL2-success.svg)]()
[![Version](https://img.shields.io/badge/Version-0.1.0--alpha-orange.svg)]()
[![OpenClaw](https://img.shields.io/badge/OpenClaw-2026.3.11-orange.svg)](https://openclaw.ai)

---

## Why ClawBox?

ClawBox makes getting started with NemoClaw and OpenShell **10x easier**. Instead of manually installing dependencies, configuring sandboxes, and setting up volume mounts — just run one command.

| Feature | Without ClawBox | With ClawBox |
|---------|-----------------|--------------|
| **Installation** | Manual install of Homebrew, Node.js, Docker, OpenShell, NemoClaw | One command: `curl ... \| bash` |
| **Volume Mounting** | Manual `openshell sandbox create --volume ...` with complex paths | Automatic persistent data mounting |
| **Configuration** | Create config files manually | Templates auto-generated |
| **Uninstall** | Manually remove each component | Clean uninstaller with options |
| **Updates** | Track and update each tool separately | Unified update path |

### Key Differentiators

| Feature | Description |
|---------|-------------|
| 🚀 **One-Click Install** | Single command installs all dependencies (Homebrew, Node.js 22+, Docker, OpenShell, NemoClaw) |
| 💾 **Persistent Volume Mounting** | OpenClaw config, credentials, and workspace persist across sandbox restarts |
| 🎨 **User-Friendly UX** | Colored terminal output, progress indicators, phase-by-phase installation |
| 🔧 **Non-Interactive Mode** | Automate installations with `--non-interactive` flag |
| 🤖 **Multi-Provider Support** | NVIDIA, OpenAI, Anthropic, OpenRouter - choose your LLM |
| 🧪 **Dry-Run Preview** | See what would be installed before making changes |
| 🧹 **Clean Uninstaller** | Remove everything or keep specific components |
| 📦 **GitHub Pages Distribution** | Install directly via `curl` without cloning |
| ⚙️ **Extensible Config** | Template files for API keys, OpenClaw config, sandbox policies |

---

## Quick Start

### One-Line Install

```bash
# Install with one command
curl -fsSL https://clawboxhq.github.io/clawbox-installer/install.sh | bash

# Or directly from GitHub
curl -fsSL https://raw.githubusercontent.com/clawboxhq/clawbox-installer/main/install.sh | bash
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/clawboxhq/clawbox-installer.git
cd clawbox-installer

# Run the installer
./install.sh
```

### Non-Interactive Installation

```bash
# NVIDIA (default)
PROVIDER=nvidia NVIDIA_API_KEY=nvapi-xxx ./install.sh --non-interactive

# OpenAI
PROVIDER=openai OPENAI_API_KEY=sk-xxx ./install.sh --non-interactive

# Anthropic
PROVIDER=anthropic ANTHROPIC_API_KEY=sk-ant-xxx ./install.sh --non-interactive

# OpenRouter
PROVIDER=openrouter OPENROUTER_API_KEY=sk-or-xxx ./install.sh --non-interactive

# Or use --provider flag
./install.sh --provider openai --non-interactive

# Custom sandbox name
./install.sh --sandbox-name my-ai-assistant
```

---

## Supported LLM Providers

ClawBox supports multiple LLM providers out of the box:

| Provider | API Key Env | Default Model | Get API Key |
|----------|-------------|---------------|-------------|
| **NVIDIA** (default) | `NVIDIA_API_KEY` | `nemotron-3-super-120b-a12b` | [Get Key](https://build.nvidia.com/settings/api-keys) |
| **OpenAI** | `OPENAI_API_KEY` | `gpt-4o` | [Get Key](https://platform.openai.com/api-keys) |
| **Anthropic** | `ANTHROPIC_API_KEY` | `claude-sonnet-4-20250514` | [Get Key](https://console.anthropic.com/settings/keys) |
| **OpenRouter** | `OPENROUTER_API_KEY` | `anthropic/claude-sonnet-4` | [Get Key](https://openrouter.ai/keys) |

### Interactive Provider Selection

When running interactively, ClawBox will prompt you to select a provider:

```
Available providers:

  1) NVIDIA (NIM API) - nemotron-3-super-120b-a12b
  2) OpenAI - gpt-4o
  3) Anthropic - claude-sonnet-4-20250514
  4) OpenRouter - anthropic/claude-sonnet-4

Select provider [1-4] (default: 1):
```

---

## What This Installs

| Component | Description |
|-----------|-------------|
| **Homebrew** | macOS package manager (if not present) |
| **Node.js 22+** | JavaScript runtime (if not present) |
| **Docker Desktop** | Container runtime (if not present) |
| **OpenShell** | Safe, private runtime for AI agents |
| **NemoClaw** | NVIDIA plugin for secure OpenClaw in OpenShell |
| **OpenClaw** | Personal AI assistant running in sandbox |

---

## System Requirements

| Platform | Requirements |
|----------|--------------|
| **macOS** | Apple Silicon (M1/M2/M3/M4), macOS 14.0+ |
| **Linux** | x86_64 or ARM64, Ubuntu 22.04+ |
| **Windows** | Windows 10/11 with WSL2 enabled |

- **RAM**: 8 GB minimum, 16 GB recommended
- **Disk**: 20 GB free space minimum
- **Network**: Internet connection required

> ⚠️ Intel Macs (x86_64) are NOT supported

---

## Command Line Options

```
Options:
  --non-interactive    Run without prompts (requires PROVIDER_API_KEY env)
  --provider PROVIDER  LLM provider: nvidia, openai, anthropic, openrouter
  --skip-docker        Skip Docker installation (use existing)
  --skip-node          Skip Node.js installation (use existing)
  --sandbox-name NAME  Custom sandbox name (default: my-assistant)
  --project-dir DIR    Project directory (default: script location)
  --dry-run            Show what would be installed
  --verbose            Enable verbose output
  --help               Show help message
```

---

## Volume Mounting

ClawBox creates persistent volume mounts for your OpenClaw data:

```
Project Directory Structure:
├── openclaw-data/
│   ├── .openclaw/           # OpenClaw configuration
│   │   ├── openclaw.json    # Main config file
│   │   ├── agents/          # Agent configurations
│   │   ├── credentials/     # Channel credentials
│   │   └── workspace/       # Skills and prompts
│   └── workspace/
│       ├── AGENTS.md        # Agent behavior config
│       ├── SOUL.md          # Agent personality
│       └── skills/          # Custom skills
```

---

## Post-Installation

### Connect to Sandbox

```bash
# Connect to the OpenClaw sandbox
nemoclaw my-assistant connect

# Inside sandbox, launch OpenClaw TUI
openclaw tui

# Or send a test message
openclaw agent -m "Hello from OpenClaw"
```

### Monitor Network Activity

```bash
# Launch OpenShell monitoring dashboard
openshell term
```

### Check Status

```bash
# Sandbox status
nemoclaw my-assistant status

# OpenClaw status inside sandbox
openclaw gateway status
```

### Access Dashboard

The OpenClaw web dashboard is forwarded to your host:

```
http://127.0.0.1:18789
```

---

## Configuration

### LLM Provider Configuration

ClawBox supports multiple LLM providers. Configure via environment variables:

```bash
# NVIDIA (default)
export PROVIDER=nvidia
export NVIDIA_API_KEY=nvapi-xxx

# OpenAI
export PROVIDER=openai
export OPENAI_API_KEY=sk-xxx

# Anthropic
export PROVIDER=anthropic
export ANTHROPIC_API_KEY=sk-ant-xxx

# OpenRouter
export PROVIDER=openrouter
export OPENROUTER_API_KEY=sk-or-xxx
```

Or add to `config/.env`:

```bash
# config/.env
PROVIDER=nvidia
NVIDIA_API_KEY=nvapi-xxx
```

### Provider-Specific URLs

| Provider | Get API Key | Documentation |
|----------|-------------|---------------|
| NVIDIA | https://build.nvidia.com/settings/api-keys | [NVIDIA NIM API](https://build.nvidia.com) |
| OpenAI | https://platform.openai.com/api-keys | [OpenAI API](https://platform.openai.com/docs) |
| Anthropic | https://console.anthropic.com/settings/keys | [Anthropic API](https://docs.anthropic.com) |
| OpenRouter | https://openrouter.ai/keys | [OpenRouter](https://openrouter.ai/docs) |

---

## Uninstallation

```bash
# Interactive uninstall
./uninstall.sh

# Force without prompts
./uninstall.sh --yes

# Keep OpenShell, remove everything else
./uninstall.sh --keep-openshell
```

---

## Project Structure

```
clawbox/
├── install.sh              # Main installer
├── uninstall.sh            # Uninstaller
├── Makefile                # Build targets
├── LICENSE                 # Apache 2.0 License
├── README.md               # This file
│
├── lib/
│   ├── colors.sh           # Terminal colors
│   ├── utils.sh            # Utility functions
│   └── ui.sh               # UI functions
│
├── scripts/
│   ├── 01-check-architecture.sh
│   ├── 02-check-prerequisites.sh
│   ├── 03-install-homebrew.sh
│   ├── 04-install-nodejs.sh
│   ├── 05-install-docker.sh
│   ├── 06-install-openshell.sh
│   ├── 07-install-nemoclaw.sh
│   ├── 08-configure-api-key.sh
│   ├── 09-create-sandbox.sh
│   └── 10-verify-installation.sh
│
├── config/
│   ├── env.template        # Environment template
│   ├── openclaw.json.template
│   └── sandbox-policy.yaml
│
├── docs/
│   ├── README.md           # Documentation
│   ├── POST-INSTALL.md     # Post-install guide
│   ├── TROUBLESHOOTING.md  # Troubleshooting guide
│   └── pages/              # GitHub Pages files
│
└── openclaw-data/          # Persistent data (mounted)
```

---

## Acknowledgments

ClawBox is built on top of amazing projects:

- [NVIDIA NemoClaw](https://github.com/NVIDIA/NemoClaw) - Secure OpenClaw sandbox
- [NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell) - Safe runtime for AI agents
- [OpenClaw](https://github.com/openclaw/openclaw) - Personal AI assistant framework

---

## Disclaimer

> **Note:** ClawBox is NOT affiliated with, endorsed by, or sponsored by NVIDIA Corporation.
> NemoClaw, OpenShell, and NVIDIA are trademarks of NVIDIA Corporation.
> ClawBox is an independent community project that installs and configures the official NemoClaw software.

---

## License

Apache License 2.0 - See [LICENSE](LICENSE) file for details.

---

## Support

- **Issues**: https://github.com/clawboxhq/clawbox-installer/issues
- **Discord**: https://discord.gg/XFpfPv9Uvx
- **OpenClaw Docs**: https://docs.openclaw.ai
- **NemoClaw Docs**: https://docs.nvidia.com/nemoclaw/latest/
