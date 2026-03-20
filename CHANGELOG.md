# Changelog

All notable changes to ClawBox will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-21

### Added
- **Go binary CLI**: Replaced shell scripts with compiled Go binary
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
- **Cross-platform builds**: macOS (ARM64/x86_64), Linux (ARM64/x86_64)

### Changed
- Configuration format changed from shell env files to JSON
- Configuration location: `~/.clawbox/config.json`
- Installation: Go binary installed to PATH

### Removed
- Shell script installer (`install.sh`)
- Shell script uninstaller (`uninstall.sh`)
- Phase scripts (`scripts/*.sh`)
- Shell library files (`lib/*.sh`)
- Template files (`config/*.template`)
- Documentation files (integrated into README)

## [0.1.0] - 2026-03-20

### Added
- Initial release as shell script installer
- One-click installation for OpenShell + NemoClaw + OpenClaw
- Persistent volume mounting for OpenClaw data
- Multi-provider API key configuration (NVIDIA, OpenAI, Anthropic, OpenRouter)
- Interactive and non-interactive installation modes
- Dry-run preview mode
- Clean uninstaller
- GitHub Pages distribution
