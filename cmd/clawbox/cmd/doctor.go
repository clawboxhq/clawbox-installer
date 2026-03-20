package cmd

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"

	"github.com/spf13/cobra"
)

var doctorCmd = &cobra.Command{
	Use:   "doctor",
	Short: "Run diagnostics and health checks",
	Long: `Run comprehensive diagnostics to verify ClawBox installation.

Checks include:
  - System architecture and platform
  - Required dependencies (Node.js, Docker, etc.)
  - OpenShell installation
  - NemoClaw installation
  - Provider connectivity
  - Sandbox health`,
	RunE: func(cmd *cobra.Command, args []string) error {
		jsonOutput, _ := cmd.Flags().GetBool("json")
		verbose, _ := cmd.Flags().GetBool("verbose")

		results := make(map[string]CheckResult)

		fmt.Println("🩺 ClawBox Doctor")
		fmt.Println("=================")
		fmt.Println()

		// System checks
		fmt.Println("📋 System Information")
		fmt.Println("---------------------")
		results["platform"] = checkPlatform(verbose)
		results["architecture"] = checkArchitecture(verbose)

		// Dependency checks
		fmt.Println("\n📦 Dependencies")
		fmt.Println("---------------")
		results["nodejs"] = checkNodeJS(verbose)
		results["npm"] = checkNPM(verbose)
		results["docker"] = checkDocker(verbose)
		results["openshell"] = checkOpenShell(verbose)
		results["nemoclaw"] = checkNemoClaw(verbose)

		// Configuration checks
		fmt.Println("\n⚙️  Configuration")
		fmt.Println("-----------------")
		results["config"] = checkConfig(verbose)

		// Provider checks
		fmt.Println("\n🔌 Providers")
		fmt.Println("------------")
		results["providers"] = checkProviders(verbose)

		// Sandbox checks
		fmt.Println("\n🖥️  Sandboxes")
		fmt.Println("-------------")
		results["sandboxes"] = checkSandboxes(verbose)

		// Network checks
		fmt.Println("\n🌐 Network")
		fmt.Println("----------")
		results["network"] = checkNetwork(verbose)

		if jsonOutput {
			output, _ := json.MarshalIndent(results, "", "  ")
			fmt.Println(string(output))
			return nil
		}

		// Summary
		fmt.Println("\n📊 Summary")
		fmt.Println("----------")
		passed := 0
		failed := 0
		warnings := 0
		for _, r := range results {
			switch r.Status {
			case StatusPass:
				passed++
			case StatusFail:
				failed++
			case StatusWarn:
				warnings++
			}
		}

		fmt.Printf("  ✅ Passed:   %d\n", passed)
		fmt.Printf("  ❌ Failed:   %d\n", failed)
		fmt.Printf("  ⚠️  Warnings: %d\n", warnings)

		if failed > 0 {
			fmt.Println("\n❌ Some checks failed. Please fix the issues above.")
			os.Exit(1)
		} else if warnings > 0 {
			fmt.Println("\n⚠️  Some warnings found. Review above for details.")
		} else {
			fmt.Println("\n✅ All checks passed!")
		}

		return nil
	},
}

type CheckStatus string

const (
	StatusPass CheckStatus = "pass"
	StatusFail CheckStatus = "fail"
	StatusWarn CheckStatus = "warn"
	StatusSkip CheckStatus = "skip"
)

type CheckResult struct {
	Name    string      `json:"name"`
	Status  CheckStatus `json:"status"`
	Message string      `json:"message"`
	Detail  string      `json:"detail,omitempty"`
}

func checkPlatform(verbose bool) CheckResult {
	osName := runtime.GOOS
	result := CheckResult{
		Name:    "Platform",
		Status:  StatusPass,
		Message: fmt.Sprintf("%s", osName),
	}
	fmt.Printf("  Platform:      %s\n", osName)
	return result
}

func checkArchitecture(verbose bool) CheckResult {
	arch := runtime.GOARCH
	result := CheckResult{
		Name:    "Architecture",
		Status:  StatusPass,
		Message: arch,
	}
	fmt.Printf("  Architecture:  %s\n", arch)

	if runtime.GOOS == "darwin" && arch != "arm64" {
		result.Status = StatusFail
		result.Message = "Intel Macs not supported (Apple Silicon only)"
		fmt.Printf("  ❌ Intel Macs not supported\n")
	}

	return result
}

