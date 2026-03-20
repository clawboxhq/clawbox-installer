package provider

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

type ProviderType string

const (
	TypeNVIDIA     ProviderType = "nvidia"
	TypeOpenAI     ProviderType = "openai"
	TypeAnthropic  ProviderType = "anthropic"
	TypeOpenRouter ProviderType = "openrouter"
	TypeOllama     ProviderType = "ollama"
	TypeLMStudio   ProviderType = "lmstudio"
	TypeLlamaCpp   ProviderType = "llamacpp"
	TypeVLLM       ProviderType = "vllm"
	TypeCustom     ProviderType = "custom"
)

type Provider struct {
	Name         string       `json:"name"`
	Type         ProviderType `json:"type"`
	Endpoint     string       `json:"endpoint,omitempty"`
	APIKey       string       `json:"apiKey,omitempty"`
	DefaultModel string       `json:"defaultModel"`
	Models       []string     `json:"models,omitempty"`
}

type ProviderInfo struct {
	Name         string
	Type         ProviderType
	DefaultModel string
	KeyPrefix    string
	KeyURL       string
	Endpoint     string
	IsLocal      bool
}

var ProviderRegistry = map[ProviderType]ProviderInfo{
	TypeNVIDIA: {
		Name:         "NVIDIA (NIM API)",
		Type:         TypeNVIDIA,
		DefaultModel: "nvidia/nemotron-3-super-120b-a12b",
		KeyPrefix:    "nvapi-",
		KeyURL:       "https://build.nvidia.com/settings/api-keys",
		Endpoint:     "https://integrate.api.nvidia.com/v1",
		IsLocal:      false,
	},
	TypeOpenAI: {
		Name:         "OpenAI",
		Type:         TypeOpenAI,
		DefaultModel: "gpt-4o",
		KeyPrefix:    "sk-",
		KeyURL:       "https://platform.openai.com/api-keys",
		Endpoint:     "https://api.openai.com/v1",
		IsLocal:      false,
	},
	TypeAnthropic: {
		Name:         "Anthropic",
		Type:         TypeAnthropic,
		DefaultModel: "claude-sonnet-4-20250514",
		KeyPrefix:    "sk-ant-",
		KeyURL:       "https://console.anthropic.com/settings/keys",
		Endpoint:     "https://api.anthropic.com/v1",
		IsLocal:      false,
	},
	TypeOpenRouter: {
		Name:         "OpenRouter",
		Type:         TypeOpenRouter,
		DefaultModel: "anthropic/claude-sonnet-4",
		KeyPrefix:    "sk-or-",
		KeyURL:       "https://openrouter.ai/keys",
		Endpoint:     "https://openrouter.ai/api/v1",
		IsLocal:      false,
	},
	TypeOllama: {
		Name:         "Ollama (Local)",
		Type:         TypeOllama,
		DefaultModel: "llama3.2",
		KeyPrefix:    "",
		KeyURL:       "https://ollama.ai/library",
		Endpoint:     "http://localhost:11434",
		IsLocal:      true,
	},
	TypeLMStudio: {
		Name:         "LM Studio (Local)",
		Type:         TypeLMStudio,
		DefaultModel: "local-model",
		KeyPrefix:    "",
		KeyURL:       "https://lmstudio.ai",
		Endpoint:     "http://localhost:1234",
		IsLocal:      true,
	},
	TypeLlamaCpp: {
		Name:         "llama.cpp Server (Local)",
		Type:         TypeLlamaCpp,
		DefaultModel: "local-model",
		KeyPrefix:    "",
		KeyURL:       "https://github.com/ggerganov/llama.cpp",
		Endpoint:     "http://localhost:8080",
		IsLocal:      true,
	},
	TypeVLLM: {
		Name:         "vLLM (Local)",
		Type:         TypeVLLM,
		DefaultModel: "local-model",
		KeyPrefix:    "",
		KeyURL:       "https://github.com/vllm-project/vllm",
		Endpoint:     "http://localhost:8000",
		IsLocal:      true,
	},
	TypeCustom: {
		Name:         "Custom Endpoint",
		Type:         TypeCustom,
		DefaultModel: "",
		KeyPrefix:    "",
		KeyURL:       "",
		Endpoint:     "",
		IsLocal:      false,
	},
}

