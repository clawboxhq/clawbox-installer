# Post-Installation Guide

This guide covers what to do after successfully installing NemoClaw on your macOS system.

## Quick Reference

| Task | Command |
|------|---------|
| Connect to sandbox | `nemoclaw my-assistant connect` |
| Launch OpenClaw TUI | `openclaw tui` |
| Monitor network | `openshell term` |
| Check status | `nemoclaw my-assistant status` |
| View logs | `nemoclaw my-assistant logs --follow` |

## Inside the Sandbox

When you connect to the sandbox, you're in an isolated environment running OpenClaw:

```bash
nemoclaw my-assistant connect
```

Inside the sandbox:

| Command | Description |
|---------|-------------|
| `openclaw tui` | Launch terminal UI (recommended) |
| `openclaw agent -m "hello"` | Send a quick message |
| `openclaw gateway status` | Check gateway status |
| `openclaw doctor` | Run diagnostics |
| `openclaw --help` | Show all commands |

To exit the sandbox:
```
exit
```

## Using the Web Dashboard

The OpenClaw dashboard is forwarded to your host:

```
http://127.0.0.1:18789
```

1. Open the URL in your browser
2. If prompted for a token, get it from:
   ```bash
   # Inside sandbox
   openclaw gateway token
   ```

## Configuring Channels

OpenClaw supports 20+ messaging channels. Configure them in your sandbox:

### Telegram

```bash
# In sandbox
openclaw channels add telegram --token YOUR_BOT_TOKEN
```

### Discord

```bash
# In sandbox
openclaw channels add discord --token YOUR_BOT_TOKEN
```

### WhatsApp

```bash
# In sandbox - will show QR code
openclaw channels add whatsapp
```

### WebChat

WebChat is enabled by default at `http://127.0.0.1:18789/webchat`

## Managing Skills

Skills are stored in your persistent `workspace/skills/` directory.

### Adding Skills

```bash
# Create a skill
mkdir -p openclaw-data/workspace/skills/my-skill
cat > openclaw-data/workspace/skills/my-skill/SKILL.md << 'EOF'
# My Custom Skill

Provide a brief description of what this skill does.

## Usage

When the user asks to [specific trigger], follow these steps:
1. Step one
2. Step two
3. Step three
EOF
```

### Built-in Skills

OpenClaw includes many built-in skills. List them:
```bash
# Inside sandbox
openclaw skills list
```

## Customizing Agent Behavior

Edit these files in your persistent workspace:

### AGENTS.md

Controls agent behavior and capabilities:

```bash
cat > openclaw-data/workspace/AGENTS.md << 'EOF'
# Agent Configuration

## Identity
You are a helpful AI assistant running securely in an OpenShell sandbox.

## Capabilities
- You can execute shell commands safely
- You have access to the workspace directory
- You can search the web via Brave API

## Constraints
- Always ask before running potentially destructive commands
- Never share API keys or credentials
- Prefer read-only operations unless explicitly asked
EOF
```

### SOUL.md

Defines agent personality:

```bash
cat > openclaw-data/workspace/SOUL.md << 'EOF'
# Personality

## Traits
- Friendly and approachable
- Precise and thorough
- Helpful without being pushy

## Communication Style
- Clear, concise responses
- Use code blocks for technical content
- Explain reasoning when asked
EOF
```

## Security Features

Your sandbox has multiple security layers:

| Layer | Protection |
|-------|------------|
| **Filesystem** | Cannot read/write outside allowed paths |
| **Network** | Only NVIDIA API endpoints allowed |
| **Process** | Cannot escalate privileges |
| **Inference** | Credentials stripped, routed through gateway |

### Viewing Active Policy

```bash
# Host
openshell policy get my-assistant

# Or view config
cat config/sandbox-policy.yaml
```

### Updating Network Policy

Edit `config/sandbox-policy.yaml` and apply:

```bash
openshell policy set my-assistant --policy config/sandbox-policy.yaml
```

## Working with Files

Files in your sandbox are persisted via volume mounts:

| Host Path | Sandbox Path |
|-----------|--------------|
| `openclaw-data/.openclaw/` | `/sandbox/.openclaw/` |
| `openclaw-data/workspace/` | `/sandbox/workspace/` |

### Copying Files

```bash
# Host to sandbox
cat my-script.sh | openshell sandbox exec my-assistant -- \
  sh -c 'cat > /sandbox/workspace/my-script.sh'

# Sandbox to host (connect first)
nemoclaw my-assistant connect
# Inside sandbox
cat /sandbox/workspace/output.txt > ~/output.txt
```

## Monitoring

### OpenShell Terminal UI

```bash
openshell term
```

Keyboard shortcuts:
- `Tab` - Switch panels
- `j/k` - Navigate lists
- `Enter` - Select
- `:` - Command mode
- `q` - Quit

### Viewing Logs

```bash
# Follow logs
nemoclaw my-assistant logs --follow

# Last 100 lines
nemoclaw my-assistant logs --lines 100

# Inside sandbox
openclaw gateway logs
```

## Backup and Restore

### Backup

```bash
# Backup your OpenClaw data
tar -czf openclaw-backup-$(date +%Y%m%d).tar.gz openclaw-data/
```

### Restore

```bash
# Restore from backup
tar -xzf openclaw-backup-20260320.tar.gz
```

## Troubleshooting

### Sandbox won't start

```bash
# Check Docker
docker info

# Check OpenShell
openshell gateway status

# Recreate sandbox
openshell sandbox delete my-assistant
./scripts/09-create-sandbox.sh
```

### Gateway not responding

```bash
# Inside sandbox
openclaw doctor --fix
openclaw gateway restart
```

### Network blocked

```bash
# Check if endpoint is in policy
openshell policy get my-assistant | grep -A5 endpoints
```

## Next Steps

1. **Try the TUI**: `openclaw tui` for the best experience
2. **Configure a channel**: Add Telegram/Discord for mobile access
3. **Create custom skills**: Automate your workflows
4. **Explore the API**: https://docs.openclaw.ai

## Getting Help

- **OpenClaw Docs**: https://docs.openclaw.ai
- **NemoClaw Docs**: https://docs.nvidia.com/nemoclaw/latest/
- **Discord**: https://discord.gg/XFpfPv9Uvx
- **GitHub Issues**: https://github.com/NVIDIA/NemoClaw/issues
