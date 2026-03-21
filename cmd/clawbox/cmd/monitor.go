package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var monitorCmd = &cobra.Command{
	Use:   "monitor",
	Short: "Open OpenShell TUI monitoring dashboard",
	Long: `Open the OpenShell TUI monitoring dashboard.

The TUI shows:
  - Gateway and sandbox status
  - Network activity
  - Blocked requests
  - Inference proxy activity

Navigation:
  Tab     Switch panels
  j/k     Navigate lists
  Enter   Select item
  :       Command mode
  q       Quit

Press 'q' to exit the TUI.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		// Check if openshell is available
		if _, err := exec.LookPath("openshell"); err != nil {
			return fmt.Errorf("openshell not found. Run 'clawbox install' first")
		}

		// Launch openshell term
		termCmd := exec.Command("openshell", "term")
		termCmd.Stdin = os.Stdin
		termCmd.Stdout = os.Stdout
		termCmd.Stderr = os.Stderr

		return termCmd.Run()
	},
}

func init() {
	rootCmd.AddCommand(monitorCmd)
}