func GetProviderTypes() []ProviderType {
	return []ProviderType{
		TypeNVIDIA, TypeOpenAI, TypeAnthropic, TypeOpenRouter,
		TypeOllama, TypeLMStudio, TypeLlamaCpp, TypeVLLM, TypeCustom,
	}
}

func GetProviderInfo(t ProviderType) (ProviderInfo, bool) {
	info, ok := ProviderRegistry[t]
	return info, ok
}

func ValidateAPIKey(t ProviderType, key string) error {
	info, ok := GetProviderInfo(t)
	if !ok {
		return fmt.Errorf("unknown provider type: %s", t)
	}

	if info.IsLocal {
		return nil // Local providers don't need API keys
	}

	if key == "" {
		return fmt.Errorf("API key required for %s", info.Name)
	}

	if info.KeyPrefix != "" && len(key) < 8 {
		return fmt.Errorf("API key too short for %s", info.Name)
	}

	return nil
}

func TestConnection(p *Provider) error {
	client := &http.Client{Timeout: 10 * time.Second}

	endpoint := p.Endpoint
	if endpoint == "" {
		info, ok := GetProviderInfo(p.Type)
		if !ok {
			return fmt.Errorf("unknown provider type: %s", p.Type)
		}
		endpoint = info.Endpoint
	}

	switch p.Type {
	case TypeOllama:
		resp, err := client.Get(endpoint + "/api/tags")
		if err != nil {
			return fmt.Errorf("cannot connect to Ollama: %w", err)
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			return fmt.Errorf("Ollama returned status %d", resp.StatusCode)
		}
		return nil

	case TypeLMStudio, TypeLlamaCpp, TypeVLLM, TypeCustom:
		resp, err := client.Get(endpoint + "/models")
		if err != nil {
			return fmt.Errorf("cannot connect to %s: %w", p.Type, err)
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			return fmt.Errorf("%s returned status %d", p.Type, resp.StatusCode)
		}
		return nil

	default:
		req, err := http.NewRequest("GET", endpoint+"/models", nil)
		if err != nil {
			return err
		}
		if p.APIKey != "" {
			req.Header.Set("Authorization", "Bearer "+p.APIKey)
		}
		resp, err := client.Do(req)
		if err != nil {
			return fmt.Errorf("cannot connect to %s: %w", p.Type, err)
		}
		defer resp.Body.Close()
		if resp.StatusCode == http.StatusUnauthorized {
			return fmt.Errorf("invalid API key for %s", p.Type)
		}
		if resp.StatusCode != http.StatusOK {
			return fmt.Errorf("%s returned status %d", p.Type, resp.StatusCode)
		}
		return nil
	}
}

func GetModels(p *Provider) ([]string, error) {
	client := &http.Client{Timeout: 10 * time.Second}

	endpoint := p.Endpoint
	if endpoint == "" {
		info, ok := GetProviderInfo(p.Type)
		if !ok {
			return nil, fmt.Errorf("unknown provider type: %s", p.Type)
		}
		endpoint = info.Endpoint
	}

	switch p.Type {
	case TypeOllama:
		resp, err := client.Get(endpoint + "/api/tags")
		if err != nil {
			return nil, err
		}
		defer resp.Body.Close()

		var result struct {
			Models []struct {
				Name string `json:"name"`
			} `json:"models"`
		}
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			return nil, err
		}
		models := make([]string, len(result.Models))
		for i, m := range result.Models {
			models[i] = m.Name
		}
		return models, nil

	default:
		req, err := http.NewRequest("GET", endpoint+"/models", nil)
		if err != nil {
			return nil, err
		}
		if p.APIKey != "" {
			req.Header.Set("Authorization", "Bearer "+p.APIKey)
		}
		resp, err := client.Do(req)
		if err != nil {
			return nil, err
		}
		defer resp.Body.Close()

		var result struct {
			Data []struct {
				ID string `json:"id"`
			} `json:"data"`
		}
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			return nil, err
		}
		models := make([]string, len(result.Data))
		for i, m := range result.Data {
			models[i] = m.ID
		}
		return models, nil
	}
}
