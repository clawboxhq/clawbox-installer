# ClawBox FAQ

Frequently Asked Questions about ClawBox.

---

## General

### What is ClawBox?

ClawBox is a secure local AI assistant that runs 100% on your machine. Unlike cloud AI tools, ClawBox:
- Keeps your code on your computer
- Executes AI-generated code in an isolated sandbox
- Controls what endpoints AI can access via network policies

### Who is ClawBox for?

ClawBox is designed for **security-focused developers**, particularly those who:
- Work in regulated industries (finance, healthcare, government)
- Cannot use cloud AI due to company policy
- Need to run AI-generated code safely
- Want control over AI network access

### How is ClawBox different from Ollama?

| Feature | ClawBox | Ollama |
|---------|---------|--------|
| Sandboxed execution | ✅ | ❌ |
| Network policies | ✅ | ❌ |
| Multi-provider support | ✅ | 🟡 Limited |
| Local inference | ✅ | ✅ |

**ClawBox can use Ollama as a provider.** Think of ClawBox as a security layer on top of Ollama.

### How is ClawBox different from GitHub Copilot?

| Feature | ClawBox | GitHub Copilot |
|---------|---------|----------------|
| Runs locally | ✅ | ❌ |
| Data leaves machine | ❌ | ✅ |
| Sandboxed execution | ✅ | ❌ |
| Network control | ✅ | ❌ |
| Subscription required | ❌ | ✅ |

### Is ClawBox free?

Yes. ClawBox is **open source** (Apache 2.0 license) and free to use.

---

## Installation

### What are the system requirements?

| Platform | Requirements |
|----------|--------------|
| macOS | macOS 11+ (Big Sur or later) |
| Linux | glibc 2.31+ (Ubuntu 20.04+, Debian 11+, Fedora 34+) |
| Windows | Windows 10+ |

**Hardware:**
- 4GB RAM minimum (8GB recommended)
- 1GB disk space
- For local inference: 8GB+ RAM for 7B models

### Do I need Docker?

Yes, Docker is required for sandbox isolation. The sandbox containers provide:
- Process isolation
- Filesystem sandboxing
- Network policy enforcement
- Resource limits

### Do I need a GPU?

No. ClawBox works without a GPU by:
- Using CPU inference (slower but functional)
- Connecting to cloud providers (OpenAI, Anthropic)
- Using existing local inference servers (Ollama, LM Studio)

### How do I install on macOS?

```bash
curl -fsSL https://clawbox.ai/install | bash
```

