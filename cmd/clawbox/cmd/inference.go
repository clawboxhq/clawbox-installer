package cmd

import (
	"encoding/json"
	"fmt"
	"os/exec"

	"github.com/clawboxhq/clawbox-installer/internal/provider"
	"github.com/spf13/cobra"
)

var inferenceCmd = &cobra.Command{
	Use:   "inference",
	Short: "Manage inference routing",
	Long: `Manage inference routing for sandboxes.

Switch between providers and models at runtime without restarting sandboxes.
Requires OpenShell gateway to be running.`,
}

var inferenceSetCmd = &cobra.Command{
	Use:   "set <sandbox> --provider <provider> --model <model>",
	Short: "Set inference provider and model",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		sandboxName := args[0]
		provName, _ := cmd.Flags().GetString("provider")
		model, _ := cmd.Flags().GetString("model")

		config, err := loadConfig()
		if err != nil {
			return err
		}

		// Validate provider
		if provName == "" {
			provName = config.DefaultProvider
		}
		if provName == "" {
			return fmt.Errorf("no provider specified and no default provider set")
		}

		prov, ok := config.Providers[provName]
		if !ok {
			return fmt.Errorf("provider '%s' not found in config", provName)
		}

		// Use provider's default model if not specified
		if model == "" {
			model = prov.DefaultModel
		}

		// Sync provider to OpenShell
		fmt.Printf("Syncing provider '%s' to OpenShell...\n", provName)
		if err := provider.SyncToOpenShell(&prov); err != nil {
			return fmt.Errorf("failed to sync provider: %w", err)
		}

		// Set inference
		fmt.Printf("Setting inference for sandbox '%s' to %s/%s...\n", sandboxName, provName, model)
		if err := provider.SetInference(provName, model); err != nil {
			return fmt.Errorf("failed to set inference: %w", err)
		}

		fmt.Printf("Inference set to provider '%s' with model '%s'\n", provName, model)
		return nil
	},
}

var inferenceStatusCmd = &cobra.Command{
	Use:   "status <sandbox>",
	Short: "Show inference status",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		sandboxName := args[0]
		jsonOutput, _ := cmd.Flags().GetBool("json")

		// Get status from openshell
		execCmd := exec.Command("openshell", "inference", "status", sandboxName)
		output, err := execCmd.Output()
		if err != nil {
			return fmt.Errorf("failed to get inference status: %w", err)
		}

		if jsonOutput {
			fmt.Println(string(output))
			return nil
		}

		fmt.Printf("Inference status for sandbox '%s':\n", sandboxName)
		fmt.Println(string(output))
		return nil
	},
}

var inferenceListModelsCmd = &cobra.Command{
	Use:   "list-models <provider>",
	Short: "List available models for a provider",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		provName := args[0]
		jsonOutput, _ := cmd.Flags().GetBool("json")

		config, err := loadConfig()
		if err != nil {
			return err
		}

		prov, ok := config.Providers[provName]
		if !ok {
			return fmt.Errorf("provider '%s' not found", provName)
		}

		fmt.Printf("Fetching models from provider '%s'...\n", provName)

		models, err := provider.GetModels(&prov)
		if err != nil {
			return fmt.Errorf("failed to list models: %w", err)
		}

		if jsonOutput {
			output, _ := json.MarshalIndent(models, "", "  ")
			fmt.Println(string(output))
			return nil
		}

		if len(models) == 0 {
			fmt.Printf("No models found for provider '%s'\n", provName)
			return nil
		}

		fmt.Printf("Available models for '%s' (%d):\n", provName, len(models))
		for _, m := range models {
			fmt.Printf("  - %s\n", m)
		}

		return nil
	},
}

var inferenceModelsCmd = &cobra.Command{
	Use:   "models",
	Short: "List common models for each provider type",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Common Models by Provider:")
		fmt.Println()

		modelMap := map[string][]string{
			"nvidia": {
				"nvidia/nemotron-3-super-120b-a12b",
				"nvidia/llama-3.1-nemotron-ultra-253b-v1",
				"nvidia/llama-3.3-nemotron-super-49b-v1.5",
				"meta/llama-3.1-405b-instruct",
			},
			"openai": {
				"gpt-4o",
				"gpt-4o-mini",
				"gpt-4-turbo",
				"gpt-3.5-turbo",
			},
			"anthropic": {
				"claude-sonnet-4-20250514",
				"claude-3-opus-20240229",
				"claude-3-haiku-20240307",
			},
			"openrouter": {
				"anthropic/claude-sonnet-4",
				"openai/gpt-4o",
				"google/gemini-pro-1.5",
				"meta-llama/llama-3.1-405b-instruct",
			},
			"ollama": {
				"llama3.2",
				"llama3.1",
				"mistral",
				"codellama",
				"phi3",
			},
		}

		for provType, models := range modelMap {
			fmt.Printf("  %s:\n", provType)
			for _, m := range models {
				fmt.Printf("    - %s\n", m)
			}
			fmt.Println()
		}

		fmt.Println("Note: For local providers (ollama, lmstudio), models depend on what's installed.")
		fmt.Println("Use 'clawbox inference list-models <provider>' to see available models.")
	},
}

func init() {
	inferenceSetCmd.Flags().String("provider", "", "Provider name (default: default provider)")
	inferenceSetCmd.Flags().String("model", "", "Model name (default: provider default)")

	inferenceCmd.AddCommand(inferenceSetCmd)
	inferenceCmd.AddCommand(inferenceStatusCmd)
	inferenceCmd.AddCommand(inferenceListModelsCmd)
	inferenceCmd.AddCommand(inferenceModelsCmd)

	rootCmd.AddCommand(inferenceCmd)
}

// getModelsFromProvider fetches models from a provider's API.
func getModelsFromProvider(prov provider.Provider) ([]string, error) {
	// This would need to be implemented based on provider type
	// For now, return common models
	switch prov.Type {
	case provider.TypeNVIDIA:
		return []string{
			"nvidia/nemotron-3-super-120b-a12b",
			"nvidia/llama-3.1-nemotron-ultra-253b-v1",
		}, nil
	case provider.TypeOpenAI:
		return []string{
			"gpt-4o",
			"gpt-4o-mini",
			"gpt-4-turbo",
		}, nil
	case provider.TypeAnthropic:
		return []string{
			"claude-sonnet-4-20250514",
			"claude-3-opus-20240229",
		}, nil
	default:
		return nil, fmt.Errorf("model listing not supported for provider type: %s", prov.Type)
	}
}
