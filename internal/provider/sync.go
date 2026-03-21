package provider

import (
	"fmt"
	"os/exec"
	"strings"
)

// SyncToOpenShell creates or updates a provider in OpenShell.
// This is critical for sandboxes to actually use the configured providers.
func SyncToOpenShell(p *Provider) error {
	if OpenShellProviderExists(p.Name) {
		return updateOpenShellProvider(p)
	}
	return createOpenShellProvider(p)
}

// OpenShellProviderExists checks if a provider exists in OpenShell.
func OpenShellProviderExists(name string) bool {
	cmd := exec.Command("openshell", "provider", "list")
	output, err := cmd.Output()
	if err != nil {
		return false
	}
	return strings.Contains(string(output), name)
}

// createOpenShellProvider creates a new provider in OpenShell.
func createOpenShellProvider(p *Provider) error {
	args := []string{
		"provider", "create",
		"--name", p.Name,
		"--type", string(p.Type),
	}

	if p.Endpoint != "" {
		args = append(args, "--endpoint", p.Endpoint)
	}

	if p.APIKey != "" {
		args = append(args, "--credential", fmt.Sprintf("%s_API_KEY=%s", strings.ToUpper(string(p.Type)), p.APIKey))
	}

	cmd := exec.Command("openshell", args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to create OpenShell provider: %w\n%s", err, string(output))
	}

	return nil
}

// updateOpenShellProvider updates an existing provider in OpenShell.
func updateOpenShellProvider(p *Provider) error {
	args := []string{
		"provider", "update", p.Name,
	}

	if p.Endpoint != "" {
		args = append(args, "--endpoint", p.Endpoint)
	}

	if p.APIKey != "" {
		args = append(args, "--credential", fmt.Sprintf("%s_API_KEY=%s", strings.ToUpper(string(p.Type)), p.APIKey))
	}

	cmd := exec.Command("openshell", args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to update OpenShell provider: %w\n%s", err, string(output))
	}

	return nil
}

// DeleteFromOpenShell removes a provider from OpenShell.
func DeleteFromOpenShell(name string) error {
	if !OpenShellProviderExists(name) {
		return nil // Already gone
	}

	cmd := exec.Command("openshell", "provider", "delete", name)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to delete OpenShell provider: %w\n%s", err, string(output))
	}

	return nil
}

// SetInference configures the inference route for a sandbox.
func SetInference(providerName, model string) error {
	cmd := exec.Command("openshell", "inference", "set", "--provider", providerName, "--model", model)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to set inference: %w\n%s", err, string(output))
	}
	return nil
}

// GetInferenceStatus returns the current inference configuration.
func GetInferenceStatus(sandboxName string) (provider, model string, err error) {
	cmd := exec.Command("openshell", "inference", "status", sandboxName)
	output, err := cmd.Output()
	if err != nil {
		return "", "", fmt.Errorf("failed to get inference status: %w", err)
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if strings.Contains(line, "Provider:") {
			provider = strings.TrimSpace(strings.TrimPrefix(line, "Provider:"))
		}
		if strings.Contains(line, "Model:") {
			model = strings.TrimSpace(strings.TrimPrefix(line, "Model:"))
		}
	}

	return provider, model, nil
}
