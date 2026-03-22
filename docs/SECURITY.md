# ClawBox Security Model

This document explains ClawBox's security architecture, threat model, and best practices for secure usage.

---

## Executive Summary

ClawBox provides **defense-in-depth security** for AI-generated code execution:

| Layer | Protection | Description |
|-------|------------|-------------|
| 1. Network | Policy-based egress control | Block all outbound by default |
| 2. Process | Container isolation | Code runs in isolated environment |
| 3. Filesystem | Volume sandboxing | No access to host filesystem |
| 4. Audit | Execution logging | Full audit trail (coming soon) |

---

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         YOUR MACHINE                             │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    CLAWBOX CLI                              │ │
│  │                                                            │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │ │
│  │  │   Policy    │  │   Config    │  │   Audit Logger      │ │ │
│  │  │   Engine    │  │   Manager   │  │   (coming soon)     │ │ │
│  │  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘ │ │
│  │         │                │                     │            │ │
│  └─────────┼────────────────┼─────────────────────┼────────────┘ │
│            │                │                     │              │
│            ▼                ▼                     ▼              │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                   SANDBOX LAYER                             ││
│  │                                                             ││
│  │  ┌────────────────────────────────────────────────────────┐ ││
│  │  │              ISOLATED CONTAINER                         │ ││
│  │  │                                                        │ ││
│  │  │  ┌──────────────┐   ┌──────────────┐                   │ ││
│  │  │  │  AI Code     │   │  Limited     │                   │ ││
│  │  │  │  Execution   │◄──│  Network     │                   │ ││
│  │  │  └──────────────┘   └──────────────┘                   │ ││
│  │  │                                                        │ ││
│  │  │  • No host filesystem access                           │ ││
│  │  │  • Network policies enforced                           │ ││
│  │  │  • Process isolation                                   │ ││
│  │  │  • Resource limits (CPU, memory)                       │ ││
│  │  └────────────────────────────────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                  HOST PROTECTIONS                           ││
│  │                                                            ││
│  │  • Read-only mounted volumes                               ││
│  │  • No privileged containers                                ││
│  │  • User namespace mapping                                  ││
│  │  • Seccomp profile applied                                 ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

---

## Threat Model

### What ClawBox Protects Against

| Threat | Protection | Status |
|--------|------------|--------|
| **Malicious code execution** | Container isolation | ✅ |
| **Data exfiltration** | Network policies | ✅ |
| **Filesystem access** | Volume sandboxing | ✅ |
| **Privilege escalation** | No privileged containers | ✅ |
| **Resource exhaustion** | CPU/memory limits | ✅ |
| **Side-channel attacks** | Process isolation | 🟡 Basic |
| **Supply chain attacks** | Model verification | ❌ Planned |
| **Prompt injection** | Input validation | 🟡 Basic |

### What ClawBox Does NOT Protect Against

| Threat | Reason | Mitigation |
|--------|--------|------------|
| **Kernel exploits** | Container isolation shares kernel | Keep kernel updated |
| **Physical access** | Out of scope | Encrypt your disk |
| **Compromised host** | Sandbox can't protect host | Secure your machine |
| **Social engineering** | Human factor | Security training |

---

## Network Policy System

### Default Deny Model

ClawBox uses a **default deny** network policy. All outbound connections are blocked unless explicitly allowed.

```
┌─────────────────────────────────────┐
│        SANDBOX CONTAINER            │
│                                     │
│   ┌──────────────────────────┐     │
│   │    APPLICATION           │     │
│   │                          │     │
│   │   ┌──────────────────┐   │     │
│   │   │  Network Stack   │   │     │
│   │   └────────┬─────────┘   │     │
│   │            │             │     │
│   └────────────┼─────────────┘     │
│                │                    │
│   ┌────────────▼─────────────┐     │
│   │   POLICY ENGINE          │     │
│   │                          │     │
│   │   Default: DENY ALL      │     │
│   │   Allow: github.com:443  │     │
│   │   Allow: api.slack.com   │     │
│   │   Block: *:*             │     │
│   └────────────┬─────────────┘     │
│                │                    │
└────────────────┼────────────────────┘
                 │
                 ▼
         ┌──────────────┐
         │   INTERNET   │
         └──────────────┘
```

### Built-in Policy Presets

Each preset allows only specific endpoints:

| Preset | Allowed Endpoints | Use Case |
|--------|-------------------|----------|
| `github` | api.github.com, github.com | Git operations, issue management |
| `docker` | registry-1.docker.io, auth.docker.io | Container pulls |
| `npm` | registry.npmjs.org | Node.js package management |
| `pypi` | pypi.org, files.pythonhosted.org | Python package management |
| `slack` | api.slack.com, slack.com | Slack integrations |
| `discord` | discord.com, gateway.discord.gg | Discord bots |
| `telegram` | api.telegram.org | Telegram bots |
| `huggingface` | huggingface.co, cdn.huggingface.co | Model downloads |
| `jira` | api.atlassian.com, atlassian.net | Issue tracking |
| `outlook` | graph.microsoft.com, outlook.office.com | Email integration |

### Custom Policies

Create custom policies for internal endpoints:

```bash
# Allow internal API
clawbox policy custom my-sandbox \
  --host api.internal.company.com \
  --port 443

# Allow multiple ports
clawbox policy custom my-sandbox \
  --host db.internal.company.com \
  --port 5432 \
  --port 6432
```

---

## Container Isolation

### Security Features

