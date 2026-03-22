# ClawBox Architecture

This document explains the internal architecture of ClawBox, including its relationship with OpenShell and NemoClaw.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USER INTERFACE                              │
│                                                                      │
│   CLI (clawbox)           TUI (monitor)         Web UI (planned)    │
│   ┌─────────────┐        ┌─────────────┐       ┌─────────────┐     │
│   │ clawbox     │        │ clawbox     │       │ Browser     │     │
│   │ sandbox ... │        │ monitor     │       │ Interface   │     │
│   └──────┬──────┘        └──────┬──────┘       └──────┬──────┘     │
│          │                      │                      │            │
└──────────┼──────────────────────┼──────────────────────┼───────────┘
           │                      │                      │
           ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        CLAWBOX CORE                                   │
│                                                                      │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐ │
│   │    CLI      │  │   Config    │  │         Policy Engine       │ │
│   │   Parser    │  │   Manager   │  │  ┌───────────────────────┐  │ │
│   └──────┬──────┘  └──────┬──────┘  │  │  Network Policy       │  │ │
│          │                │         │  │  Sandbox Policy       │  │ │
│          │                │         │  │  Custom Endpoints     │  │ │
│          │                │         │  └───────────────────────┘  │ │
│          │                │         └─────────────────────────────┘ │
│          │                │                                          │
│   ┌──────▼────────────────▼──────────────────────────────────────┐  │
│   │                    PROVIDER MANAGER                           │  │
│   │                                                              │  │
│   │   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────┐ │  │
│   │   │ Ollama  │  │ OpenAI  │  │Anthropic│  │    Custom       │ │  │
│   │   │ Client  │  │ Client  │  │ Client  │  │    Provider     │ │  │
│   │   └────┬────┘  └────┬────┘  └────┬────┘  └────────┬────────┘ │  │
│   └────────┼────────────┼────────────┼─────────────────┼──────────┘  │
│            │            │            │                 │             │
└────────────┼────────────┼────────────┼─────────────────┼─────────────┘
             │            │            │                 │
             ▼            ▼            ▼                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      SANDBOX LAYER                                    │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                    OpenShell Runtime                         │   │
│   │                                                             │   │
│   │   ┌─────────────────────────────────────────────────────┐   │   │
│   │   │              NemoClaw Engine                         │   │   │
│   │   │                                                     │   │   │
│   │   │   ┌─────────────────────────────────────────────┐   │   │   │
│   │   │   │           Isolated Container                 │   │   │   │
│   │   │   │                                             │   │   │   │
│   │   │   │    ┌───────────────────────────────────┐    │   │   │   │
│   │   │   │    │        AI Execution               │    │   │   │   │
│   │   │   │    │                                     │    │   │   │   │
│   │   │   │    │  • Code Generation                 │    │   │   │   │
│   │   │   │    │  • Code Execution                  │    │   │   │   │
│   │   │   │    │  • File Operations                 │    │   │   │   │
│   │   │   │    │  • Network Calls (policy-enforced) │    │   │   │   │
│   │   │   │    └───────────────────────────────────┘    │   │   │   │
│   │   │   │                                             │   │   │   │
│   │   │   └─────────────────────────────────────────────┘   │   │   │
│   │   │                                                     │   │   │
│   │   └─────────────────────────────────────────────────────┘   │   │
│   │                                                             │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Component Overview

### 1. CLI Layer

The CLI is the primary interface for ClawBox users.

**Technology:** Go with Cobra framework

**Key Files:**
```
cmd/clawbox/
├── main.go          # Entry point
└── cmd/
    ├── root.go      # Root command
    ├── sandbox.go   # Sandbox commands
    ├── provider.go  # Provider commands
    ├── policy.go    # Policy commands
    ├── inference.go # Inference commands
    ├── config.go    # Config commands
    ├── doctor.go    # Diagnostics
    └── version.go   # Version info
```

**Command Flow:**
```
User Input → Cobra Parser → Command Handler → Internal API → Output
```

### 2. Configuration Manager

Manages user configuration stored in `~/.clawbox/config.json`.

