package cmd

import (
	"encoding/json"
	"fmt"
	"os/exec"

	"github.com/spf13/cobra"
)

var updateCmd = &cobra.Command{
	Use:   "update [component]",
	Short: "Update ClawBox components",
	Long: `Update ClawBox components.

Components:
  self       Update the clawbox CLI itself
  openshell  Update OpenShell
  nemoclaw   Update NemoClaw
  all        Update all components`,
	Args: cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		component := "all"
		if len(args) > 0 {
			component = args[0]
		}

		switch component {
		case "self":
			return updateSelf()
		case "openshell":
			return updateOpenShell()
		case "nemoclaw":
			return updateNemoClaw()
		case "all":
			if err := updateOpenShell(); err != nil {
				fmt.Printf("Warning: OpenShell update failed: %v\n", err)
			}
			if err := updateNemoClaw(); err != nil {
				fmt.Printf("Warning: NemoClaw update failed: %v\n", err)
			}
			fmt.Println("\n✅ All components updated")
		default:
			return fmt.Errorf("unknown component: %s (valid: self, openshell, nemoclaw, all)", component)
		}

		return nil
	},
}

func updateSelf() error {
	fmt.Println("Updating clawbox CLI...")

	// Check for new version on GitHub
	latestVersion, err := getLatestVersion()
	if err != nil {
		return fmt.Errorf("failed to check for updates: %w", err)
	}

	if latestVersion == version {
		fmt.Println("clawbox is already up to date")
		return nil
	}

	fmt.Printf("New version available: %s (current: %s)\n", latestVersion, version)
	fmt.Println("Please reinstall from: https://github.com/clawboxhq/clawbox-installer")

	return nil
}

func updateOpenShell() error {
	fmt.Println("Updating OpenShell...")

	if !commandExists("openshell") {
		return fmt.Errorf("OpenShell not installed")
	}

	// OpenShell self-update command if available
	cmd := exec.Command("openshell", "self-update")
	if err := cmd.Run(); err != nil {
		// Fallback to reinstall script
		cmd = exec.Command("bash", "-c", "curl -fsSL https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | bash")
		if err := cmd.Run(); err != nil {
			return err
		}
	}

	fmt.Println("✅ OpenShell updated")
	return nil
}

func updateNemoClaw() error {
	fmt.Println("Updating NemoClaw...")

	if !commandExists("npm") {
		return fmt.Errorf("npm not found")
	}

	cmd := exec.Command("npm", "update", "-g", "nemoclaw")
	if err := cmd.Run(); err != nil {
		return err
	}

	fmt.Println("✅ NemoClaw updated")
	return nil
}

func getLatestVersion() (string, error) {
	cmd := exec.Command("curl", "-sSL", "https://raw.githubusercontent.com/clawboxhq/clawbox-installer/main/VERSION")
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}

	var v struct {
		Version string `json:"version"`
	}
	if err := json.Unmarshal(output, &v); err != nil {
		return "", err
	}

	return v.Version, nil
}

func init() {
	rootCmd.AddCommand(updateCmd)
}
