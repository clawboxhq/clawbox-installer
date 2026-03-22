# Download ClawBox

ClawBox is a secure AI assistant that runs entirely on your machine. Choose your platform for easy installation.

---

## Easy Install (Recommended for Most Users)

=== "macOS"

    ### Option 1: DMG Installer (Easiest)
    
    1. Download the DMG for your Mac:
       - [ClawBox for Apple Silicon (M1/M2/M3/M4)](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/ClawBox-0.4.0-macos-arm64.dmg)
       - [ClawBox for Intel Mac](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/ClawBox-0.4.0-macos-amd64.dmg)
    
    2. **Double-click** the downloaded `.dmg` file
    
    3. **Drag** ClawBox.app to the Applications folder
    
    4. **Open** Applications and double-click ClawBox
    
    !!! warning "Security Warning"
        If you see "unidentified developer" warning:
        
        - Right-click (or Control-click) ClawBox.app
        - Select **Open** from the menu
        - Click **Open** in the dialog
    
    ---
    
    ### Option 2: Terminal Install
    
    ```bash
    curl -fsSL https://github.com/clawboxhq/clawbox-installer/releases/latest/download/install.sh | bash
    ```

=== "Windows"

    ### Option 1: Windows Installer (Easiest)
    
    1. [Download ClawBox Setup](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/ClawBox-Setup-0.4.0.exe)
    
    2. **Double-click** the downloaded `.exe` file
    
    3. Follow the setup wizard:
       - Accept the license
       - Choose install location
       - Click **Install**
    
    !!! warning "Windows Defender Warning"
        You may see a SmartScreen warning. Click **"Run anyway"** to proceed.
    
    ---
    
    ### Option 2: PowerShell Install
    
    ```powershell
    iex (irm https://github.com/clawboxhq/clawbox-installer/releases/latest/download/install.ps1)
    ```

=== "Linux"

    ### Option 1: Package Manager (Easiest)
    
    **Debian/Ubuntu:**
    
    1. [Download .deb package](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox_0.4.0_amd64.deb)
    
    2. **Double-click** the `.deb` file
    
    3. Click **Install** in Software Center
    
    Or via terminal:
    ```bash
    sudo apt install ./clawbox_0.4.0_amd64.deb
    ```
    
    ---
    
    **Fedora/RHEL:**
    
    1. [Download .rpm package](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-0.4.0-1.x86_64.rpm)
    
    2. **Double-click** the `.rpm` file
    
    Or via terminal:
    ```bash
    sudo dnf install ./clawbox-0.4.0-1.x86_64.rpm
    ```
    
    ---
    
    ### Option 2: Terminal Install
    
    ```bash
    curl -fsSL https://github.com/clawboxhq/clawbox-installer/releases/latest/download/install.sh | bash
    ```

---

## All Downloads

| Platform | Easy Install | Binary Only | Checksum |
|----------|--------------|-------------|----------|
| macOS (Apple Silicon) | [ClawBox-0.4.0-macos-arm64.dmg](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/ClawBox-0.4.0-macos-arm64.dmg) | [clawbox-0.4.0-darwin-arm64](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-0.4.0-darwin-arm64) | [checksums.txt](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/checksums.txt) |
| macOS (Intel) | [ClawBox-0.4.0-macos-amd64.dmg](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/ClawBox-0.4.0-macos-amd64.dmg) | [clawbox-0.4.0-darwin-amd64](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-0.4.0-darwin-amd64) | [checksums.txt](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/checksums.txt) |
| Windows (x64) | [ClawBox-Setup-0.4.0.exe](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/ClawBox-Setup-0.4.0.exe) | [clawbox-0.4.0-windows-amd64.exe](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-0.4.0-windows-amd64.exe) | [checksums.txt](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/checksums.txt) |
| Windows (ARM64) | [ClawBox-Setup-0.4.0.exe](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/ClawBox-Setup-0.4.0.exe) | [clawbox-0.4.0-windows-arm64.exe](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-0.4.0-windows-arm64.exe) | [checksums.txt](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/checksums.txt) |
| Linux (Debian x64) | [clawbox_0.4.0_amd64.deb](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox_0.4.0_amd64.deb) | [clawbox-0.4.0-linux-amd64](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-0.4.0-linux-amd64) | [checksums.txt](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/checksums.txt) |
| Linux (Debian ARM64) | [clawbox_0.4.0_arm64.deb](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox_0.4.0_arm64.deb) | [clawbox-0.4.0-linux-arm64](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-0.4.0-linux-arm64) | [checksums.txt](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/checksums.txt) |
| Linux (Fedora x64) | [clawbox-0.4.0-1.x86_64.rpm](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-0.4.0-1.x86_64.rpm) | [clawbox-0.4.0-linux-amd64](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-0.4.0-linux-amd64) | [checksums.txt](https://github.com/clawboxhq/clawbox-installer/releases/latest/download/checksums.txt) |

---

## System Requirements

| Platform | Requirements |
|----------|--------------|
| macOS | macOS 11+ (Big Sur or later) |
| Linux | glibc 2.31+ (Ubuntu 20.04+, Debian 11+, Fedora 34+) |
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

You should see:
```
clawbox version 0.4.0
```

---

## Next Steps

1. **Run** `clawbox install` to set up your AI environment
2. **Follow** the interactive setup wizard
3. **Start** using ClawBox with `clawbox chat`

---

## Troubleshooting

### macOS: "App is damaged and can't be opened"

This is Gatekeeper blocking unsigned apps. Fix:

```bash
xattr -cr /Applications/ClawBox.app
```

Then open the app again.

### macOS: "unidentified developer" warning

1. Right-click (Control-click) ClawBox.app
2. Select **Open** from the menu
3. Click **Open** in the dialog

### Windows: "Windows protected your PC"

1. Click **More info**
2. Click **Run anyway**

### Windows: "Command not found" after install

1. Open a new PowerShell window
2. Or restart your computer

### Linux: "command not found" after install

```bash
source ~/.bashrc   # or ~/.zshrc
```

---

## Previous Releases

See all releases on [GitHub Releases](https://github.com/clawboxhq/clawbox-installer/releases).
