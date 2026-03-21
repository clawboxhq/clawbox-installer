package cmd

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"text/tabwriter"

	"github.com/clawboxhq/clawbox-installer/internal/provider"
	"github.com/spf13/cobra"
)

var sandboxCmd = &cobra.Command{
	Use:   "sandbox",
	Short: "Manage OpenShell sandboxes",
	Long: `Manage OpenShell sandboxes for ClawBox.

Sandboxes provide isolated environments for running OpenClaw
with persistent volume mounting and network isolation.`,
}

var sandboxListCmd = &cobra.Command{
	Use:   "list",
	Short: "List all sandboxes",
	RunE: func(cmd *cobra.Command, args []string) error {
		config, err := loadConfig()
		if err != nil {
			return err
		}

		jsonOutput, _ := cmd.Flags().GetBool("json")
		if jsonOutput {
			output, err := json.MarshalIndent(config.Sandboxes, "", "  ")
			if err != nil {
				return err
			}
			fmt.Println(string(output))
			return nil
		}

		if len(config.Sandboxes) == 0 {
			fmt.Println("No sandboxes configured")
			return nil
		}

		w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
		fmt.Fprintln(w, "NAME\tPROVIDER\tMODEL\tPORT\tSTATUS")
		for _, s := range config.Sandboxes {
			status := "stopped"
			if isSandboxRunning(s.Name) {
				status = "running"
			}
			fmt.Fprintf(w, "%s\t%s\t%s\t%d\t%s\n",
				s.Name, s.Provider, s.Model, s.Port, status)
		}
		w.Flush()
		return nil
	},
}

var sandboxCreateCmd = &cobra.Command{
	Use:   "create <name> [flags]",
	Short: "Create a new sandbox",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]
		provName, _ := cmd.Flags().GetString("provider")
		model, _ := cmd.Flags().GetString("model")
		port, _ := cmd.Flags().GetInt("port")

		config, err := loadConfig()
		if err != nil {
			return err
		}

		if provName == "" {
			provName = config.DefaultProvider
		}
		if provName == "" {
			return fmt.Errorf("no provider specified and no default provider set")
		}

		prov, ok := config.Providers[provName]
		if !ok {
			return fmt.Errorf("provider '%s' not found", provName)
		}

		if model == "" {
			model = prov.DefaultModel
		}

		if port == 0 {
			port = 18789 + len(config.Sandboxes)
		}

		for _, s := range config.Sandboxes {
			if s.Name == name {
				return fmt.Errorf("sandbox '%s' already exists", name)
			}
			if s.Port == port {
				return fmt.Errorf("port %d is already in use by sandbox '%s'", port, s.Name)
			}
		}

		newSandbox := SandboxConfig{
			Name:     name,
			Provider: provName,
			Model:    model,
			Port:     port,
		}

		config.Sandboxes = append(config.Sandboxes, newSandbox)
		if err := saveConfig(config); err != nil {
			return err
		}

		fmt.Printf("Sandbox '%s' created with provider '%s' and model '%s'\n", name, provName, model)
		fmt.Printf("Port: %d\n", port)
		fmt.Printf("\nTo start the sandbox:\n  clawbox sandbox start %s\n", name)
		return nil
	},
}

var sandboxStartCmd = &cobra.Command{
	Use:   "start <name>",
	Short: "Start a sandbox",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]

		config, err := loadConfig()
		if err != nil {
			return err
		}

		var sandbox *SandboxConfig
		for i := range config.Sandboxes {
			if config.Sandboxes[i].Name == name {
				sandbox = &config.Sandboxes[i]
				break
			}
		}
		if sandbox == nil {
			return fmt.Errorf("sandbox '%s' not found", name)
		}

		if isSandboxRunning(name) {
			fmt.Printf("Sandbox '%s' is already running\n", name)
			return nil
		}

		// Sync provider to OpenShell before starting sandbox
		prov, ok := config.Providers[sandbox.Provider]
		if !ok {
			return fmt.Errorf("provider '%s' not found in config", sandbox.Provider)
		}

		fmt.Printf("Syncing provider '%s' to OpenShell...\n", sandbox.Provider)
		if err := provider.SyncToOpenShell(&prov); err != nil {
			return fmt.Errorf("failed to sync provider: %w", err)
		}

		// Set inference route
		fmt.Printf("Setting inference to model '%s'...\n", sandbox.Model)
		if err := provider.SetInference(sandbox.Provider, sandbox.Model); err != nil {
			return fmt.Errorf("failed to set inference: %w", err)
		}

		fmt.Printf("Starting sandbox '%s'...\n", name)

		openshellCmd := exec.Command("openshell", "sandbox", "start", name)
		openshellCmd.Stdout = os.Stdout
		openshellCmd.Stderr = os.Stderr

		if err := openshellCmd.Run(); err != nil {
			return fmt.Errorf("failed to start sandbox: %w", err)
		}

		fmt.Printf("Sandbox '%s' started\n", name)
		fmt.Printf("Dashboard: http://127.0.0.1:%d\n", sandbox.Port)
		return nil
	},
}

