package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/clawboxhq/clawbox-installer/internal/provider"
	"github.com/spf13/cobra"
)

var (
	cfgFile   string
	version   string
	gitCommit string
	buildDate string
)

var rootCmd = &cobra.Command{
	Use:   "clawbox",
	Short: "Secure AI Assistant in a Box",
	Long: `ClawBox - Secure AI Assistant in a Box

One-click cross-platform installer for OpenShell + NemoClaw + OpenClaw
with secure sandboxing and persistent volume mounting.

Supports multiple LLM providers: NVIDIA, OpenAI, Anthropic, OpenRouter,
Ollama, LM Studio, llama.cpp, vLLM, and custom endpoints.`,
	Version: version,
}

func Execute(v, gc, bd string) error {
	version = v
	gitCommit = gc
	buildDate = bd

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		return err
	}
	return nil
}

func init() {
	cobra.OnInitialize(initConfig)
	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is ~/.clawbox/config.json)")
}

func initConfig() {
	if cfgFile == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		cfgFile = filepath.Join(home, ".clawbox", "config.json")
	}
}

func getConfigDir() string {
	if cfgFile != "" {
		return filepath.Dir(cfgFile)
	}
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".clawbox")
}

func loadConfig() (*Config, error) {
	config := &Config{}
	data, err := os.ReadFile(cfgFile)
	if err != nil {
		if os.IsNotExist(err) {
			return config, nil
		}
		return nil, err
	}
	if err := json.Unmarshal(data, config); err != nil {
		return nil, err
	}
	return config, nil
}

func saveConfig(config *Config) error {
	dir := filepath.Dir(cfgFile)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}
	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(cfgFile, data, 0644)
}

type Config struct {
	DefaultProvider  string                       `json:"defaultProvider"`
	Providers        map[string]provider.Provider `json:"providers"`
	Sandboxes        []SandboxConfig              `json:"sandboxes"`
	OpenClawVersion  string                       `json:"openClawVersion"`
	OpenShellVersion string                       `json:"openShellVersion"`
	ContainerRuntime string                       `json:"containerRuntime"`
}

type SandboxConfig struct {
	Name     string `json:"name"`
	Provider string `json:"provider"`
	Model    string `json:"model"`
	Port     int    `json:"port"`
}
