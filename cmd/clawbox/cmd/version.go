package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show version information",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("clawbox version %s\n", version)
		fmt.Printf("  Git commit: %s\n", gitCommit)
		fmt.Printf("  Build date: %s\n", buildDate)
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