**Configuration Structure:**
```go
type Config struct {
    DefaultProvider string              `json:"defaultProvider"`
    Providers       map[string]Provider `json:"providers"`
    Sandboxes       []SandboxConfig     `json:"sandboxes"`
    ContainerRuntime string             `json:"containerRuntime"`
}

type Provider struct {
    Name         string `json:"name"`
    Type         string `json:"type"`
    Endpoint     string `json:"endpoint"`
    APIKey       string `json:"apiKey,omitempty"`
    DefaultModel string `json:"defaultModel"`
}

type SandboxConfig struct {
    Name           string   `json:"name"`
    Provider       string   `json:"provider"`
    Model          string   `json:"model"`
    Port           int      `json:"port"`
    Policies       []string `json:"policies"`
    CustomPolicies []CustomPolicy `json:"customPolicies"`
}
```

### 3. Policy Engine

Enforces network and sandbox policies.

**Policy Types:**

| Type | Scope | Enforcement |
|------|-------|-------------|
| Network | Outbound connections | Container firewall |
| Sandbox | Filesystem, resources | Container config |
| Custom | User-defined | Application-level |

**Policy Resolution:**
```
Default Policy (deny all)
    ↓
Apply Preset Policies (github, slack, etc.)
    ↓
Apply Custom Policies (user-defined)
    ↓
Final Policy
```

### 4. Provider Manager

Abstracts multiple LLM providers behind a unified interface.

**Provider Interface:**
```go
type Provider interface {
    // Core methods
    Name() string
    Type() string
    
    // Model methods
    ListModels() ([]Model, error)
    GetModel(id string) (Model, error)
    
    // Inference methods
    Complete(prompt string, opts ...Option) (string, error)
    Stream(prompt string, opts ...Option) (<-chan string, error)
    
    // Health check
    Test() error
}
```

**Provider Adapters:**
- `OllamaProvider` - Local Ollama
- `OpenAIProvider` - OpenAI API
- `AnthropicProvider` - Anthropic API
- `CustomProvider` - OpenAI-compatible endpoints

---

## OpenShell Integration

### What is OpenShell?

OpenShell is the sandbox runtime that ClawBox uses to execute AI-generated code securely.

**Key Features:**
- Container-based isolation
- Resource management
- Process supervision
- Network policy enforcement

### How ClawBox Uses OpenShell

```
┌─────────────────────────────────────────────────────────────┐
│                        ClawBox                                │
│                                                              │
│   1. Creates sandbox configuration                           │
│   2. Generates policy files                                  │
│   3. Calls OpenShell API                                     │
│   4. Monitors sandbox status                                 │
│                                                              │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ OpenShell API
                             │ (gRPC/REST)
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                       OpenShell                               │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                  Sandbox Manager                     │   │
│   │                                                     │   │
│   │   • Create/Destroy containers                       │   │
│   │   • Apply network policies                          │   │
│   │   • Mount volumes                                   │   │
│   │   • Set resource limits                             │   │
│   │                                                     │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                  Process Supervisor                  │   │
│   │                                                     │   │
│   │   • Start/Stop processes                            │   │
│   │   • Monitor health                                  │   │
│   │   • Collect logs                                    │   │
│   │                                                     │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### OpenShell Commands Used

| ClawBox Command | OpenShell Call |
|-----------------|----------------|
| `sandbox create` | `openshell create <config>` |
| `sandbox start` | `openshell start <id>` |
| `sandbox stop` | `openshell stop <id>` |
| `sandbox delete` | `openshell destroy <id>` |
| `sandbox logs` | `openshell logs <id>` |

---

## NemoClaw Integration

### What is NemoClaw?

NemoClaw provides the AI inference engine optimized for NVIDIA hardware.

**Key Features:**
- GPU-accelerated inference
- Model management
- Multi-model serving
- Streaming responses

### How ClawBox Uses NemoClaw

```
┌─────────────────────────────────────────────────────────────┐
│                        ClawBox                                │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │               Provider Manager                       │   │
│   │                                                     │   │
│   │   • Detects NemoClaw availability                   │   │
│   │   • Routes inference requests                       │   │
│   │   • Handles model switching                         │   │
│   │                                                     │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ NemoClaw API
                             │ (OpenAI-compatible)
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                       NemoClaw                                │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                  Model Server                        │   │
│   │                                                     │   │
│   │   • Load/unload models                              │   │
│   │   • GPU memory management                           │   │
│   │   • Inference optimization                          │   │
│   │                                                     │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                  API Gateway                         │   │
│   │                                                     │   │
│   │   • OpenAI-compatible endpoints                     │   │
│   │   • Authentication                                  │   │
│   │   • Rate limiting                                   │   │
│   │                                                     │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Creating a Sandbox

