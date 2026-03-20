# ClawBox Build Configuration

BINARY_NAME=clawbox
VERSION=0.2.0
GIT_COMMIT=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GOOS=$(shell go env GOOS)
GOARCH=$(shell go env GOARCH)

LDFLAGS=-ldflags "-X main.Version=$(VERSION) -X main.GitCommit=$(GIT_COMMIT) -X main.BuildDate=$(BUILD_DATE)"

.PHONY: all build install clean test lint completions help

all: build

build:
	go build $(LDFLAGS) -o bin/$(BINARY_NAME) ./cmd/clawbox

build-all:
	GOOS=darwin GOARCH=arm64 go build $(LDFLAGS) -o bin/clawbox-darwin-arm64 ./cmd/clawbox
	GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -o bin/clawbox-darwin-amd64 ./cmd/clawbox
	GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -o bin/clawbox-linux-arm64 ./cmd/clawbox
	GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o bin/clawbox-linux-amd64 ./cmd/clawbox

install: build
	install -m 755 bin/$(BINARY_NAME) /usr/local/bin/

install-local: build
	mkdir -p $(HOME)/.local/bin
	install -m 755 bin/$(BINARY_NAME) $(HOME)/.local/bin/

test:
	go test -v ./...

lint:
	go fmt ./...
	go vet ./...

completions:
	mkdir -p completions
	./bin/$(BINARY_NAME) completion bash > completions/clawbox.bash
	./bin/$(BINARY_NAME) completion zsh > completions/clawbox.zsh
	./bin/$(BINARY_NAME) completion fish > completions/clawbox.fish

clean:
	rm -rf bin/
	rm -f completions/*.bash completions/*.zsh completions/*.fish

mod:
	go mod tidy
	go mod download

run:
	go run ./cmd/clawbox

version:
	@echo "clawbox version $(VERSION)"
	@echo "  Platform: $(GOOS)/$(GOARCH)"
	@echo "  Git: $(GIT_COMMIT)"
	@echo "  Built: $(BUILD_DATE)"

help:
	@echo "ClawBox Build System"
	@echo ""
	@echo "Targets:"
	@echo "  build          Build binary for current platform"
	@echo "  build-all      Build binaries for all platforms"
	@echo "  install        Install to /usr/local/bin (requires sudo)"
	@echo "  install-local  Install to ~/.local/bin"
	@echo "  test           Run tests"
	@echo "  lint           Run linters"
	@echo "  completions    Generate shell completions"
	@echo "  clean          Remove build artifacts"
	@echo "  mod            Download and tidy modules"
	@echo "  run            Run without building"
	@echo "  version        Show version info"
	@echo "  help           Show this help"
