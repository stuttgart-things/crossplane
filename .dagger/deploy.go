package main

import (
	"context"
	"dagger/dagger/internal/dagger"
)

func (m *Dagger) DeployCrossplaneCRDS(
	ctx context.Context,
	// +optional
	// +default="https://github.com/stuttgart-things/helm/cicd/crds/crossplane"
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

func (m *Dagger) DeployCrossplaneChart(
	ctx context.Context,
	// +optional
	// +default="git::https://github.com/stuttgart-things/helm.git@cicd/crossplane.yaml.gotmpl"
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

func (m *Dagger) DeployCrossplane(
	ctx context.Context,
	// +optional
	// +default=true
	deployCore bool,
	// +optional
	// +default=true
	deployCrossplaneCRDs bool,
	// +optional
	// +default="https://github.com/stuttgart-things/helm/cicd/crds/crossplane"
	crossplaneCRDsSource string,
	// +optional
	// +default="git::https://github.com/stuttgart-things/helm.git@cicd/crossplane.yaml.gotmpl"
	coreHelmfileRef string,
	// +optional
	// +default=true
	deployConfigurations bool,
	// +optional
	// +default="https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/configurations/volume-claim.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/configurations/storage-platform.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/configurations/pipeline-integration.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/configurations/ansible-run.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/configurations/cloud-config.yaml"
	configurationsSourceURLs string,
	// +optional
	// +default=true
	deployFunctions bool,
	// +optional
	// +default="https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/functions/function-auto-ready.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/functions/function-go-templating.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/functions/function-kcl.yaml,https://raw.githubusercontent.com/stuttgart-things/crossplane/refs/heads/main/packages/functions/function-patch-and-transform.yaml"
	functionsSourceURLs string,
	// +optional
	// +default="crossplane-system"
	namespace string,
	// +optional
	kubeConfig *dagger.Secret,
	// Comma-separated key=value pairs for --state-values-set
	// (e.g., "issuerName=cluster-issuer-approle,domain=demo.example.com")
	// +optional
	coreStateValues string,
) error {
	// Deploy Crossplane CRDs first if requested
	if deployCrossplaneCRDs {
		_, err := m.DeployCrossplaneCRDS(ctx, crossplaneCRDsSource, kubeConfig)
		if err != nil {
			return err
		}
	}

	// Deploy Crossplane chart if requested
	if deployCore {
		err := m.DeployCrossplaneChart(ctx, coreHelmfileRef, kubeConfig, coreStateValues)
		if err != nil {
			return err
		}
	}

	// Deploy Configurations if requested
	if deployConfigurations {
		_, err := m.DeployConfigurations(ctx, configurationsSourceURLs, namespace, kubeConfig)
		if err != nil {
			return err
		}
	}

	// Deploy Functions if requested
	if deployFunctions {
		_, err := m.DeployFunctions(ctx, functionsSourceURLs, namespace, kubeConfig)
		if err != nil {
			return err
		}
	}

	return nil
}
