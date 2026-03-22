## ClawBox v${VERSION}

Secure AI Assistant in a Box - One-click cross-platform installer for OpenShell + NemoClaw + OpenClaw with secure sandboxing and persistent volume mounting.

---

### Easy Installation (Recommended)

**macOS:**
- Download `.dmg` → Double-click → Drag to Applications
- [Apple Silicon (M1/M2/M3/M4)](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/ClawBox-${VERSION}-macos-arm64.dmg)
- [Intel Mac](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/ClawBox-${VERSION}-macos-amd64.dmg)

**Windows:**
- Download `.exe` → Double-click → Follow setup wizard
- [Windows Installer](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/ClawBox-Setup-${VERSION}.exe)

**Linux:**
- Download `.deb` or `.rpm` → Double-click → Install
- [Debian/Ubuntu (.deb)](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/clawbox_${VERSION}_amd64.deb)
- [Fedora/RHEL (.rpm)](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/clawbox-${VERSION}-1.x86_64.rpm)

---

### Features

- **One-Click GUI Installers** - Double-click to install on any platform
- **Network Policy Management** - Control sandbox network access with presets
- **Inference Routing** - Switch providers and models at runtime
- **Multi-Provider Support** - NVIDIA, OpenAI, Anthropic, Ollama, and more
- **Secure Sandboxing** - Isolated AI execution environment
- **Persistent Volumes** - Your data persists across sessions
- **Shell Completions** - Bash, Zsh, and Fish support
- **Telegram Integration** - Control via mobile with opencode-telegram-bot

---

### All Downloads

#### macOS
| Type | Architecture | Download |
|------|--------------|----------|
| DMG Installer | Apple Silicon (M1/M2/M3/M4) | [ClawBox-${VERSION}-macos-arm64.dmg](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/ClawBox-${VERSION}-macos-arm64.dmg) |
| DMG Installer | Intel | [ClawBox-${VERSION}-macos-amd64.dmg](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/ClawBox-${VERSION}-macos-amd64.dmg) |
| Binary | Apple Silicon | [clawbox-${VERSION}-darwin-arm64](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/clawbox-${VERSION}-darwin-arm64) |
| Binary | Intel | [clawbox-${VERSION}-darwin-amd64](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/clawbox-${VERSION}-darwin-amd64) |

#### Windows
| Type | Architecture | Download |
|------|--------------|----------|
| Installer | x64 | [ClawBox-Setup-${VERSION}.exe](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/ClawBox-Setup-${VERSION}.exe) |
| Binary | x64 | [clawbox-${VERSION}-windows-amd64.exe](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/clawbox-${VERSION}-windows-amd64.exe) |
| Binary | ARM64 | [clawbox-${VERSION}-windows-arm64.exe](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/clawbox-${VERSION}-windows-arm64.exe) |

#### Linux
| Type | Distribution | Download |
|------|--------------|----------|
| .deb Package | Debian/Ubuntu (x64) | [clawbox_${VERSION}_amd64.deb](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/clawbox_${VERSION}_amd64.deb) |
| .deb Package | Debian/Ubuntu (ARM64) | [clawbox_${VERSION}_arm64.deb](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/clawbox_${VERSION}_arm64.deb) |
| .rpm Package | Fedora/RHEL (x64) | [clawbox-${VERSION}-1.x86_64.rpm](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/clawbox-${VERSION}-1.x86_64.rpm) |
| Binary | x64 | [clawbox-${VERSION}-linux-amd64](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/clawbox-${VERSION}-linux-amd64) |
| Binary | ARM64 | [clawbox-${VERSION}-linux-arm64](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/clawbox-${VERSION}-linux-arm64) |

---

### Terminal Installation (Alternative)

**macOS / Linux:**
```bash
curl -fsSL https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/install.sh | bash
```

**Windows (PowerShell):**
```powershell
iex (irm https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/install.ps1)
```

### Checksums
See [checksums.txt](https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}/checksums.txt)

---

### Security Notes

**macOS:** Unsigned DMG. To bypass Gatekeeper, right-click the app and select "Open".

**Windows:** Unsigned installer. Click "Run anyway" if you see a SmartScreen warning.

**Linux:** Packages install normally on most distributions.

---

### What's Changed
See [CHANGELOG.md](https://github.com/clawboxhq/clawbox-installer/blob/main/CHANGELOG.md) for details.