Or download the DMG from [Releases](https://github.com/clawboxhq/clawbox-installer/releases).

### How do I install on Windows?

```powershell
iex (irm https://clawbox.ai/install.ps1)
```

Or download the installer from [Releases](https://github.com/clawboxhq/clawbox-installer/releases).

### How do I install on Linux?

```bash
curl -fsSL https://clawbox.ai/install | bash
```

Or install via package manager:
```bash
# Debian/Ubuntu
sudo apt install ./clawbox_0.1.0_amd64.deb

# Fedora/RHEL
sudo dnf install ./clawbox-0.1.0-1.x86_64.rpm
```

---

## Usage

### How do I create a sandbox?

```bash
clawbox sandbox create my-sandbox --provider ollama --model llama3.2
```

### How do I start a sandbox?

```bash
clawbox sandbox start my-sandbox
```

### How do I connect to a sandbox?

```bash
clawbox sandbox connect my-sandbox
```

### How do I list all sandboxes?

```bash
clawbox sandbox list
```

### How do I stop a sandbox?

```bash
clawbox sandbox stop my-sandbox
```

### How do I delete a sandbox?

```bash
clawbox sandbox delete my-sandbox
```

---

## Providers

### What providers are supported?

| Type | Providers |
|------|-----------|
| Local | Ollama, LM Studio, llama.cpp, vLLM |
| Cloud | OpenAI, Anthropic, NVIDIA, OpenRouter |
| Custom | Any OpenAI-compatible endpoint |

### How do I add a cloud provider?

```bash
clawbox provider add my-openai \
  --type openai \
  --api-key sk-xxx
```

### How do I add a local provider?

```bash
clawbox provider add my-ollama \
  --type ollama \
  --endpoint http://localhost:11434
```

### How do I add a custom provider?

```bash
clawbox provider add my-custom \
  --type custom \
  --endpoint https://my-api.example.com/v1 \
  --api-key my-key
```

### How do I switch providers?

```bash
clawbox inference set my-sandbox --provider openai --model gpt-4o
```

This switches without restarting the sandbox.

### How do I test a provider connection?

```bash
clawbox provider test my-openai
```

---

## Security

### Is ClawBox secure?

Yes. ClawBox provides multiple security layers:
1. **Container isolation** - Code runs in isolated containers
2. **Network policies** - Block all outbound by default
3. **Filesystem sandboxing** - Limited file access
4. **Resource limits** - Prevent resource exhaustion

### What is the default network policy?

**Default: Deny all outbound connections.**

All network access must be explicitly allowed via policies.

### How do I add network access?

Use presets or custom policies:

```bash
# Add preset
clawbox policy add my-sandbox github

# Add custom endpoint
clawbox policy custom my-sandbox --host api.example.com --port 443
```

### What policies are available?

| Preset | Description |
|--------|-------------|
| `github` | GitHub API and webhooks |
| `docker` | Docker Hub and NVIDIA registry |
| `npm` | npm and Yarn registry |
| `pypi` | Python Package Index |
| `slack` | Slack API and webhooks |
| `discord` | Discord Bot API |
| `telegram` | Telegram Bot API |
| `huggingface` | Hugging Face Hub |
| `jira` | Jira and Atlassian Cloud |
| `outlook` | Microsoft Outlook and Graph API |

### Can AI-generated code escape the sandbox?

Extremely unlikely. Multiple layers of isolation:
- Container namespaces
- Seccomp filters
- No privileged containers
- Read-only mounts

### Does ClawBox send my data anywhere?

**No.** ClawBox runs 100% locally:
- No telemetry
- No analytics
- No cloud connections
- Your code stays on your machine

---

## Troubleshooting

### "command not found: clawbox"

Restart your terminal or run:
```bash
source ~/.zshrc  # macOS (zsh)
source ~/.bashrc # Linux (bash)
```

### "Ollama not detected"

Ensure Ollama is running:
```bash
ollama serve
```

Or check if Ollama is installed:
```bash
which ollama
```

### "Docker not available"

Start Docker Desktop or ensure Docker daemon is running:
```bash
# Linux
sudo systemctl start docker

# macOS
open -a Docker
```

### "Port already in use"

Use a different port:
```bash
clawbox sandbox create my-sandbox --port 18888
```

### "Model not found"

Pull the model first:
```bash
ollama pull llama3.2
```

### "Container fails to start"

Check Docker logs:
```bash
docker logs $(docker ps -ql)
```

Run diagnostics:
```bash
clawbox doctor --verbose
```

### "Out of memory"

For local inference:
- Use a smaller model (e.g., `llama3.2` instead of `llama3.1:70b`)
- Close other applications
- Increase Docker memory limit

### "Network connection blocked"

Add appropriate policy:
```bash
# See what's blocked
clawbox sandbox logs my-sandbox --follow

# Add policy for blocked endpoint
clawbox policy custom my-sandbox --host api.example.com --port 443
```

---

## Performance

### How much RAM do I need?

| Model Size | Minimum RAM | Recommended |
|------------|-------------|-------------|
| 7B parameters | 8GB | 16GB |
| 13B parameters | 16GB | 32GB |
| 70B parameters | 64GB | 128GB |

### How do I improve performance?

1. **Use GPU** - Significantly faster inference
2. **Quantized models** - Use Q4/Q5 quantization
3. **Smaller models** - Trade quality for speed
4. **Cloud providers** - Offload heavy workloads

### What's the latency?

| Mode | Latency |
|------|---------|
| Local (GPU) | 20-50 tokens/sec |
| Local (CPU) | 2-10 tokens/sec |
| Cloud | Network-dependent |

---

## Comparisons

### ClawBox vs Ollama

See [General: How is ClawBox different from Ollama?](#how-is-clawbox-different-from-ollama)

### ClawBox vs Docker Model Runner

| Feature | ClawBox | Docker Model Runner |
|---------|---------|---------------------|
| Sandboxed execution | ✅ | ❌ |
| Network policies | ✅ | ❌ |
| Multi-provider | ✅ | 🟡 |
| CLI focus | ✅ | ❌ |

### ClawBox vs LocalAI

| Feature | ClawBox | LocalAI |
|---------|---------|---------|
| Ease of use | ✅ One-command | 🟡 More config |
| Network policies | ✅ | ❌ |
| Multi-provider | ✅ | ✅ |
| Sandboxed execution | ✅ | ❌ |

### ClawBox vs AnythingLLM

| Feature | ClawBox | AnythingLLM |
|---------|---------|-------------|
| Focus | Developers | General use |
| Sandboxed execution | ✅ | ❌ |
| Network policies | ✅ | ❌ |
| Built-in RAG | ❌ | ✅ |

---

## Development

### Is ClawBox open source?

Yes. ClawBox is licensed under Apache 2.0.

**Repository:** https://github.com/clawboxhq/clawbox-installer

### How do I contribute?

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### How do I report bugs?

Open an issue: https://github.com/clawboxhq/clawbox-installer/issues

### How do I request features?

Open an issue with the `enhancement` label:
https://github.com/clawboxhq/clawbox-installer/issues

---

## Support

### Where can I get help?

| Channel | Use For |
|---------|---------|
| [GitHub Issues](https://github.com/clawboxhq/clawbox-installer/issues) | Bugs, features |
| [Discord](https://discord.gg/XFpfPv9Uvx) | Questions, discussions |
| [Discussions](https://github.com/clawboxhq/clawbox-installer/discussions) | Ideas, showcase |

### How do I report a security vulnerability?

**Email:** security@clawbox.ai

**Do NOT report security issues publicly.**

---

## Future

### What features are planned?

- Web UI
- VS Code extension
- Audit logging
- Model verification
- Enterprise features (RBAC, SSO)

### When will feature X be available?

Check the [roadmap](https://github.com/clawboxhq/clawbox-installer/blob/main/docs/PRODUCT.md) for planned features.

### Can I sponsor development?

Not currently. The project is community-driven.

---

## Still have questions?

Join our [Discord](https://discord.gg/XFpfPv9Uvx) or open a [GitHub Discussion](https://github.com/clawboxhq/clawbox-installer/discussions).
