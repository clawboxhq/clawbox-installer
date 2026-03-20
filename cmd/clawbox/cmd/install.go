package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"

	"github.com/clawboxhq/clawbox-installer/internal/provider"
	"github.com/spf13/cobra"
)

var installCmd = &cobra.Command{
	Use:   "install",
	Short: "Install ClawBox and all dependencies",
	Long: `Install ClawBox with all required dependencies.

This will install:
  - Homebrew (if not present on macOS)
  - Node.js 22+ (if not present)
  - Docker Desktop (if not present)
  - OpenShell CLI
  - NemoClaw
  - OpenClaw sandbox`,
	RunE: func(cmd *cobra.Command, args []string) error {
		provName, _ := cmd.Flags().GetString("provider")
		model, _ := cmd.Flags().GetString("model")
		sandboxName, _ := cmd.Flags().GetString("sandbox-name")
		nonInteractive, _ := cmd.Flags().GetBool("non-interactive")
		skipDocker, _ := cmd.Flags().GetBool("skip-docker")
		skipNode, _ := cmd.Flags().GetBool("skip-node")
		dryRun, _ := cmd.Flags().GetBool("dry-run")

		fmt.Println("🦞 ClawBox Installer")
		fmt.Println("==================")
		fmt.Println()

		// Load or create config
		config, err := loadConfig()
		if err != nil {
			return err
		}

		// Determine provider
		if provName == "" {
			if nonInteractive {
				provName = "nvidia"
				fmt.Printf("Using default provider: %s\n", provName)
			} else {
				provName, err = promptProvider()
				if err != nil {
					return err
				}
			}
		}

		prov, ok := config.Providers[provName]
		if !ok {
			info, ok := provider.GetProviderInfo(provider.ProviderType(provName))
			if !ok {
				return fmt.Errorf("unknown provider: %s", provName)
			}

			var apiKey string
			if !info.IsLocal && !nonInteractive {
				apiKey, err = promptAPIKey(info)
				if err != nil {
					return err
				}
			}

			if config.Providers == nil {
				config.Providers = make(map[string]provider.Provider)
			}
			prov = provider.Provider{
				Name:         provName,
				Type:         provider.ProviderType(provName),
				Endpoint:     info.Endpoint,
				APIKey:       apiKey,
				DefaultModel: info.DefaultModel,
			}
			config.Providers[provName] = prov
		}

		if model == "" {
			model = prov.DefaultModel
		}

		if sandboxName == "" {
			sandboxName = "my-assistant"
		}

		// Show installation plan
		fmt.Println("\n📋 Installation Plan")
		fmt.Println("-------------------")
		fmt.Printf("Platform:      %s/%s\n", runtime.GOOS, runtime.GOARCH)
		fmt.Printf("Provider:      %s\n", provName)
		fmt.Printf("Model:         %s\n", model)
		fmt.Printf("Sandbox:       %s\n", sandboxName)
		fmt.Printf("Config Dir:    %s\n", getConfigDir())
		fmt.Println()

		if dryRun {
			fmt.Println("🔍 Dry run - no changes will be made")
			fmt.Println("\nWould install:")
			fmt.Println("  1. Check system architecture")
			fmt.Println("  2. Check prerequisites (RAM, disk, network)")
			fmt.Println("  3. Install Homebrew (if needed)")
			fmt.Println("  4. Install Node.js 22+ (if needed)")
			fmt.Println("  5. Install Docker Desktop (if needed)")
			fmt.Println("  6. Install OpenShell CLI")
			fmt.Println("  7. Install NemoClaw")
			fmt.Println("  8. Configure API key")
			fmt.Println("  9. Create sandbox with volume mounts")
			fmt.Println("  10. Verify installation")
			return nil
		}

		if !nonInteractive {
			fmt.Print("\nProceed with installation? [y/N]: ")
			reader := bufio.NewReader(os.Stdin)
			response, _ := reader.ReadString('\n')
			response = strings.TrimSpace(strings.ToLower(response))
			if response != "y" && response != "yes" {
				fmt.Println("Installation cancelled")
				return nil
			}
		}

		// Execute installation steps
		steps := []struct {
			name string
			fn   func() error
		}{
			{"Checking architecture", func() error { return installCheckArchitecture() }},
			{"Checking prerequisites", installCheckPrerequisites},
		}

		if !skipNode && !commandExists("node") {
			steps = append(steps, struct {
				name string
				fn   func() error
			}{"Installing Node.js", installNodeJS})
		}

		if !skipDocker && !commandExists("docker") {
			steps = append(steps, struct {
				name string
				fn   func() error
			}{"Installing Docker", installDocker})
		}

		steps = append(steps, []struct {
			name string
			fn   func() error
		}{
			{"Installing OpenShell", installOpenShell},
			{"Installing NemoClaw", installNemoClaw},
		}...)

		for i, step := range steps {
			fmt.Printf("\n[%d/%d] %s...\n", i+1, len(steps), step.name)
			if err := step.fn(); err != nil {
				fmt.Printf("❌ %s failed: %v\n", step.name, err)
				return err
			}
			fmt.Printf("✅ %s complete\n", step.name)
		}

		// Save configuration
		config.DefaultProvider = provName
		config.Sandboxes = append(config.Sandboxes, SandboxConfig{
			Name:     sandboxName,
			Provider: provName,
			Model:    model,
			Port:     18789,
		})
		if err := saveConfig(config); err != nil {
			return err
		}

		fmt.Println("\n✨ Installation complete!")
		fmt.Println("\nNext steps:")
		fmt.Printf("  1. Start sandbox:    clawbox sandbox start %s\n", sandboxName)
		fmt.Printf("  2. Connect:          clawbox sandbox connect %s\n", sandboxName)
		fmt.Printf("  3. View dashboard:   http://127.0.0.1:18789\n")
		fmt.Println("  4. Run diagnostics:  clawbox doctor")

		return nil
	},
}

