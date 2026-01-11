package main

import (
	"context"
	"dagger/dagger/internal/dagger"
)

func (m *Dagger) DeployFunctions(
	ctx context.Context,
	// +optional
	// +default="https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/functions/function-auto-ready.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/functions/function-go-templating.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/functions/function-kcl.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/functions/function-patch-and-transform.yaml"
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
