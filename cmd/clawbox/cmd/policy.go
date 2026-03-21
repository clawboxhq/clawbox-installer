package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"text/tabwriter"

	"github.com/clawboxhq/clawbox-installer/internal/policy"
	"github.com/spf13/cobra"
)

var policyCmd = &cobra.Command{
	Use:   "policy",
	Short: "Manage network policies",
	Long: `Manage sandbox network policies.

Network policies control which endpoints the sandbox can reach.
By default, all requests to unlisted endpoints are blocked.

Available presets:
  discord, docker, github, huggingface, jira, npm, outlook, pypi, slack, telegram`,
}

var policyPresetsCmd = &cobra.Command{
	Use:   "presets",
	Short: "List available policy presets",
	Run: func(cmd *cobra.Command, args []string) {
		jsonOutput, _ := cmd.Flags().GetBool("json")
		if jsonOutput {
			presets := make([]policy.PolicyPreset, 0)
			for _, name := range policy.GetPresetNames() {
				if p, ok := policy.GetPreset(name); ok {
					presets = append(presets, p)
				}
			}
			output, _ := json.MarshalIndent(presets, "", "  ")
			fmt.Println(string(output))
			return
		}

		fmt.Println("Available Policy Presets:")
		fmt.Println()

		w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
		fmt.Fprintln(w, "NAME\tDESCRIPTION\tENDPOINTS")
		for _, name := range policy.GetPresetNames() {
			if p, ok := policy.GetPreset(name); ok {
				endpoints := make([]string, len(p.Endpoints))
				for i, ep := range p.Endpoints {
					endpoints[i] = fmt.Sprintf("%s:%d", ep.Host, ep.Port)
				}
				fmt.Fprintf(w, "%s\t%s\t%s\n", p.Name, p.Description, strings.Join(endpoints, ", "))
			}
		}
		w.Flush()
	},
}

var policyListCmd = &cobra.Command{
	Use:   "list <sandbox>",
	Short: "List applied policies for a sandbox",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		sandboxName := args[0]
		jsonOutput, _ := cmd.Flags().GetBool("json")

		policies, err := policy.ListAppliedPolicies(sandboxName)
		if err != nil {
			return err
		}

		if jsonOutput {
			output, _ := json.MarshalIndent(policies, "", "  ")
			fmt.Println(string(output))
			return nil
		}

		if len(policies) == 0 {
			fmt.Printf("No custom policies applied to sandbox '%s'\n", sandboxName)
			return nil
		}

		fmt.Printf("Applied policies for sandbox '%s':\n", sandboxName)
		for _, p := range policies {
			fmt.Printf("  - %s\n", p)
		}

		return nil
	},
}

var policyAddCmd = &cobra.Command{
	Use:   "add <sandbox> <preset>",
	Short: "Add a policy preset to a sandbox",
	Args:  cobra.ExactArgs(2),
	RunE: func(cmd *cobra.Command, args []string) error {
		sandboxName := args[0]
		presetName := args[1]

		// Verify preset exists
		if _, ok := policy.GetPreset(presetName); !ok {
			return fmt.Errorf("preset '%s' not found. Run 'clawbox policy presets' to see available presets", presetName)
		}

		fmt.Printf("Applying policy preset '%s' to sandbox '%s'...\n", presetName, sandboxName)

		if err := policy.ApplyPreset(sandboxName, presetName); err != nil {
			return fmt.Errorf("failed to apply policy: %w", err)
		}

		fmt.Printf("Policy '%s' applied successfully\n", presetName)
		return nil
	},
}

var policyShowCmd = &cobra.Command{
	Use:   "show <sandbox>",
	Short: "Show full policy for a sandbox",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		sandboxName := args[0]

		policyYAML, err := policy.GetPolicy(sandboxName)
		if err != nil {
			return err
		}

		fmt.Println(policyYAML)
		return nil
	},
}

var policyEditCmd = &cobra.Command{
	Use:   "edit <sandbox>",
	Short: "Edit policy for a sandbox (pull/edit/push)",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		sandboxName := args[0]

		// Get current policy
		policyYAML, err := policy.GetPolicy(sandboxName)
		if err != nil {
			return err
		}

		// Write to temp file
		tmpFile := fmt.Sprintf("/tmp/clawbox-policy-%s.yaml", sandboxName)
		if err := os.WriteFile(tmpFile, []byte(policyYAML), 0644); err != nil {
			return fmt.Errorf("failed to write policy file: %w", err)
		}
		defer os.Remove(tmpFile)

		// Open editor
		editor := os.Getenv("EDITOR")
		if editor == "" {
			editor = "vim"
		}

		editCmd := executeCommand(editor, tmpFile)
		editCmd.Stdin = os.Stdin
		editCmd.Stdout = os.Stdout
		editCmd.Stderr = os.Stderr

		if err := editCmd.Run(); err != nil {
			return fmt.Errorf("editor failed: %w", err)
		}

		// Apply edited policy
		fmt.Printf("Applying edited policy to sandbox '%s'...\n", sandboxName)
		applyCmd := executeCommand("openshell", "policy", "set", "--policy", tmpFile, "--wait", sandboxName)
		output, err := applyCmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("failed to apply policy: %w\n%s", err, string(output))
		}

		fmt.Printf("Policy updated for sandbox '%s'\n", sandboxName)
		return nil
	},
}

var policyCustomCmd = &cobra.Command{
	Use:   "custom <sandbox> --host <host> --port <port>",
	Short: "Add a custom policy endpoint",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		sandboxName := args[0]
		host, _ := cmd.Flags().GetString("host")
		port, _ := cmd.Flags().GetInt("port")
		name, _ := cmd.Flags().GetString("name")

		if host == "" {
			return fmt.Errorf("--host is required")
		}
		if port == 0 {
			port = 443
		}
		if name == "" {
			name = strings.ReplaceAll(host, ".", "_")
		}

		// Generate custom policy
		endpoints := []policy.PolicyEndpoint{
			{Host: host, Port: port},
		}
		yamlContent := policy.GenerateCustomPolicyYAML(name, endpoints)

		// Write to temp file
		tmpFile := fmt.Sprintf("/tmp/clawbox-policy-custom-%s.yaml", sandboxName)
		if err := os.WriteFile(tmpFile, []byte(yamlContent), 0644); err != nil {
			return fmt.Errorf("failed to write policy file: %w", err)
		}
		defer os.Remove(tmpFile)

		fmt.Printf("Adding custom policy for %s:%d to sandbox '%s'...\n", host, port, sandboxName)

		// Apply via openshell
		applyCmd := executeCommand("openshell", "policy", "set", "--policy", tmpFile, "--wait", sandboxName)
		output, err := applyCmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("failed to apply policy: %w\n%s", err, string(output))
		}

		fmt.Printf("Custom policy added successfully\n")
		return nil
	},
}

func executeCommand(name string, args ...string) *exec.Cmd {
	return exec.Command(name, args...)
}

func init() {
	policyCustomCmd.Flags().String("host", "", "Endpoint host (required)")
	policyCustomCmd.Flags().Int("port", 443, "Endpoint port")
	policyCustomCmd.Flags().String("name", "", "Policy name (default: derived from host)")

	policyCmd.AddCommand(policyPresetsCmd)
	policyCmd.AddCommand(policyListCmd)
	policyCmd.AddCommand(policyAddCmd)
	policyCmd.AddCommand(policyShowCmd)
	policyCmd.AddCommand(policyEditCmd)
	policyCmd.AddCommand(policyCustomCmd)

	rootCmd.AddCommand(policyCmd)
}
