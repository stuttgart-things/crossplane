package main

import (
	"context"
	"dagger/dagger/internal/dagger"
)

func (m *Dagger) DeployCilium(
	ctx context.Context,
	// +optional
	// +default=true
	deployCRDs bool,
	// +optional
	// +default="https://github.com/stuttgart-things/helm/infra/crds/cilium"
	crdSource string,
	// +optional
	// +default="git::https://github.com/stuttgart-things/helm.git@infra/cilium.yaml.gotmpl"
	helmfileRef string,
	// +optional
	kubeConfig *dagger.Secret,
	// Comma-separated key=value pairs for --state-values-set
	// (e.g., "issuerName=cluster-issuer-approle,domain=demo.example.com")
	// +optional
	stateValues string,
) error {
	// Deploy CRDs first if requested
	if deployCRDs {
		_, err := m.DeployCiliumCRDS(ctx, crdSource, kubeConfig)
		if err != nil {
			return err
		}
	}

	// Deploy the Cilium chart
	return m.DeployCiliumChart(ctx, helmfileRef, kubeConfig, stateValues)
}

func (m *Dagger) DeployCiliumChart(
	ctx context.Context,
	// +optional
	// +default="git::https://github.com/stuttgart-things/helm.git@infra/cilium.yaml.gotmpl"
	helmfileRef string,
	// +optional
	kubeConfig *dagger.Secret,
	// Comma-separated key=value pairs for --state-values-set
	// (e.g., "issuerName=cluster-issuer-approle,domain=demo.example.com")
	// +optional
	stateValues string,
) error {
	return dag.
		KubernetesDeployment().
		DeployMicroservices(
			ctx,
			dagger.KubernetesDeploymentDeployMicroservicesOpts{
				HelmfileRefs: helmfileRef,
				KubeConfig:   kubeConfig,
				StateValues:  stateValues,
			},
		)
}

func (m *Dagger) DeployCiliumCRDS(
	ctx context.Context,
	// +optional
	// +default="https://github.com/stuttgart-things/helm/infra/crds/cilium"
	crdSource string,
	kubeConfig *dagger.Secret,
) (string, error) {
	return dag.
		KubernetesDeployment().
		InstallCustomResourceDefinitions(
			ctx,
			dagger.KubernetesDeploymentInstallCustomResourceDefinitionsOpts{
				KustomizeSources: crdSource,
				KubeConfig:       kubeConfig,
				ServerSide:       true,
			},
		)
}
