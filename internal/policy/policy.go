package policy

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// PolicyPreset represents a predefined network policy configuration.
type PolicyPreset struct {
	Name        string           `json:"name"`
	Description string           `json:"description"`
	Endpoints   []PolicyEndpoint `json:"endpoints"`
}

// PolicyEndpoint represents an endpoint in a policy.
type PolicyEndpoint struct {
	Host     string       `json:"host"`
	Port     int          `json:"port"`
	Protocol string       `json:"protocol,omitempty"`
	Binaries []string     `json:"binaries,omitempty"`
	Rules    []PolicyRule `json:"rules,omitempty"`
}

// PolicyRule represents an HTTP rule for a policy.
type PolicyRule struct {
	Method string `json:"method"`
	Path   string `json:"path"`
}

// BuiltInPresets are the predefined policy presets from NemoClaw.
var BuiltInPresets = map[string]PolicyPreset{
	"discord": {
		Name:        "discord",
		Description: "Discord API, gateway, and CDN",
		Endpoints: []PolicyEndpoint{
			{Host: "discord.com", Port: 443},
			{Host: "gateway.discord.gg", Port: 443},
			{Host: "cdn.discordapp.com", Port: 443},
		},
	},
	"docker": {
		Name:        "docker",
		Description: "Docker Hub and NVIDIA container registry",
		Endpoints: []PolicyEndpoint{
			{Host: "registry.hub.docker.com", Port: 443},
			{Host: "nvcr.io", Port: 443},
		},
	},
	"github": {
		Name:        "github",
		Description: "GitHub API and webhooks",
		Endpoints: []PolicyEndpoint{
			{Host: "github.com", Port: 443},
			{Host: "api.github.com", Port: 443},
		},
	},
	"huggingface": {
		Name:        "huggingface",
		Description: "Hugging Face Hub, LFS, and Inference API",
		Endpoints: []PolicyEndpoint{
			{Host: "huggingface.co", Port: 443},
			{Host: "cdn.huggingface.co", Port: 443},
			{Host: "api-inference.huggingface.co", Port: 443},
		},
	},
	"jira": {
		Name:        "jira",
		Description: "Jira and Atlassian Cloud",
		Endpoints: []PolicyEndpoint{
			{Host: "api.atlassian.com", Port: 443},
			{Host: "your-domain.atlassian.net", Port: 443},
		},
	},
	"npm": {
		Name:        "npm",
		Description: "npm and Yarn registry",
		Endpoints: []PolicyEndpoint{
			{Host: "registry.npmjs.org", Port: 443},
		},
	},
	"outlook": {
		Name:        "outlook",
		Description: "Microsoft Outlook and Graph API",
		Endpoints: []PolicyEndpoint{
			{Host: "graph.microsoft.com", Port: 443},
			{Host: "outlook.office.com", Port: 443},
		},
	},
	"pypi": {
		Name:        "pypi",
		Description: "Python Package Index",
		Endpoints: []PolicyEndpoint{
			{Host: "pypi.org", Port: 443},
			{Host: "files.pythonhosted.org", Port: 443},
		},
	},
	"slack": {
		Name:        "slack",
		Description: "Slack API and webhooks",
		Endpoints: []PolicyEndpoint{
			{Host: "slack.com", Port: 443},
			{Host: "api.slack.com", Port: 443},
			{Host: "hooks.slack.com", Port: 443},
		},
	},
	"telegram": {
		Name:        "telegram",
		Description: "Telegram Bot API",
		Endpoints: []PolicyEndpoint{
			{Host: "api.telegram.org", Port: 443},
		},
	},
}

// GetPresetNames returns the list of available preset names.
func GetPresetNames() []string {
	names := make([]string, 0, len(BuiltInPresets))
	for name := range BuiltInPresets {
		names = append(names, name)
	}
	return names
}

// GetPreset returns a preset by name.
func GetPreset(name string) (PolicyPreset, bool) {
	preset, ok := BuiltInPresets[name]
	return preset, ok
}

// ApplyPreset applies a policy preset to a running sandbox.
func ApplyPreset(sandboxName, presetName string) error {
	preset, ok := BuiltInPresets[presetName]
	if !ok {
		return fmt.Errorf("preset '%s' not found", presetName)
	}

	// Generate YAML for the preset
	yamlContent := generatePolicyYAML(preset)

	// Write to temp file
	tmpFile := fmt.Sprintf("/tmp/clawbox-policy-%s-%s.yaml", sandboxName, presetName)
	if err := os.WriteFile(tmpFile, []byte(yamlContent), 0644); err != nil {
		return fmt.Errorf("failed to write policy file: %w", err)
	}
	defer os.Remove(tmpFile)

	// Apply via openshell
	cmd := exec.Command("openshell", "policy", "set", "--policy", tmpFile, "--wait", sandboxName)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to apply policy: %w\n%s", err, string(output))
	}

	return nil
}

// GetPolicy retrieves the current policy for a sandbox.
func GetPolicy(sandboxName string) (string, error) {
	cmd := exec.Command("openshell", "policy", "get", "--full", sandboxName)
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get policy: %w", err)
	}
	return string(output), nil
}

// ListAppliedPolicies returns the list of policies applied to a sandbox.
func ListAppliedPolicies(sandboxName string) ([]string, error) {
	policyYAML, err := GetPolicy(sandboxName)
	if err != nil {
		return nil, err
	}

	// Parse policy names from YAML
	var policies []string
	lines := strings.Split(policyYAML, "\n")
	for _, line := range lines {
		if strings.Contains(line, "name:") && !strings.HasPrefix(strings.TrimSpace(line), "#") {
			// Extract policy name from line like "  slack:" or "name: slack"
			parts := strings.Fields(line)
			if len(parts) >= 2 {
				name := strings.TrimSuffix(parts[0], ":")
				if name != "version" && name != "filesystem_policy" && name != "process" && name != "network_policies" {
					policies = append(policies, name)
				}
			}
		}
	}

	return policies, nil
}

// generatePolicyYAML generates OpenShell-compatible YAML for a policy preset.
func generatePolicyYAML(preset PolicyPreset) string {
	var sb strings.Builder
	sb.WriteString("network_policies:\n")
	sb.WriteString(fmt.Sprintf("  %s:\n", preset.Name))
	sb.WriteString(fmt.Sprintf("    name: %s\n", preset.Name))
	sb.WriteString("    endpoints:\n")

	for _, ep := range preset.Endpoints {
		sb.WriteString(fmt.Sprintf("      - host: %s\n", ep.Host))
		sb.WriteString(fmt.Sprintf("        port: %d\n", ep.Port))
		sb.WriteString("        protocol: rest\n")
		sb.WriteString("        enforcement: enforce\n")
		sb.WriteString("        tls: terminate\n")
		if len(ep.Rules) > 0 {
			sb.WriteString("        rules:\n")
			for _, rule := range ep.Rules {
				sb.WriteString(fmt.Sprintf("          - allow: { method: %s, path: \"%s\" }\n", rule.Method, rule.Path))
			}
		} else {
			sb.WriteString("        rules:\n")
			sb.WriteString("          - allow: { method: \"*\", path: \"/**\" }\n")
		}
	}

	return sb.String()
}

// GenerateCustomPolicyYAML generates a policy YAML for custom endpoints.
func GenerateCustomPolicyYAML(name string, endpoints []PolicyEndpoint) string {
	preset := PolicyPreset{
		Name:      name,
		Endpoints: endpoints,
	}
	return generatePolicyYAML(preset)
}
