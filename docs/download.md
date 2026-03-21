# Download ClawBox

ClawBox is a secure AI assistant that runs entirely on your machine. Choose your platform below for installation instructions.

---

## One-Click Install

=== "macOS"

    Open Terminal and run:

    ```bash
    curl -fsSL https://clawbox.ai/install.sh | bash
    ```

    **Manual Download:**
    
    | Architecture | Download |
    |--------------|----------|
    | Apple Silicon (M1/M2/M3/M4) | [clawbox-darwin-arm64](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-darwin-arm64) |
    | Intel | [clawbox-darwin-amd64](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-darwin-amd64) |

    After downloading:
    ```bash
    chmod +x clawbox-*
    sudo mv clawbox-* /usr/local/bin/clawbox
    ```

=== "Linux"

    Open Terminal and run:

    ```bash
    curl -fsSL https://clawbox.ai/install.sh | bash
    ```

    **Manual Download:**
    
    | Architecture | Download |
    |--------------|----------|
    | ARM64 | [clawbox-linux-arm64](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-linux-arm64) |
    | x86_64 | [clawbox-linux-amd64](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-linux-amd64) |

    After downloading:
    ```bash
    chmod +x clawbox-*
    sudo mv clawbox-* /usr/local/bin/clawbox
    ```

    **Package Install:**
    
    Debian/Ubuntu:
    ```bash
    sudo apt install ./clawbox_0.4.0_amd64.deb
    ```
    
    RHEL/Fedora:
    ```bash
    sudo rpm -i clawbox-0.4.0.x86_64.rpm
    ```

=== "Windows"

    Open PowerShell and run:

    ```powershell
    iex (irm https://clawbox.ai/install.ps1)
    ```

    **Manual Download:**
    
    | Architecture | Download |
    |--------------|----------|
    | x86_64 | [clawbox-windows-amd64.exe](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-windows-amd64.exe) |
    | ARM64 | [clawbox-windows-arm64.exe](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-windows-arm64.exe) |

    After downloading, add to PATH:
    ```powershell
    # Move to a directory in PATH
    Move-Item clawbox-*.exe $env:LOCALAPPDATA\ClawBox\clawbox.exe
    
    # Add to PATH (permanent)
    [Environment]::SetEnvironmentVariable("Path", "$env:Path;$env:LOCALAPPDATA\ClawBox", "User")
    ```

---

## System Requirements

| Platform | Requirements |
|----------|--------------|
| macOS | macOS 11+ (Big Sur or later) |
| Linux | glibc 2.31+ (most modern distributions) |
| Windows | Windows 10+ or Windows Server 2019+ |

**Hardware:**
- 4GB RAM minimum (8GB recommended)
- 1GB disk space
- Internet connection for initial setup

---

## Verify Installation

After installation, verify ClawBox is working:

```bash
clawbox version
```

You should see output like:
```
clawbox version 0.4.0
```

---

## Next Steps

1. Run `clawbox install` to set up your AI environment
2. Follow the interactive setup wizard
3. Start using ClawBox with `clawbox chat`

---

## Troubleshooting

### "command not found" after install

**macOS/Linux:**
```bash
source ~/.zshrc   # or ~/.bashrc
```

**Windows:**
Open a new PowerShell window.

### Permission denied (macOS/Linux)

Run with sudo for system-wide install:
```bash
curl -fsSL https://clawbox.ai/install.sh | sudo bash
```

### Windows security warning

Click "More info" → "Run anyway" when prompted by Windows Defender.

---

## All Downloads

See all releases and checksums on [GitHub Releases](https://github.com/clawboxhq/clawbox-installer/releases).
