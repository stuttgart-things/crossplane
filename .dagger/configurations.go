package main

import (
	"context"
	"dagger/dagger/internal/dagger"
)

func (m *Dagger) DeployConfigurations(
	ctx context.Context,
	// +optional
	// +default="https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/configurations/volume-claim.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/configurations/storage-platform.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/configurations/pipeline-integration.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/configurations/ansible-run.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/configurations/cloud-config.yaml"
	sourceURLs string,
	// +optional
	// +default="crossplane-system"
	namespace string,
	kubeConfig *dagger.Secret,
) (string, error) {
	return dag.
		KubernetesDeployment().
		ApplyManifests(
			ctx,
			dagger.KubernetesDeploymentApplyManifestsOpts{
				SourceUrls: sourceURLs,
				KubeConfig: kubeConfig,
				Namespace:  namespace,
			},
		)
}
