package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
)

var uninstallCmd = &cobra.Command{
	Use:   "uninstall",
	Short: "Uninstall ClawBox",
	Long: `Remove ClawBox and all installed components.

This will remove:
  - All OpenShell sandboxes
  - NemoClaw npm package
  - OpenShell binary (optional)
  - Configuration files (optional)`,
	RunE: func(cmd *cobra.Command, args []string) error {
		yes, _ := cmd.Flags().GetBool("yes")
		keepOpenShell, _ := cmd.Flags().GetBool("keep-openshell")
		deleteModels, _ := cmd.Flags().GetBool("delete-models")
		deleteConfig, _ := cmd.Flags().GetBool("delete-config")

		fmt.Println("🦞 ClawBox Uninstaller")
		fmt.Println("====================")
		fmt.Println()

		fmt.Println("This will remove:")
		fmt.Println("  • All OpenShell sandboxes")
		fmt.Println("  • NemoClaw npm package")
		if !keepOpenShell {
			fmt.Println("  • OpenShell binary")
		}
		if deleteModels {
			fmt.Println("  • Ollama models")
		}
		if deleteConfig {
			fmt.Println("  • Configuration files")
		}
		fmt.Println()

		if !yes {
			fmt.Print("Proceed with uninstall? [y/N]: ")
			reader := bufio.NewReader(os.Stdin)
			response, _ := reader.ReadString('\n')
			response = strings.TrimSpace(strings.ToLower(response))
			if response != "y" && response != "yes" {
				fmt.Println("Uninstall cancelled")
				return nil
			}
		}

		// Remove sandboxes
		fmt.Println("\nRemoving sandboxes...")
		if commandExists("openshell") {
			sandboxes := getSandboxes()
			for _, sb := range sandboxes {
				fmt.Printf("  Stopping %s...\n", sb)
				exec.Command("openshell", "sandbox", "stop", sb).Run()
				fmt.Printf("  Removing %s...\n", sb)
				exec.Command("openshell", "sandbox", "delete", sb).Run()
			}
		}

		// Remove providers
		fmt.Println("\nRemoving providers...")
		if commandExists("openshell") {
			providers := getProviders()
			for _, p := range providers {
				fmt.Printf("  Removing %s...\n", p)
				exec.Command("openshell", "provider", "delete", p).Run()
			}
		}

		// Remove NemoClaw
		fmt.Println("\nRemoving NemoClaw...")
		if commandExists("npm") {
			exec.Command("npm", "uninstall", "-g", "nemoclaw").Run()
		}

		// Remove OpenShell
		if !keepOpenShell {
			fmt.Println("\nRemoving OpenShell...")
			if commandExists("openshell") {
				exec.Command("openshell", "gateway", "stop").Run()
				openshellPath, err := exec.LookPath("openshell")
				if err == nil {
					os.Remove(openshellPath)
				}
			}
		}

		// Remove config
		if deleteConfig {
			fmt.Println("\nRemoving configuration...")
			os.RemoveAll(getConfigDir())
		}

		fmt.Println("\n✅ Uninstall complete")
		if !deleteConfig {
			fmt.Printf("\nConfiguration preserved at: %s\n", getConfigDir())
			fmt.Println("To remove: rm -rf " + getConfigDir())
		}

		return nil
	},
}

func getSandboxes() []string {
	cmd := exec.Command("openshell", "sandbox", "list")
	output, err := cmd.Output()
	if err != nil {
		return nil
	}

	var sandboxes []string
	lines := strings.Split(string(output), "\n")
	for i, line := range lines {
		if i == 0 {
			continue // skip header
		}
		fields := strings.Fields(line)
		if len(fields) > 0 {
			sandboxes = append(sandboxes, fields[0])
		}
	}
	return sandboxes
}

func getProviders() []string {
	cmd := exec.Command("openshell", "provider", "list")
	output, err := cmd.Output()
	if err != nil {
		return nil
	}

	var providers []string
	lines := strings.Split(string(output), "\n")
	for i, line := range lines {
		if i == 0 {
			continue // skip header
		}
		fields := strings.Fields(line)
		if len(fields) > 0 {
			providers = append(providers, fields[0])
		}
	}
	return providers
}

func init() {
	uninstallCmd.Flags().Bool("yes", false, "Skip confirmation")
	uninstallCmd.Flags().Bool("keep-openshell", false, "Keep OpenShell installed")
	uninstallCmd.Flags().Bool("delete-models", false, "Remove Ollama models")
	uninstallCmd.Flags().Bool("delete-config", false, "Remove configuration files")

	rootCmd.AddCommand(uninstallCmd)
}