func checkNodeJS(verbose bool) CheckResult {
	result := CheckResult{Name: "Node.js"}

	if !commandExists("node") {
		result.Status = StatusFail
		result.Message = "Not installed"
		fmt.Printf("  Node.js:       ❌ Not installed\n")
		return result
	}

	version, err := exec.Command("node", "--version").Output()
	if err != nil {
		result.Status = StatusFail
		result.Message = "Failed to get version"
		fmt.Printf("  Node.js:       ❌ Failed to get version\n")
		return result
	}

	v := strings.TrimSpace(string(version))
	result.Status = StatusPass
	result.Message = v
	fmt.Printf("  Node.js:       ✅ %s\n", v)
	return result
}

func checkNPM(verbose bool) CheckResult {
	result := CheckResult{Name: "npm"}

	if !commandExists("npm") {
		result.Status = StatusFail
		result.Message = "Not installed"
		fmt.Printf("  npm:           ❌ Not installed\n")
		return result
	}

	version, err := exec.Command("npm", "--version").Output()
	if err != nil {
		result.Status = StatusFail
		result.Message = "Failed to get version"
		fmt.Printf("  npm:           ❌ Failed to get version\n")
		return result
	}

	v := strings.TrimSpace(string(version))
	result.Status = StatusPass
	result.Message = v
	fmt.Printf("  npm:           ✅ %s\n", v)
	return result
}

func checkDocker(verbose bool) CheckResult {
	result := CheckResult{Name: "Docker"}

	if !commandExists("docker") {
		result.Status = StatusFail
		result.Message = "Not installed"
		fmt.Printf("  Docker:        ❌ Not installed\n")
		return result
	}

	// Check if Docker daemon is running
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://localhost/v1.41/containers/json")
	if err != nil {
		result.Status = StatusFail
		result.Message = "Daemon not running"
		fmt.Printf("  Docker:        ❌ Installed but daemon not running\n")
		return result
	}
	resp.Body.Close()

	version, _ := exec.Command("docker", "--version").Output()
	v := strings.TrimSpace(string(version))
	result.Status = StatusPass
	result.Message = v
	fmt.Printf("  Docker:        ✅ Running\n")
	if verbose {
		fmt.Printf("                 %s\n", v)
	}
	return result
}

func checkOpenShell(verbose bool) CheckResult {
	result := CheckResult{Name: "OpenShell"}

	if !commandExists("openshell") {
		result.Status = StatusFail
		result.Message = "Not installed"
		fmt.Printf("  OpenShell:     ❌ Not installed\n")
		return result
	}

	version, err := exec.Command("openshell", "version").Output()
	if err != nil {
		version, _ = exec.Command("openshell", "--version").Output()
	}

	v := strings.TrimSpace(string(version))
	result.Status = StatusPass
	result.Message = v
	fmt.Printf("  OpenShell:     ✅ Installed\n")
	if verbose && v != "" {
		fmt.Printf("                 %s\n", v)
	}
	return result
}

func checkNemoClaw(verbose bool) CheckResult {
	result := CheckResult{Name: "NemoClaw"}

	if !commandExists("nemoclaw") {
		result.Status = StatusFail
		result.Message = "Not installed"
		fmt.Printf("  NemoClaw:      ❌ Not installed\n")
		return result
	}

	result.Status = StatusPass
	result.Message = "Installed"
	fmt.Printf("  NemoClaw:      ✅ Installed\n")
	return result
}

func checkConfig(verbose bool) CheckResult {
	result := CheckResult{Name: "Configuration"}

	config, err := loadConfig()
	if err != nil {
		result.Status = StatusWarn
		result.Message = "No configuration file"
		fmt.Printf("  Config:        ⚠️  Not found\n")
		fmt.Printf("                 Run 'clawbox install' first\n")
		return result
	}

	if config.DefaultProvider == "" {
		result.Status = StatusWarn
		result.Message = "No default provider set"
		fmt.Printf("  Config:        ⚠️  No default provider\n")
		return result
	}

	result.Status = StatusPass
	result.Message = fmt.Sprintf("Default provider: %s", config.DefaultProvider)
	fmt.Printf("  Config:        ✅ Found\n")
	fmt.Printf("                 Default: %s\n", config.DefaultProvider)
	if verbose {
		fmt.Printf("                 Location: %s\n", cfgFile)
	}
	return result
}

