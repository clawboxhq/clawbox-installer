# ClawBox — Run AI Locally. Execute Code Safely.

**The secure local AI assistant for developers who can't risk cloud AI tools.**

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-success.svg)]()
[![Version](https://img.shields.io/badge/Version-0.1.0-orange.svg)]()

---

## Why ClawBox?

| Problem | ClawBox Solution |
|---------|------------------|
| "I can't use Copilot due to company policy" | **100% local** — zero telemetry, no data leaves your machine |
| "AI-generated code might be malicious" | **Sandboxed execution** — code runs in isolated environment |
| "I need to control what AI can access" | **Network policies** — block by default, allow explicitly |
| "My company needs audit trails" | **Execution logging** — full audit capability (coming soon) |

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

---

## Quick Start

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

## How ClawBox Compares

| Feature | ClawBox | Ollama | LM Studio | Open WebUI | GitHub Copilot |
|---------|---------|--------|-----------|------------|----------------|
| Sandboxed code execution | ✅ Built-in | ❌ | ❌ | ❌ | ❌ |
| Network policy control | ✅ 10 presets | ❌ | ❌ | ❌ | ❌ |
| 100% offline | ✅ | ✅ | ✅ | ✅ | ❌ |
| Zero telemetry | ✅ | ✅ | ✅ | ✅ | ❌ |
| Multi-provider support | ✅ | 🟡 Limited | ✅ | ✅ | ❌ |
| One-click GUI installer | ✅ | ✅ | ✅ | ❌ | N/A |
| Hot-swap models | ✅ | 🟡 Restart | 🟡 Manual | 🟡 Manual | N/A |

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

- **GitHub**: [clawboxhq/clawbox-installer](https://github.com/clawboxhq/clawbox-installer)
- **Issues**: [GitHub Issues](https://github.com/clawboxhq/clawbox-installer/issues)
- **Documentation**: [docs.openclaw.ai](https://docs.openclaw.ai)

---

## License

Apache License 2.0 — See [LICENSE](https://github.com/clawboxhq/clawbox-installer/blob/main/LICENSE) for details.