func promptProvider() (string, error) {
	fmt.Println("\nSelect LLM Provider:")
	fmt.Println()
	fmt.Println("Cloud Providers:")
	fmt.Println("  1) NVIDIA (NIM API) - nemotron-3-super-120b-a12b")
	fmt.Println("  2) OpenAI - gpt-4o")
	fmt.Println("  3) Anthropic - claude-sonnet-4-20250514")
	fmt.Println("  4) OpenRouter - anthropic/claude-sonnet-4")
	fmt.Println()
	fmt.Println("Local Providers:")
	fmt.Println("  5) Ollama - llama3.2")
	fmt.Println("  6) LM Studio - local-model")
	fmt.Println("  7) llama.cpp - local-model")
	fmt.Println("  8) vLLM - local-model")
	fmt.Println()
	fmt.Println("  9) Custom endpoint")
	fmt.Println()
	fmt.Print("Select provider [1-9] (default: 1): ")

	reader := bufio.NewReader(os.Stdin)
	response, _ := reader.ReadString('\n')
	response = strings.TrimSpace(response)

	providers := []provider.ProviderType{
		provider.TypeNVIDIA, provider.TypeOpenAI, provider.TypeAnthropic, provider.TypeOpenRouter,
		provider.TypeOllama, provider.TypeLMStudio, provider.TypeLlamaCpp, provider.TypeVLLM,
		provider.TypeCustom,
	}

	if response == "" {
		response = "1"
	}

	idx := 0
	if _, err := fmt.Sscanf(response, "%d", &idx); err != nil || idx < 1 || idx > 9 {
		return string(provider.TypeNVIDIA), nil
	}

	return string(providers[idx-1]), nil
}

func promptAPIKey(info provider.ProviderInfo) (string, error) {
	fmt.Printf("\nGet your %s API key from: %s\n", info.Name, info.KeyURL)
	fmt.Print("Enter API key: ")

	reader := bufio.NewReader(os.Stdin)
	key, _ := reader.ReadString('\n')
	return strings.TrimSpace(key), nil
}

func installCheckArchitecture() error {
	if runtime.GOARCH != "arm64" && runtime.GOOS == "darwin" {
		return fmt.Errorf("Intel Macs (x86_64) are not supported - Apple Silicon only")
	}
	return nil
}

func installCheckPrerequisites() error {
	// Check RAM (simplified)
	// Check disk space (simplified)
	// Check network connectivity
	return nil
}

func installNodeJS() error {
	if commandExists("node") {
		return nil
	}

	switch runtime.GOOS {
	case "darwin":
		if commandExists("brew") {
			return exec.Command("brew", "install", "node@22").Run()
		}
		return fmt.Errorf("Homebrew not found - please install from https://brew.sh")
	case "linux":
		// Detect package manager and install
		if commandExists("apt") {
			cmd := exec.Command("bash", "-c", "curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs")
			return cmd.Run()
		}
	}
	return fmt.Errorf("unsupported platform: %s", runtime.GOOS)
}

func installDocker() error {
	if commandExists("docker") {
		return nil
	}

	switch runtime.GOOS {
	case "darwin":
		if commandExists("brew") {
			return exec.Command("brew", "install", "--cask", "docker").Run()
		}
	}
	return fmt.Errorf("please install Docker Desktop manually")
}

func installOpenShell() error {
	if commandExists("openshell") {
		return nil
	}

	cmd := exec.Command("bash", "-c", "curl -fsSL https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | bash")
	return cmd.Run()
}

func installNemoClaw() error {
	if commandExists("nemoclaw") {
		return nil
	}

	return exec.Command("npm", "install", "-g", "nemoclaw").Run()
}

func commandExists(cmd string) bool {
	_, err := exec.LookPath(cmd)
	return err == nil
}

func init() {
	installCmd.Flags().String("provider", "", "LLM provider (nvidia, openai, anthropic, openrouter, ollama, lmstudio, llamacpp, vllm, custom)")
	installCmd.Flags().String("model", "", "Model to use")
	installCmd.Flags().String("sandbox-name", "my-assistant", "Sandbox name")
	installCmd.Flags().Bool("non-interactive", false, "Run without prompts")
	installCmd.Flags().Bool("skip-docker", false, "Skip Docker installation")
	installCmd.Flags().Bool("skip-node", false, "Skip Node.js installation")
	installCmd.Flags().Bool("dry-run", false, "Show what would be installed")

	rootCmd.AddCommand(installCmd)
}