| Feature | Description | Enabled by Default |
|---------|-------------|-------------------|
| **User namespace** | Maps container user to unprivileged host user | ✅ |
| **PID namespace** | Isolated process tree | ✅ |
| **Network namespace** | Isolated network stack | ✅ |
| **Mount namespace** | Isolated filesystem | ✅ |
| **IPC namespace** | Isolated IPC | ✅ |
| **UTS namespace** | Isolated hostname | ✅ |
| **Seccomp** | System call filtering | ✅ |
| **No new privileges** | Prevents setuid binaries | ✅ |
| **Read-only root** | Read-only container root filesystem | ✅ |

### Resource Limits

Default limits prevent resource exhaustion:

| Resource | Default Limit | Configurable |
|----------|---------------|--------------|
| CPU | 2 cores | Yes |
| Memory | 4 GB | Yes |
| PIDs | 1024 | Yes |
| File descriptors | 65536 | Yes |

---

## Filesystem Isolation

### Volume Mounting

Only specified directories are accessible:

```
┌─────────────────────────────────────────────────────┐
│                 HOST FILESYSTEM                      │
│                                                      │
│   /Users/you/                                        │
│   ├── .clawbox/                    (Config)          │
│   ├── projects/                                      │
│   │   └── my-app/                  (Mounted RO)     │
│   └── sensitive-data/              (NOT MOUNTED)     │
│                                                      │
└─────────────────────────────────────────────────────┘
                         │
                         │ Mount Points
                         ▼
┌─────────────────────────────────────────────────────┐
│              SANDBOX CONTAINER                       │
│                                                      │
│   /workspace/                                        │
│   ├── my-app/                     (Read-Only)       │
│   ├── output/                     (Read-Write)       │
│   └── .clawbox-config/            (Read-Only)       │
│                                                      │
│   NO ACCESS TO:                                      │
│   • ~/.ssh/                                          │
│   • ~/.aws/                                          │
│   • /etc/passwd                                      │
│   • Sensitive files                                  │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### Best Practices

1. **Mount read-only by default** - Only mount write access when needed
2. **Minimize mount points** - Only mount what's necessary
3. **Use dedicated directories** - Keep sandboxed files separate
4. **Audit mounts** - Review what's accessible

---

## Audit Logging (Coming Soon)

### Planned Features

| Event | Logged | Retention |
|-------|--------|-----------|
| Sandbox create/delete | ✅ | 90 days |
| Sandbox start/stop | ✅ | 90 days |
| Policy changes | ✅ | 90 days |
| Code execution | ✅ | 30 days |
| Network connections | ✅ | 30 days |
| File access | ✅ | 30 days |

### Log Format

```json
{
  "timestamp": "2026-03-22T12:00:00Z",
  "event": "sandbox.execute",
  "sandbox": "dev",
  "user": "you",
  "action": {
    "type": "code_execution",
    "language": "python",
    "file": "script.py",
    "hash": "sha256:abc123..."
  },
  "network": {
    "allowed": ["github.com:443"],
    "blocked": ["unknown-server.com:443"]
  },
  "result": {
    "status": "success",
    "exit_code": 0,
    "duration_ms": 1234
  }
}
```

---

## Security Best Practices

### For Users

1. **Keep ClawBox updated**
   ```bash
   clawbox update
   ```

2. **Use minimal policies**
   - Only allow endpoints you need
   - Review policies regularly

3. **Mount read-only when possible**
   ```bash
   clawbox sandbox create dev --mount ./src:ro
   ```

4. **Review logs regularly** (when available)
   ```bash
   clawbox logs dev --follow
   ```

5. **Don't run as root**
   - ClawBox runs containers as unprivileged user
   - Never use `sudo clawbox sandbox start`

### For Developers

1. **Validate all inputs**
   - Sanitize prompts before sending to AI
   - Validate file paths

2. **Use secrets management**
   - Never hardcode API keys
   - Use environment variables or vault

3. **Follow principle of least privilege**
   - Request minimum permissions
   - Don't request network access unless needed

---

## Security Contact

### Reporting Vulnerabilities

**Do NOT report security vulnerabilities publicly.**

Email: security@clawbox.ai

We will:
1. Acknowledge receipt within 24 hours
2. Investigate and confirm within 72 hours
3. Fix and release patch within 30 days
4. Credit you in release notes (if desired)

### Security Updates

- Subscribe to security advisories: https://github.com/clawboxhq/clawbox-installer/security/advisories
- Join #security-advisories on Discord

---

## Compliance

### Supported Standards

| Standard | Status | Notes |
|----------|--------|-------|
| **SOC 2 Type II** | 🟡 Planned | Enterprise feature |
| **GDPR** | ✅ | Data stays on your machine |
| **HIPAA** | 🟡 Planned | Healthcare compliance |
| **PCI DSS** | 🟡 Planned | Payment card compliance |

---

## FAQ

### Is ClawBox secure enough for production?

ClawBox provides strong isolation for development and testing. For production workloads with sensitive data, additional hardening may be required.

### Can AI-generated code escape the sandbox?

Extremely unlikely. Container isolation, namespaces, and seccomp provide multiple layers of protection. However, kernel exploits could theoretically bypass this.

### What if I need to access more endpoints?

Use custom policies:
```bash
clawbox policy custom my-sandbox --host api.example.com --port 443
```

### How do I verify ClawBox is working correctly?

Run diagnostics:
```bash
clawbox doctor --verbose
```

---

## Changelog

| Version | Security Changes |
|---------|------------------|
| 0.1.0 | Initial security architecture |
| 0.2.0 | (Planned) Audit logging |
| 0.3.0 | (Planned) Model verification |
