# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Makefile for ClawBox

.PHONY: all install uninstall check clean test lint help

# Default target
all: check

# Installation targets
install: ## Run the full installer
	@./install.sh

install-non-interactive: ## Run non-interactive installation (requires NVIDIA_API_KEY)
	@NVIDIA_API_KEY=${NVIDIA_API_KEY} ./install.sh --non-interactive

install-dry-run: ## Show what would be installed without making changes
	@./install.sh --dry-run

# Uninstallation
uninstall: ## Run the uninstaller
	@./uninstall.sh

uninstall-force: ## Force uninstall without prompts
	@./uninstall.sh --yes

# Verification
check: ## Check all scripts are executable
	@echo "Checking scripts..."
	@for f in scripts/*.sh; do \
		if [ ! -x "$$f" ]; then \
			echo "Making $$f executable"; \
			chmod +x "$$f"; \
		fi; \
	done
	@chmod +x install.sh uninstall.sh
	@echo "✓ All scripts are executable"

verify: ## Verify the installation (run after install)
	@./scripts/10-verify-installation.sh

# Testing
test: check ## Run basic tests
	@echo "Running tests..."
	@./scripts/01-check-architecture.sh && echo "✓ Architecture check passed" || echo "✗ Architecture check failed"
	@./scripts/02-check-prerequisites.sh && echo "✓ Prerequisites check passed" || echo "✗ Prerequisites check failed"

# Linting
lint: ## Check shell scripts for issues
	@echo "Linting shell scripts..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck lib/*.sh scripts/*.sh install.sh uninstall.sh; \
	else \
		echo "shellcheck not installed, skipping"; \
	fi

# Formatting
format: ## Format shell scripts
	@echo "Formatting shell scripts..."
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -w lib/*.sh scripts/*.sh install.sh uninstall.sh; \
	else \
		echo "shfmt not installed, skipping"; \
	fi

# Cleanup
clean: ## Clean up generated files
	@echo "Cleaning up..."
	@rm -f *.log *.tmp
	@rm -rf /tmp/nemoclaw-*
	@echo "✓ Clean complete"

# Docker cleanup
docker-clean: ## Clean Docker resources
	@echo "Cleaning Docker resources..."
	@docker system prune -f 2>/dev/null || true
	@docker volume prune -f 2>/dev/null || true
	@echo "✓ Docker clean complete"

# Sandbox management
sandbox-status: ## Check sandbox status
	@openshell sandbox list 2>/dev/null || echo "OpenShell not available"

sandbox-connect: ## Connect to sandbox
	@nemoclaw my-assistant connect

sandbox-logs: ## View sandbox logs
	@nemoclaw my-assistant logs --follow

# Gateway management
gateway-status: ## Check OpenShell gateway status
	@openshell gateway status 2>/dev/null || echo "Gateway not running"

gateway-start: ## Start OpenShell gateway
	@openshell gateway start

gateway-stop: ## Stop OpenShell gateway
	@openshell gateway stop

# Data management
backup: ## Backup OpenClaw data
	@tar -czf openclaw-backup-$$(date +%Y%m%d-%H%M%S).tar.gz openclaw-data/
	@echo "✓ Backup created"

restore: ## Restore from backup (usage: make restore BACKUP=file.tar.gz)
ifndef BACKUP
	@echo "Usage: make restore BACKUP=file.tar.gz"
	@exit 1
endif
	@tar -xzf $(BACKUP)
	@echo "✓ Restored from $(BACKUP)"

# Development
dev-setup: check ## Setup development environment
	@echo "Setting up development environment..."
	@if command -v brew >/dev/null 2>&1; then \
		brew install shellcheck shfmt; \
	fi
	@echo "✓ Development environment ready"

# Help
help: ## Show this help message
	@echo "ClawBox - Secure AI Assistant in a Box"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make install              # Run full installation"
	@echo "  make uninstall            # Remove everything"
	@echo "  make check                # Verify scripts"
	@echo "  make test                 # Run tests"
	@echo "  make help                 # Show this help"
