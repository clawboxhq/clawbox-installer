// Package main is the entry point for ClawBox CLI
package main

import (
	"os"

	"github.com/clawboxhq/clawbox-installer/cmd/clawbox/cmd"
)

var (
	// Version is set at build time
	Version = "0.5.1"
	// GitCommit is set at build time
	GitCommit = "unknown"
	// BuildDate is set at build time
	BuildDate = "unknown"
)

func main() {
	// Execute the root command
	if err := cmd.Execute(Version, GitCommit, BuildDate); err != nil {
		os.Exit(1)
	}
}