func checkProviders(verbose bool) CheckResult {
	result := CheckResult{Name: "Providers"}

	config, err := loadConfig()
	if err != nil || len(config.Providers) == 0 {
		result.Status = StatusWarn
		result.Message = "No providers configured"
		fmt.Printf("  Providers:     ⚠️  None configured\n")
		return result
	}

	for name, p := range config.Providers {
		// Test connection
		client := &http.Client{Timeout: 5 * time.Second}
		endpoint := p.Endpoint
		if endpoint == "" {
			endpoint = "http://localhost:11434" // default for Ollama
		}

		testURL := endpoint
		if strings.Contains(endpoint, "ollama") || strings.Contains(endpoint, ":11434") {
			testURL = endpoint + "/api/tags"
		} else {
			testURL = endpoint + "/models"
		}

		resp, err := client.Get(testURL)
		if err != nil {
			fmt.Printf("  %s:        ❌ Cannot connect\n", name)
			continue
		}
		resp.Body.Close()

		if resp.StatusCode == http.StatusOK {
			fmt.Printf("  %s:        ✅ Connected\n", name)
		} else if resp.StatusCode == http.StatusUnauthorized {
			fmt.Printf("  %s:        ⚠️  API key required\n", name)
		} else {
			fmt.Printf("  %s:        ⚠️  Status %d\n", name, resp.StatusCode)
		}
	}

	result.Status = StatusPass
	result.Message = fmt.Sprintf("%d provider(s) configured", len(config.Providers))
	return result
}

func checkSandboxes(verbose bool) CheckResult {
	result := CheckResult{Name: "Sandboxes"}

	if !commandExists("openshell") {
		result.Status = StatusSkip
		result.Message = "OpenShell not installed"
		fmt.Printf("  Sandboxes:     ⏭️  Skipped (OpenShell not installed)\n")
		return result
	}

	output, err := exec.Command("openshell", "sandbox", "list").Output()
	if err != nil {
		result.Status = StatusWarn
		result.Message = "Failed to list sandboxes"
		fmt.Printf("  Sandboxes:     ⚠️  Failed to list\n")
		return result
	}

	lines := strings.Split(string(output), "\n")
	running := 0
	stopped := 0
	for i, line := range lines {
		if i == 0 {
			continue
		}
		if strings.Contains(line, "running") {
			running++
		} else if strings.Fields(line) != nil && len(strings.Fields(line)) > 0 {
			stopped++
		}
	}

	total := running + stopped
	if total == 0 {
		fmt.Printf("  Sandboxes:     ⚠️  None created\n")
		result.Status = StatusWarn
		result.Message = "No sandboxes"
	} else {
		fmt.Printf("  Sandboxes:     ✅ %d total (%d running, %d stopped)\n", total, running, stopped)
		result.Status = StatusPass
		result.Message = fmt.Sprintf("%d sandboxes", total)
	}
	return result
}

func checkNetwork(verbose bool) CheckResult {
	result := CheckResult{Name: "Network"}

	client := &http.Client{Timeout: 10 * time.Second}

	// Test connectivity to common endpoints
	endpoints := []struct {
		name string
		url  string
	}{
		{"GitHub", "https://github.com"},
		{"NVIDIA API", "https://integrate.api.nvidia.com"},
		{"npm registry", "https://registry.npmjs.org"},
	}

	allOK := true
	for _, e := range endpoints {
		resp, err := client.Get(e.url)
		if err != nil {
			fmt.Printf("  %s:     ❌ Cannot reach\n", e.name)
			allOK = false
			continue
		}
		resp.Body.Close()
		fmt.Printf("  %s:     ✅ OK\n", e.name)
	}

	if allOK {
		result.Status = StatusPass
		result.Message = "All endpoints reachable"
	} else {
		result.Status = StatusWarn
		result.Message = "Some endpoints unreachable"
	}
	return result
}

func init() {
	doctorCmd.Flags().Bool("verbose", false, "Show detailed output")
	rootCmd.AddCommand(doctorCmd)
}
