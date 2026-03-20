package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"text/tabwriter"

	"github.com/clawboxhq/clawbox-installer/internal/provider"
	"github.com/spf13/cobra"
)

var providerCmd = &cobra.Command{
	Use:   "provider",
	Short: "Manage LLM providers",
	Long: `Manage LLM providers for ClawBox.

Supports multiple providers:
  - Cloud: NVIDIA, OpenAI, Anthropic, OpenRouter
  - Local: Ollama, LM Studio, llama.cpp, vLLM
  - Custom: Any OpenAI-compatible endpoint`,
}

var providerListCmd = &cobra.Command{
	Use:   "list",
	Short: "List all providers",
	RunE: func(cmd *cobra.Command, args []string) error {
		config, err := loadConfig()
		if err != nil {
			return err
		}

		jsonOutput, _ := cmd.Flags().GetBool("json")
		if jsonOutput {
			output, err := json.MarshalIndent(config.Providers, "", "  ")
			if err != nil {
				return err
			}
			fmt.Println(string(output))
			return nil
		}

		w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
		fmt.Fprintln(w, "NAME\tTYPE\tENDPOINT\tDEFAULT MODEL\tSTATUS")

		names := make([]string, 0, len(config.Providers))
		for n := range config.Providers {
			names = append(names, n)
		}
		sort.Strings(names)

		for _, name := range names {
			p := config.Providers[name]
			info, _ := provider.GetProviderInfo(p.Type)
			status := "not configured"
			if p.APIKey != "" || info.IsLocal {
				status = "configured"
			}
			fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n",
				name, p.Type, p.Endpoint, p.DefaultModel, status)
		}
		w.Flush()
		return nil
	},
}

var providerAddCmd = &cobra.Command{
	Use:   "add <name> --type <type> [flags]",
	Short: "Add or configure a provider",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]
		provType, _ := cmd.Flags().GetString("type")
		endpoint, _ := cmd.Flags().GetString("endpoint")
		apiKey, _ := cmd.Flags().GetString("api-key")
		model, _ := cmd.Flags().GetString("model")

		config, err := loadConfig()
		if err != nil {
			return err
		}

		pt := provider.ProviderType(provType)
		info, ok := provider.GetProviderInfo(pt)
		if !ok {
			return fmt.Errorf("unknown provider type: %s", provType)
		}

		if endpoint == "" {
			endpoint = info.Endpoint
		}
		if model == "" {
			model = info.DefaultModel
		}

		if err := provider.ValidateAPIKey(pt, apiKey); err != nil && !info.IsLocal {
			return err
		}

		if config.Providers == nil {
			config.Providers = make(map[string]provider.Provider)
		}

		config.Providers[name] = provider.Provider{
			Name:         name,
			Type:         pt,
			Endpoint:     endpoint,
			APIKey:       apiKey,
			DefaultModel: model,
		}

		if config.DefaultProvider == "" {
			config.DefaultProvider = name
		}

		if err := saveConfig(config); err != nil {
			return err
		}

		fmt.Printf("Provider '%s' added successfully\n", name)
		return nil
	},
}

var providerRemoveCmd = &cobra.Command{
	Use:   "remove <name>",
	Short: "Remove a provider",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]

		config, err := loadConfig()
		if err != nil {
			return err
		}

		if _, ok := config.Providers[name]; !ok {
			return fmt.Errorf("provider '%s' not found", name)
		}

		delete(config.Providers, name)

		if config.DefaultProvider == name {
			config.DefaultProvider = ""
			for n := range config.Providers {
				config.DefaultProvider = n
				break
			}
		}

		if err := saveConfig(config); err != nil {
			return err
		}

		fmt.Printf("Provider '%s' removed\n", name)
		return nil
	},
}

var providerDefaultCmd = &cobra.Command{
	Use:   "default <name>",
	Short: "Set the default provider",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]

		config, err := loadConfig()
		if err != nil {
			return err
		}

		if _, ok := config.Providers[name]; !ok {
			return fmt.Errorf("provider '%s' not found", name)
		}

		config.DefaultProvider = name
		if err := saveConfig(config); err != nil {
			return err
		}

		fmt.Printf("Default provider set to '%s'\n", name)
		return nil
	},
}

var providerTestCmd = &cobra.Command{
	Use:   "test <name>",
	Short: "Test provider connection",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]

		config, err := loadConfig()
		if err != nil {
			return err
		}

		p, ok := config.Providers[name]
		if !ok {
			return fmt.Errorf("provider '%s' not found", name)
		}

		fmt.Printf("Testing connection to %s...\n", name)
		if err := provider.TestConnection(&p); err != nil {
			fmt.Printf("Connection failed: %v\n", err)
			return err
		}
		fmt.Println("Connection successful!")

		models, err := provider.GetModels(&p)
		if err == nil && len(models) > 0 {
			fmt.Println("\nAvailable models:")
			for _, m := range models {
				fmt.Printf("  - %s\n", m)
			}
		}

		return nil
	},
}

var providerTypesCmd = &cobra.Command{
	Use:   "types",
	Short: "List available provider types",
	Run: func(cmd *cobra.Command, args []string) {
		jsonOutput, _ := cmd.Flags().GetBool("json")
		if jsonOutput {
			types := provider.GetProviderTypes()
			output, _ := json.MarshalIndent(types, "", "  ")
			fmt.Println(string(output))
			return
		}

		fmt.Println("Available provider types:")
		fmt.Println()
		fmt.Println("Cloud Providers:")
		for _, t := range []provider.ProviderType{provider.TypeNVIDIA, provider.TypeOpenAI, provider.TypeAnthropic, provider.TypeOpenRouter} {
			info, _ := provider.GetProviderInfo(t)
			fmt.Printf("  %-12s %s\n", t, info.Name)
			fmt.Printf("              Default: %s\n", info.DefaultModel)
			fmt.Printf("              Get key: %s\n\n", info.KeyURL)
		}
		fmt.Println("Local Providers:")
		for _, t := range []provider.ProviderType{provider.TypeOllama, provider.TypeLMStudio, provider.TypeLlamaCpp, provider.TypeVLLM} {
			info, _ := provider.GetProviderInfo(t)
			fmt.Printf("  %-12s %s\n", t, info.Name)
			fmt.Printf("              Default: %s\n\n", info.DefaultModel)
		}
		fmt.Println("Other:")
		fmt.Printf("  %-12s %s\n", provider.TypeCustom, "Custom OpenAI-compatible endpoint")
	},
}

func init() {
	providerAddCmd.Flags().String("type", "", "Provider type (required)")
	providerAddCmd.Flags().String("endpoint", "", "Custom endpoint URL")
	providerAddCmd.Flags().String("api-key", "", "API key")
	providerAddCmd.Flags().String("model", "", "Default model")
	providerAddCmd.MarkFlagRequired("type")

	providerCmd.AddCommand(providerListCmd)
	providerCmd.AddCommand(providerAddCmd)
	providerCmd.AddCommand(providerRemoveCmd)
	providerCmd.AddCommand(providerDefaultCmd)
	providerCmd.AddCommand(providerTestCmd)
	providerCmd.AddCommand(providerTypesCmd)

	rootCmd.AddCommand(providerCmd)
}
