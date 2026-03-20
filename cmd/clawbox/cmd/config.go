package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"

	"github.com/clawboxhq/clawbox-installer/internal/provider"
	"github.com/spf13/cobra"
)

var configCmd = &cobra.Command{
	Use:   "config",
	Short: "Manage configuration",
	Long: `Manage ClawBox configuration.

The configuration file is stored at ~/.clawbox/config.json by default.
You can customize the location with the --config flag.`,
}

var configShowCmd = &cobra.Command{
	Use:   "show",
	Short: "Show current configuration",
	RunE: func(cmd *cobra.Command, args []string) error {
		config, err := loadConfig()
		if err != nil {
			return err
		}

		output, err := json.MarshalIndent(config, "", "  ")
		if err != nil {
			return err
		}

		fmt.Println(string(output))
		return nil
	},
}

var configSetCmd = &cobra.Command{
	Use:   "set <key> <value>",
	Short: "Set a configuration value",
	Args:  cobra.ExactArgs(2),
	RunE: func(cmd *cobra.Command, args []string) error {
		key := args[0]
		value := args[1]

		config, err := loadConfig()
		if err != nil {
			return err
		}

		switch key {
		case "defaultProvider":
			config.DefaultProvider = value
		case "containerRuntime":
			config.ContainerRuntime = value
		case "openClawVersion":
			config.OpenClawVersion = value
		case "openShellVersion":
			config.OpenShellVersion = value
		default:
			return fmt.Errorf("unknown config key: %s", key)
		}

		if err := saveConfig(config); err != nil {
			return err
		}

		fmt.Printf("Set %s = %s\n", key, value)
		return nil
	},
}

var configGetCmd = &cobra.Command{
	Use:   "get <key>",
	Short: "Get a configuration value",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		key := args[0]

		config, err := loadConfig()
		if err != nil {
			return err
		}

		var value string
		switch key {
		case "defaultProvider":
			value = config.DefaultProvider
		case "containerRuntime":
			value = config.ContainerRuntime
		case "openClawVersion":
			value = config.OpenClawVersion
		case "openShellVersion":
			value = config.OpenShellVersion
		default:
			return fmt.Errorf("unknown config key: %s", key)
		}

		fmt.Println(value)
		return nil
	},
}

var configPathCmd = &cobra.Command{
	Use:   "path",
	Short: "Show configuration file path",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(cfgFile)
	},
}

var configEditCmd = &cobra.Command{
	Use:   "edit",
	Short: "Open configuration in editor",
	RunE: func(cmd *cobra.Command, args []string) error {
		editor := os.Getenv("EDITOR")
		if editor == "" {
			editor = "vim"
		}

		// Ensure config file exists
		config, err := loadConfig()
		if err != nil {
			return err
		}
		if err := saveConfig(config); err != nil {
			return err
		}

		// Open editor
		editorArgs := []string{cfgFile}
		return runCommand(editor, editorArgs...)
	},
}

var configResetCmd = &cobra.Command{
	Use:   "reset",
	Short: "Reset configuration to defaults",
	RunE: func(cmd *cobra.Command, args []string) error {
		yes, _ := cmd.Flags().GetBool("yes")

		if !yes {
			fmt.Print("This will reset all configuration. Continue? [y/N]: ")
			var response string
			fmt.Scanln(&response)
			if response != "y" && response != "Y" {
				fmt.Println("Cancelled")
				return nil
			}
		}

		config := &Config{
			Providers: make(map[string]provider.Provider),
		}

		if err := saveConfig(config); err != nil {
			return err
		}

		fmt.Println("Configuration reset to defaults")
		return nil
	},
}

func runCommand(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func init() {
	configResetCmd.Flags().Bool("yes", false, "Skip confirmation")

	configCmd.AddCommand(configShowCmd)
	configCmd.AddCommand(configSetCmd)
	configCmd.AddCommand(configGetCmd)
	configCmd.AddCommand(configPathCmd)
	configCmd.AddCommand(configEditCmd)
	configCmd.AddCommand(configResetCmd)

	rootCmd.AddCommand(configCmd)
}