```
User                ClawBox CLI           OpenShell            Container
  │                      │                     │                    │
  │  sandbox create      │                     │                    │
  │─────────────────────►│                     │                    │
  │                      │                     │                    │
  │                      │ Validate config     │                    │
  │                      │────────────────────►│                    │
  │                      │                     │                    │
  │                      │                     │ Create container   │
  │                      │                     │───────────────────►│
  │                      │                     │                    │
  │                      │                     │     Container ID   │
  │                      │                     │◄───────────────────│
  │                      │                     │                    │
  │                      │     Sandbox ID      │                    │
  │                      │◄────────────────────│                    │
  │                      │                     │                    │
  │      Sandbox created │                     │                    │
  │◄─────────────────────│                     │                    │
  │                      │                     │                    │
```

### Running AI Inference

```
User                ClawBox CLI           Provider            AI Model
  │                      │                     │                    │
  │  Generate code       │                     │                    │
  │─────────────────────►│                     │                    │
  │                      │                     │                    │
  │                      │ Route to provider   │                    │
  │                      │────────────────────►│                    │
  │                      │                     │                    │
  │                      │                     │ Inference request  │
  │                      │                     │───────────────────►│
  │                      │                     │                    │
  │                      │                     │    Generated code  │
  │                      │                     │◄───────────────────│
  │                      │                     │                    │
  │                      │      Response       │                    │
  │                      │◄────────────────────│                    │
  │                      │                     │                    │
  │                      │ Execute in sandbox  │                    │
  │                      │────────────────────────────────────────►│
  │                      │                     │                    │
  │                      │                  Execution result        │
  │                      │◄────────────────────────────────────────│
  │                      │                     │                    │
  │      Result          │                     │                    │
  │◄─────────────────────│                     │                    │
  │                      │                     │                    │
```

---

## Security Boundaries

```
┌─────────────────────────────────────────────────────────────┐
│                      TRUSTED ZONE                             │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                   Host System                        │   │
│   │                                                     │   │
│   │   • ClawBox CLI                                     │   │
│   │   • Configuration                                   │   │
│   │   • User data                                       │   │
│   │                                                     │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   Security Boundary (Container Isolation)                    │
│   ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
│   . . . . . . . . . . . . . . . . . . . . . . . . . . . . .│
│   ┌─────────────────────────────────────────────────────┐   │
│   │                  UNTRUSTED ZONE                     │   │
│   │                                                     │   │
│   │   ┌─────────────────────────────────────────────┐   │   │
│   │   │            Sandbox Container                │   │   │
│   │   │                                             │   │   │
│   │   │   • AI-generated code                      │   │   │
│   │   │   • Network calls (policy-enforced)        │   │   │
│   │   │   • File operations (volume-limited)       │   │   │
│   │   │                                             │   │   │
│   │   └─────────────────────────────────────────────┘   │   │
│   │                                                     │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Extensibility

### Adding a New Provider

```go
// 1. Implement Provider interface
type MyProvider struct {
    name     string
    endpoint string
    apiKey   string
}

func (p *MyProvider) Complete(prompt string, opts ...Option) (string, error) {
    // Implementation
}

func (p *MyProvider) Test() error {
    // Implementation
}

// 2. Register in provider manager
func init() {
    RegisterProvider("myprovider", NewMyProvider)
}
```

### Adding a New Policy Preset

```go
// In internal/policy/presets.go
var PresetPolicies = map[string]Policy{
    "my-preset": {
        Name: "my-preset",
        Description: "My custom preset",
        Endpoints: []Endpoint{
            {Host: "api.example.com", Port: 443},
        },
    },
}
```

---

## Performance Considerations

### Startup Time

| Component | Time | Optimization |
|-----------|------|---------------|
| CLI parsing | <10ms | Native Go |
| Config load | <50ms | JSON unmarshal |
| Provider init | 100-500ms | Lazy loading |
| Container start | 2-5s | Pre-pulled images |

### Memory Usage

| Component | Memory | Notes |
|-----------|--------|-------|
| ClawBox CLI | ~20MB | Go binary |
| Config | ~1MB | JSON in memory |
| Per sandbox | ~100MB | Container overhead |
| AI model | 2-16GB | Depends on model |

---

## Future Architecture

Planned improvements:

1. **Web UI** - Browser-based interface
2. **gRPC API** - High-performance internal communication
3. **Plugin System** - Extensible architecture
4. **Distributed Mode** - Multi-machine deployment
5. **Model Registry** - Centralized model management
