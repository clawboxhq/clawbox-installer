# ClawBox Quick Start Guide

Get up and running with ClawBox in 5 minutes.

---

## Prerequisites

Before starting, ensure you have:

| Requirement | How to Check | Install Link |
|-------------|--------------|--------------|
| **Ollama** (recommended) | `ollama --version` | [ollama.ai](https://ollama.ai) |
| **Docker** | `docker --version` | [docker.com](https://docker.com) |

> **Note:** Ollama is recommended for local AI. You can also use OpenAI, Anthropic, or other cloud providers.

---

## Step 1: Install ClawBox (1 minute)

### macOS / Linux

Open Terminal and run:

```bash
curl -fsSL https://clawbox.ai/install | bash
```

### Windows

Open PowerShell and run:

```powershell
iex (irm https://clawbox.ai/install.ps1)
```

### What happens during installation?

1. Downloads ClawBox binary
2. Detects your platform (macOS, Linux, Windows)
3. Detects if Ollama is installed
4. Creates initial configuration
5. Adds ClawBox to your PATH

---

## Step 2: Verify Installation (30 seconds)

Check that ClawBox is installed correctly:

```bash
clawbox version
```

Expected output:
```
clawbox version 0.1.0
```

Run diagnostics:

```bash
clawbox doctor
```

Expected output:
```
✓ clawbox binary found
✓ Configuration valid
✓ Ollama detected at http://localhost:11434
✓ Docker available
✓ All checks passed
```

---

## Step 3: Pull a Model (1 minute)

If using Ollama, pull a model:

```bash
ollama pull llama3.2
```

Wait for download to complete (about 2GB).

> **Alternative models:**
> - `llama3.2` - Fast, capable (recommended)
> - `mistral` - Good performance
> - `codellama` - Code-focused
> - `deepseek-coder` - Excellent for coding

---

## Step 4: Create a Sandbox (1 minute)

Create your first sandbox:

```bash
clawbox sandbox create my-first-sandbox \
  --provider ollama \
  --model llama3.2
```

Expected output:
```
✓ Created sandbox: my-first-sandbox
  Provider: ollama
  Model: llama3.2
  Port: 18789
```

---

## Step 5: Start the Sandbox (30 seconds)

Start your sandbox:

```bash
clawbox sandbox start my-first-sandbox
```

Expected output:
```
✓ Started sandbox: my-first-sandbox
  Model: llama3.2
  Port: 18789
  Status: running

Ready! Connect with: clawbox sandbox connect my-first-sandbox
```

---

## Step 6: Connect and Chat (ongoing)

Connect to your sandbox:

```bash
clawbox sandbox connect my-first-sandbox
```

You're now in an interactive AI session. Try:

```
You: Write a Python function to calculate fibonacci numbers
```

The AI will generate code that runs safely in the sandbox.

---

## Quick Reference

### Essential Commands

| Command | Description |
|---------|-------------|
| `clawbox version` | Show version |
| `clawbox doctor` | Run diagnostics |
| `clawbox sandbox create <name>` | Create a sandbox |
| `clawbox sandbox start <name>` | Start a sandbox |
| `clawbox sandbox stop <name>` | Stop a sandbox |
| `clawbox sandbox list` | List all sandboxes |
| `clawbox sandbox connect <name>` | Connect to sandbox |
| `clawbox sandbox delete <name>` | Delete a sandbox |

### Network Policies

| Command | Description |
|---------|-------------|
| `clawbox policy presets` | List available presets |
| `clawbox policy add <sandbox> <preset>` | Apply preset |
| `clawbox policy list <sandbox>` | Show applied policies |
| `clawbox policy custom <sandbox> --host <host> --port <port>` | Add custom endpoint |

### Provider Management

| Command | Description |
|---------|-------------|
| `clawbox provider list` | List providers |
| `clawbox provider add <name> --type <type>` | Add provider |
| `clawbox provider test <name>` | Test connection |
| `clawbox provider default <name>` | Set default |

---

## Common Tasks

### Using a Different Model

```bash
# Create sandbox with different model
clawbox sandbox create coding-assistant \
  --provider ollama \
  --model deepseek-coder

# Or use cloud provider
clawbox sandbox create cloud-assistant \
  --provider openai \
  --model gpt-4o
```

### Adding Network Access

```bash
# Allow GitHub access
clawbox policy add my-first-sandbox github

# Allow custom API
clawbox policy custom my-first-sandbox \
  --host api.example.com \
  --port 443
```

### Switching Models

```bash
# Switch without restart
clawbox inference set my-first-sandbox \
  --provider openai \
  --model gpt-4o-mini
```

---

## Troubleshooting

### "command not found: clawbox"

Restart your terminal or run:
```bash
source ~/.zshrc  # or ~/.bashrc
```

### "Ollama not detected"

Ensure Ollama is running:
```bash
ollama serve
```

### "Docker not available"

Start Docker Desktop or ensure Docker daemon is running.

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

---

## Next Steps

Now that you're set up:

1. **Read the full documentation** - [README.md](../README.md)
2. **Learn about security** - [SECURITY.md](SECURITY.md)
3. **Understand architecture** - [ARCHITECTURE.md](ARCHITECTURE.md)
4. **Join the community** - [Discord](https://discord.gg/XFpfPv9Uvx)

---

## Getting Help

| Channel | Use For |
|---------|---------|
| [GitHub Issues](https://github.com/clawboxhq/clawbox-installer/issues) | Bug reports, feature requests |
| [Discord](https://discord.gg/XFpfPv9Uvx) | Questions, discussions |
| [Discussions](https://github.com/clawboxhq/clawbox-installer/discussions) | Ideas, showcase |

---

## 5-Minute Checklist

- [ ] ClawBox installed
- [ ] `clawbox version` shows version
- [ ] `clawbox doctor` passes all checks
- [ ] Ollama running with a model
- [ ] First sandbox created
- [ ] First sandbox started
- [ ] Successfully connected to sandbox
- [ ] AI responded to a prompt

---

**🎉 Congratulations! You're ready to use ClawBox securely.**
