# Changelog

All notable changes to ClawBox will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-22

### Added

- **One-Click GUI Installers**: True double-click installation for all platforms
  - macOS: DMG with drag-to-Applications
  - Windows: NSIS setup wizard (.exe)
  - Linux: .deb and .rpm packages
- **Network Policy Management**: Control which endpoints sandboxes can reach
  - 10 built-in presets: discord, docker, github, huggingface, jira, npm, outlook, pypi, slack, telegram
  - Commands: `clawbox policy presets/list/add/show/edit/custom`
  - Custom endpoint support with `--host` and `--port` flags
- **Inference Routing**: Switch providers and models at runtime
  - Commands: `clawbox inference set/status/models/list-models`
  - No sandbox restart required
- **OpenShell Provider Sync**: Automatic synchronization to OpenShell
  - Providers sync on `sandbox start`
  - New `clawbox provider sync <name>` command
  - Auto-sync on `provider add` (with `--sync` flag)
- **Monitor Command**: `clawbox monitor` wraps `openshell term` TUI
- **Policy fields in SandboxConfig**: `policies` and `customPolicies` arrays
- **Go binary CLI**: Compiled Go binary for all operations
- **Unified CLI**: Single `clawbox` command for all operations
- **Multi-provider support**:
  - Cloud: NVIDIA, OpenAI, Anthropic, OpenRouter
  - Local: Ollama, LM Studio, llama.cpp, vLLM
  - Custom: Any OpenAI-compatible endpoint
- **Provider management**: `clawbox provider` command with subcommands
- **Sandbox management**: `clawbox sandbox` command for full lifecycle
- **Configuration management**: `clawbox config` command
- **Diagnostics**: `clawbox doctor` for health checks
- **Shell completions**: Bash, Zsh, Fish
- **JSON output**: `--json` flag for scripting
- **Cross-platform builds**: macOS (ARM64/x86_64), Linux (ARM64/x86_64), Windows (ARM64/x86_64)
- **Telegram Bot Integration**: Remote control via `opencode-telegram-bot`
- **Initial release** as shell script installer
- **Persistent volume mounting** for OpenClaw data
- **Interactive and non-interactive** installation modes
- **Dry-run preview mode**
- **Clean uninstaller**
- **GitHub Pages distribution**

### Changed

- Configuration format changed from shell env files to JSON
- Configuration location: `~/.clawbox/config.json`
- Installation: Go binary installed to PATH

### Fixed

- **Critical**: Providers now sync to OpenShell on sandbox start
  - Previously, sandboxes couldn't use configured providers
- Provider add/remove now syncs to OpenShell by default

### Security

- Network policies enforce strict-by-default egress control
- All endpoints require explicit policy allowlisting
- Supports OpenShell's policy hot-reload for runtime updates
