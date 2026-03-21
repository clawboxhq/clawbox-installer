# ClawBox Windows Installer
# PowerShell script for one-click installation on Windows

param(
    [string]$Version = "0.4.0",
    [string]$InstallDir = "",
    [switch]$Uninstall,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Default install directory
if ([string]::IsNullOrEmpty($InstallDir)) {
    $InstallDir = "$env:LOCALAPPDATA\ClawBox"
}

$BinaryName = "clawbox-$Version-windows-$($env:PROCESSOR_ARCHITECTURE.ToLower())"
if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    $BinaryName = "clawbox-$Version-windows-amd64"
} elseif ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
    $BinaryName = "clawbox-$Version-windows-arm64"
}

$DownloadUrl = "https://github.com/clawboxhq/clawbox-installer/releases/download/v$Version/$BinaryName.exe"
$ExePath = "$InstallDir\clawbox.exe"

function Show-Banner {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║        ClawBox Installer v$Version        ║" -ForegroundColor Blue
    Write-Host "║    Secure AI Assistant in a Box         ║" -ForegroundColor Blue
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

function Add-ToPath {
    param([string]$Path)
    
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$Path*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$Path", "User")
        Write-Host "Added $Path to PATH" -ForegroundColor Green
        Write-Host "Please restart your terminal for PATH changes to take effect" -ForegroundColor Yellow
    }
}

function Install-ClawBox {
    Show-Banner
    
    Write-Host "Detected Architecture: $env:PROCESSOR_ARCHITECTURE" -ForegroundColor Blue
    Write-Host "Install Directory: $InstallDir" -ForegroundColor Blue
    Write-Host ""
    
    # Create install directory
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        Write-Host "Created directory: $InstallDir" -ForegroundColor Green
    }
    
    # Download binary
    Write-Host "Downloading ClawBox..." -ForegroundColor Blue
    
    try {
        # Use .NET WebClient for better compatibility
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($DownloadUrl, $ExePath)
    } catch {
        Write-Host "Download failed: $_" -ForegroundColor Red
        Write-Host "Please download manually from: $DownloadUrl" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Downloaded to: $ExePath" -ForegroundColor Green
    
    # Add to PATH
    Add-ToPath $InstallDir
    
    # Verify installation
    if (Test-Path $ExePath) {
        Write-Host ""
        Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║      Installation Successful!           ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "Version: $Version" -ForegroundColor Blue
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Blue
        Write-Host "  1. Open a new PowerShell or Command Prompt"
        Write-Host "  2. Run: clawbox install"
        Write-Host "  3. Follow the interactive setup"
        Write-Host ""
        Write-Host "Documentation: https://github.com/clawboxhq/clawbox-installer" -ForegroundColor Blue
    }
}

function Uninstall-ClawBox {
    if (Test-Path $ExePath) {
        Remove-Item $ExePath -Force
        Write-Host "ClawBox uninstalled successfully" -ForegroundColor Green
    } else {
        Write-Host "ClawBox not found at $ExePath" -ForegroundColor Yellow
    }
}

function Show-Help {
    Write-Host "ClawBox Windows Installer"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  iex (irm https://clawbox.ai/install.ps1)"
    Write-Host "  .\install.ps1 [-Version <version>] [-InstallDir <path>]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Version       Version to install (default: $Version)"
    Write-Host "  -InstallDir    Installation directory (default: $InstallDir)"
    Write-Host "  -Uninstall     Remove ClawBox"
    Write-Host "  -Help          Show this help"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\install.ps1"
    Write-Host "  .\install.ps1 -Version 0.4.0"
    Write-Host "  .\install.ps1 -InstallDir 'C:\Tools\ClawBox'"
    Write-Host "  .\install.ps1 -Uninstall"
}

# Main
if ($Help) {
    Show-Help
} elseif ($Uninstall) {
    Uninstall-ClawBox
} else {
    Install-ClawBox
}