var sandboxStopCmd = &cobra.Command{
	Use:   "stop <name>",
	Short: "Stop a sandbox",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]

		if !isSandboxRunning(name) {
			fmt.Printf("Sandbox '%s' is not running\n", name)
			return nil
		}

		fmt.Printf("Stopping sandbox '%s'...\n", name)

		openshellCmd := exec.Command("openshell", "sandbox", "stop", name)
		openshellCmd.Stdout = os.Stdout
		openshellCmd.Stderr = os.Stderr

		if err := openshellCmd.Run(); err != nil {
			return fmt.Errorf("failed to stop sandbox: %w", err)
		}

		fmt.Printf("Sandbox '%s' stopped\n", name)
		return nil
	},
}

var sandboxConnectCmd = &cobra.Command{
	Use:   "connect <name>",
	Short: "Connect to a sandbox",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]

		nemoclawCmd := exec.Command("nemoclaw", name, "connect")
		nemoclawCmd.Stdin = os.Stdin
		nemoclawCmd.Stdout = os.Stdout
		nemoclawCmd.Stderr = os.Stderr

		return nemoclawCmd.Run()
	},
}

var sandboxRemoveCmd = &cobra.Command{
	Use:   "remove <name>",
	Short: "Remove a sandbox",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]

		config, err := loadConfig()
		if err != nil {
			return err
		}

		for i, s := range config.Sandboxes {
			if s.Name == name {
				if isSandboxRunning(name) {
					fmt.Printf("Stopping sandbox '%s'...\n", name)
					exec.Command("openshell", "sandbox", "stop", name).Run()
				}

				exec.Command("openshell", "sandbox", "delete", name).Run()

				config.Sandboxes = append(config.Sandboxes[:i], config.Sandboxes[i+1:]...)
				if err := saveConfig(config); err != nil {
					return err
				}

				fmt.Printf("Sandbox '%s' removed\n", name)
				return nil
			}
		}

		return fmt.Errorf("sandbox '%s' not found", name)
	},
}

var sandboxLogsCmd = &cobra.Command{
	Use:   "logs <name>",
	Short: "View sandbox logs",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]
		follow, _ := cmd.Flags().GetBool("follow")

		args2 := []string{name, "logs"}
		if follow {
			args2 = append(args2, "--follow")
		}

		nemoclawCmd := exec.Command("nemoclaw", args2...)
		nemoclawCmd.Stdout = os.Stdout
		nemoclawCmd.Stderr = os.Stderr

		return nemoclawCmd.Run()
	},
}

func isSandboxRunning(name string) bool {
	cmd := exec.Command("openshell", "sandbox", "list")
	output, err := cmd.Output()
	if err != nil {
		return false
	}
	return bytes.Contains(output, []byte(name)) && bytes.Contains(output, []byte("running"))
}

func init() {
	sandboxCreateCmd.Flags().String("provider", "", "Provider name (default: default provider)")
	sandboxCreateCmd.Flags().String("model", "", "Model to use (default: provider default)")
	sandboxCreateCmd.Flags().Int("port", 0, "Port for dashboard (default: auto-assign)")

	sandboxLogsCmd.Flags().Bool("follow", false, "Follow log output")

	sandboxCmd.AddCommand(sandboxListCmd)
	sandboxCmd.AddCommand(sandboxCreateCmd)
	sandboxCmd.AddCommand(sandboxStartCmd)
	sandboxCmd.AddCommand(sandboxStopCmd)
	sandboxCmd.AddCommand(sandboxConnectCmd)
	sandboxCmd.AddCommand(sandboxRemoveCmd)
	sandboxCmd.AddCommand(sandboxLogsCmd)

	rootCmd.AddCommand(sandboxCmd)
}
