# 🦞 ClawBox

**Secure AI Assistant in a Box**

Cross-platform CLI for deploying OpenShell + NemoClaw + OpenClaw with secure sandboxing, persistent volume mounting, and network policy management.

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20WSL2-success.svg)]()
[![Version](https://img.shields.io/badge/Version-0.3.0--beta-orange.svg)]()

---

## Installation

### One-Line Install

```bash
# macOS/Linux
curl -fsSL https://github.com/clawboxhq/clawbox-installer/releases/download/v0.3.0/clawbox-0.3.0-darwin-arm64 -o clawbox
chmod +x clawbox
sudo mv clawbox /usr/local/bin/
```

### Manual Build

```bash
git clone https://github.com/clawboxhq/clawbox-installer.git
cd clawbox-installer
make build
sudo make install
```

---

## Usage

```bash
clawbox [command] [flags]
```

### Commands

| Command | Description |
|---------|-------------|
| `install` | Install ClawBox and all dependencies |
| `uninstall` | Remove ClawBox installation |
| `sandbox` | Manage OpenShell sandboxes |
| `provider` | Manage LLM providers |
| `policy` | Manage network policies |
| `inference` | Manage inference routing |
| `config` | Manage configuration |
| `monitor` | Open TUI monitoring dashboard |
| `status` | Show system status |
| `doctor` | Run diagnostics and health checks |
| `update` | Update ClawBox components |
| `version` | Show version information |

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

Control which endpoints your sandbox can reach. By default, all unlisted endpoints are blocked.

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

# Show full policy YAML
clawbox policy show my-assistant

# Edit policy (pull/edit/push workflow)
clawbox policy edit my-assistant

# Add custom endpoint
clawbox policy custom my-assistant --host api.company.com --port 443
```

---

## Inference Routing

Switch providers and models at runtime without restarting sandboxes.

### Inference Commands

```bash
# Switch to different provider/model
clawbox inference set my-assistant --provider openai --model gpt-4o

# Show current inference configuration
clawbox inference status my-assistant

# List common models
clawbox inference models

# List available models for a provider
clawbox inference list-models openai
```

---

## Examples

### Installation

```bash
# Interactive installation
clawbox install

# Non-interactive with specific provider
clawbox install --provider openai --non-interactive

# Local LLM with Ollama
clawbox install --provider ollama --model llama3.2

# Custom endpoint
clawbox install --provider custom --endpoint https://my-api.example.com/v1 --api-key my-key
```

### Provider Management

```bash
# List providers
clawbox provider list

# Add cloud provider
clawbox provider add my-openai --type openai --api-key sk-xxx

# Add local provider
clawbox provider add my-ollama --type ollama --endpoint http://localhost:11434

# Sync provider to OpenShell
clawbox provider sync my-openai

# Test connection
clawbox provider test my-ollama

# Set default
clawbox provider default my-openai
```

### Sandbox Management

```bash
# Create sandbox
clawbox sandbox create dev --provider ollama --model llama3.2

# List sandboxes
clawbox sandbox list

# Start/stop
clawbox sandbox start dev
clawbox sandbox stop dev

# Connect
clawbox sandbox connect dev

# View logs
clawbox sandbox logs dev --follow
```

### Monitoring

```bash
# Open TUI monitoring dashboard
clawbox monitor

# Run diagnostics
clawbox doctor

# Verbose output
clawbox doctor --verbose

# JSON output
clawbox doctor --json
```

### Configuration

```bash
# Show config
clawbox config show

# Set values
clawbox config set defaultProvider ollama

# Edit config
clawbox config edit

# Show config path
clawbox config path
```

---

## Configuration

Configuration is stored in JSON format at `~/.clawbox/config.json`.

### Example Configuration

```json
{
  "defaultProvider": "ollama",
  "providers": {
    "ollama": {
      "name": "ollama",
      "type": "ollama",
      "endpoint": "http://localhost:11434",
      "defaultModel": "llama3.2"
    },
    "openai": {
      "name": "openai",
      "type": "openai",
      "endpoint": "https://api.openai.com/v1",
      "apiKey": "sk-xxx",
      "defaultModel": "gpt-4o"
    }
  },
  "sandboxes": [
    {
      "name": "my-assistant",
      "provider": "ollama",
      "model": "llama3.2",
      "port": 18789,
      "policies": ["github", "slack"]
    }
  ],
  "containerRuntime": "docker"
}
```

### Custom Config Location

```bash
clawbox --config /path/to/config.json [command]
```

---

## Shell Completions

### Bash

```bash
clawbox completion bash > /etc/bash_completion.d/clawbox
source ~/.bashrc
```

### Zsh

```bash
clawbox completion zsh > "${fpath[1]}/_clawbox"
source ~/.zshrc
```

### Fish

```bash
clawbox completion fish > ~/.config/fish/completions/clawbox.fish
source ~/.config/fish/config.fish
```

---

## System Requirements

| Platform | Requirements |
|----------|--------------|
| macOS | Apple Silicon (M1/M2/M3/M4), macOS 14.0+ |
| Linux | x86_64 or ARM64, Ubuntu 22.04+ |
| Windows | Windows 10/11 with WSL2 |

- **RAM**: 8 GB minimum, 16 GB recommended
- **Disk**: 20 GB free space minimum
- **Network**: Internet connection required

---

## Project Structure

```
clawbox/
├── cmd/clawbox/           # CLI entry point
│   └── cmd/               # Command implementations
├── internal/              # Internal packages
│   ├── provider/          # Provider system
│   └── policy/            # Policy management
├── completions/           # Shell completions
├── go.mod                 # Go module definition
├── go.sum                 # Dependency checksums
└── Makefile               # Build configuration
```

---

## License

Apache License 2.0 - See [LICENSE](LICENSE) file for details.

---

## Support

- **Issues**: https://github.com/clawboxhq/clawbox-installer/issues
- **Discord**: https://discord.gg/XFpfPv9Uvx
- **OpenClaw Docs**: https://docs.openclaw.ai
- **NemoClaw Docs**: https://docs.nvidia.com/nemoclaw/
