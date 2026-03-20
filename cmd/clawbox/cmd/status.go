package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"text/tabwriter"

	"github.com/spf13/cobra"
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show system status",
	Long: `Show current ClawBox system status including:
  - Configuration summary
  - Provider status
  - Sandbox status
  - Component versions`,
	RunE: func(cmd *cobra.Command, args []string) error {
		jsonOutput, _ := cmd.Flags().GetBool("json")
		verbose, _ := cmd.Flags().GetBool("verbose")

		config, err := loadConfig()
		if err != nil {
			return err
		}

		status := struct {
			DefaultProvider  string `json:"defaultProvider"`
			Providers        int    `json:"providers"`
			Sandboxes        int    `json:"sandboxes"`
			RunningSandboxes int    `json:"runningSandboxes"`
			OpenClawVersion  string `json:"openClawVersion"`
			ContainerRuntime string `json:"containerRuntime"`
		}{
			DefaultProvider:  config.DefaultProvider,
			Providers:        len(config.Providers),
			Sandboxes:        len(config.Sandboxes),
			OpenClawVersion:  config.OpenClawVersion,
			ContainerRuntime: config.ContainerRuntime,
		}

		// Count running sandboxes
		for _, s := range config.Sandboxes {
			if isSandboxRunning(s.Name) {
				status.RunningSandboxes++
			}
		}

		if jsonOutput {
			output, _ := json.MarshalIndent(status, "", "  ")
			fmt.Println(string(output))
			return nil
		}

		fmt.Println("🦞 ClawBox Status")
		fmt.Println("================")
		fmt.Println()

		w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)

		fmt.Fprintln(w, "Component\tStatus")
		fmt.Fprintln(w, "--------\t------")

		// Default provider
		if config.DefaultProvider != "" {
			fmt.Fprintf(w, "Default Provider\t%s\n", config.DefaultProvider)
		} else {
			fmt.Fprintln(w, "Default Provider\t(not set)")
		}

		// Providers
		fmt.Fprintf(w, "Providers\t%d configured\n", status.Providers)

		// Sandboxes
		fmt.Fprintf(w, "Sandboxes\t%d total (%d running)\n", status.Sandboxes, status.RunningSandboxes)

		// Container runtime
		if status.ContainerRuntime != "" {
			fmt.Fprintf(w, "Container Runtime\t%s\n", status.ContainerRuntime)
		} else {
			fmt.Fprintln(w, "Container Runtime\tdocker")
		}

		w.Flush()

		// Show sandboxes if verbose
		if verbose && len(config.Sandboxes) > 0 {
			fmt.Println("\nSandboxes:")
			for _, s := range config.Sandboxes {
				running := "stopped"
				if isSandboxRunning(s.Name) {
					running = "running"
				}
				fmt.Printf("  %s: %s (%s, port %d) - %s\n",
					s.Name, s.Provider, s.Model, s.Port, running)
			}
		}

		return nil
	},
}

func init() {
	statusCmd.Flags().Bool("verbose", false, "Show detailed information")
	rootCmd.AddCommand(statusCmd)
}
