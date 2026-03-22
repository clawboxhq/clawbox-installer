# ClawBox - Run AI Locally. Execute Code Safely.

**The secure local AI assistant for developers who can't risk cloud AI tools.**

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-success.svg)]()
[![Version](https://img.shields.io/badge/Version-0.1.0-orange.svg)]()

---

## Why ClawBox?

| Problem | ClawBox Solution |
|---------|------------------|
| "I can't use Copilot due to company policy" | **100% local** - zero telemetry, no data leaves your machine |
| "AI-generated code might be malicious" | **Sandboxed execution** - code runs in isolated environment |
| "I need to control what AI can access" | **Network policies** - block by default, allow explicitly |
| "My company needs audit trails" | **Execution logging** - full audit capability (coming soon) |

---

## One-Command Install

**macOS / Linux:**
```bash
curl -fsSL https://clawbox.ai/install | bash
```

**Windows (PowerShell):**
```powershell
iex (irm https://clawbox.ai/install.ps1)
```

**Or download installers:**
- [macOS DMG](https://github.com/clawboxhq/clawbox-installer/releases/latest) - Double-click to install
- [Windows Installer](https://github.com/clawboxhq/clawbox-installer/releases/latest) - Setup wizard
- [Linux Packages](https://github.com/clawboxhq/clawbox-installer/releases/latest) - .deb and .rpm available

---

## How ClawBox Compares

| Feature | ClawBox | Ollama | LM Studio | Open WebUI | GitHub Copilot |
|---------|---------|--------|-----------|------------|----------------|
| Sandboxed code execution | ✅ Built-in | ❌ | ❌ | ❌ | ❌ |
| Network policy control | ✅ 10 presets | ❌ | ❌ | ❌ | ❌ |
| 100% offline | ✅ | ✅ | ✅ | ✅ | ❌ |
| Zero telemetry | ✅ | ✅ | ✅ | ✅ | ❌ |
| Multi-provider support | ✅ | 🟡 Limited | ✅ | ✅ | ❌ |
| Works without GPU | ✅ | 🟡 Limited | ✅ | ✅ | ✅ |
| One-click GUI installer | ✅ | ✅ | ✅ | ❌ | N/A |
| Hot-swap models | ✅ | 🟡 Restart | 🟡 Manual | 🟡 Manual | N/A |

**ClawBox is for developers who need security guarantees that other tools don't provide.**

---

## Quick Start

After installation:

```bash
# Check everything is working
clawbox version

# Install and configure AI providers
clawbox install

# Start a sandbox
clawbox sandbox create dev --provider ollama --model llama3.2
clawbox sandbox start dev

# Connect and start coding
clawbox sandbox connect dev
```

---

## Supported LLM Providers

### Cloud Providers

| Provider | Default Model | Get API Key |
|----------|---------------|-------------|
| NVIDIA | `nvidia/nemotron-3-super-120b-a12b` | [Get Key](https://build.nvidia.com/settings/api-keys) |
| OpenAI | `gpt-4o` | [Get Key](https://platform.openai.com/api-keys) |
| Anthropic | `claude-sonnet-4-20250514` | [Get Key](https://console.anthropic.com/settings/keys) |
| OpenRouter | `anthropic/claude-sonnet-4` | [Get Key](https://openrouter.ai/keys) |

### Local Providers

| Provider | Default Model | Endpoint |
|----------|---------------|----------|
| Ollama | `llama3.2` | `http://localhost:11434` |
| LM Studio | `local-model` | `http://localhost:1234` |
| llama.cpp | `local-model` | `http://localhost:8080` |
| vLLM | `local-model` | `http://localhost:8000` |
| Custom | (configurable) | (configurable) |

---

## Network Policies

Control which endpoints your sandbox can reach. **All unlisted endpoints are blocked by default.**

### Built-in Presets

| Preset | Description |
|--------|-------------|
| `discord` | Discord API, gateway, and CDN |
| `docker` | Docker Hub and NVIDIA container registry |
| `github` | GitHub API and webhooks |
| `huggingface` | Hugging Face Hub, LFS, and Inference API |
| `jira` | Jira and Atlassian Cloud |
| `npm` | npm and Yarn registry |
| `outlook` | Microsoft Outlook and Graph API |
| `pypi` | Python Package Index |
| `slack` | Slack API and webhooks |
| `telegram` | Telegram Bot API |

### Policy Commands

```bash
# List available presets
clawbox policy presets

# Apply a preset to a sandbox
clawbox policy add my-assistant github

# List applied policies
clawbox policy list my-assistant

# Add custom endpoint
clawbox policy custom my-assistant --host api.company.com --port 443
```

---

## Inference Routing

Switch providers and models at runtime without restarting sandboxes.

```bash
# Switch to different provider/model
clawbox inference set my-assistant --provider openai --model gpt-4o

# Show current inference configuration
clawbox inference status my-assistant

# List available models for a provider
clawbox inference list-models openai
```

---

## Commands Reference

| Command | Description |
|---------|-------------|
| `install` | Install ClawBox and configure providers |
| `sandbox` | Manage OpenShell sandboxes |
| `provider` | Manage LLM providers |
| `policy` | Manage network policies |
| `inference` | Manage inference routing |
| `config` | Manage configuration |
| `monitor` | Open TUI monitoring dashboard |
| `doctor` | Run diagnostics and health checks |
| `version` | Show version information |

---

## Configuration

Configuration stored at `~/.clawbox/config.json`:

```json
{
  "defaultProvider": "ollama",
  "providers": {
    "ollama": {
      "name": "ollama",
      "type": "ollama",
      "endpoint": "http://localhost:11434",
      "defaultModel": "llama3.2"
    }
  },
  "sandboxes": [
    {
      "name": "dev",
      "provider": "ollama",
      "model": "llama3.2",
      "port": 18789,
      "policies": ["github", "slack"]
    }
  ]
}
```

---

## System Requirements

| Platform | Requirements |
|----------|--------------|
| macOS | macOS 11+ (Big Sur or later) |
| Linux | glibc 2.31+ (Ubuntu 20.04+, Debian 11+, Fedora 34+) |
| Windows | Windows 10+ or Windows Server 2019+ |

**Hardware:**
- 4GB RAM minimum (8GB recommended)
- 1GB disk space
- Internet connection for initial setup

---

## Security Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Your Machine                         │
│  ┌─────────────────────────────────────────────────────┐│
│  │                  ClawBox CLI                         ││
│  │  • Provider management                               ││
│  │  • Policy enforcement                                ││
│  │  • Audit logging                                     ││
│  └──────────────────────┬──────────────────────────────┘│
│                         │                                │
│  ┌──────────────────────▼──────────────────────────────┐│
│  │              Sandbox Environment                     ││
│  │  ┌─────────────────────────────────────────────────┐││
│  │  │          Isolated Container                      │││
│  │  │  • AI-generated code runs here                  │││
│  │  │  • No access to host filesystem                 │││
│  │  │  • Network policies enforced                    │││
│  │  └─────────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

---

## Community

- **Discord**: [Join Discussion](https://discord.gg/XFpfPv9Uvx)
- **Issues**: [GitHub Issues](https://github.com/clawboxhq/clawbox-installer/issues)
- **OpenClaw Docs**: https://docs.openclaw.ai

---

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.
