# stuttgart-things/crossplane/postgres-db

## REQUIREMENTS

<details><summary><b>DEPLOY POSTGRESDB w/ HELM</b></summary>

```bash
cat <<EOF > values.yaml
---
global:
  postgresql:
    auth:
      postgresPassword: volki123
      username: volki
      password: volki123
      database: volki
EOF

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm upgrade --install postgresql bitnami/postgresql \
--version 16.7.13 \
-n xplane \
--create-namespace \
--values values.yaml
```

```bash
kubectl run -n xplane -it psql-client --rm --image=postgres --restart=Never -- bash

psql -h postgresql.xplane.svc.cluster.local -U postgres -p 5432

\l # list databases
```

</details>

<details><summary><b>INSTALL SQL CROSSPLANE PROVIDER + CONFIG</b></summary>

```bash
kubectl apply -f - <<EOF
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-sql
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-sql:v0.12.0
EOF
```

```bash
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Secret
type: kubernetes.io/basic-auth
metadata:
  name: volki-postgres-secret
  namespace: xplane
stringData:
  username: postgres
  password: volki123
  endpoint: postgresql.xplane.svc.cluster.local
  port: "5432"
EOF
```

```bash
kubectl apply -f - <<EOF
---
apiVersion: postgresql.sql.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: default
spec:
  defaultDatabase: postgres
  sslMode: disable
  credentials:
    source: PostgreSQLConnectionSecret
    connectionSecretRef:
      namespace: xplane
      name: volki-postgres-secret
EOF
```

</details>

<details><summary><b>TEST CREATION OF DB (FOR TESTING THE PROVIDER)</b></summary>

```bash
kubectl apply -f - <<EOF
---
apiVersion: postgresql.sql.crossplane.io/v1alpha1
kind: Role
metadata:
  name: ownerrole
spec:
  deletionPolicy:  Orphan
  writeConnectionSecretToRef:
    name: ownerrole-secret
    namespace: default
  forProvider:
    privileges:
      createDb: true
      login: true
      createRole: true
      inherit: true
---
apiVersion: postgresql.sql.crossplane.io/v1alpha1
kind: Grant
metadata:
  name: grant-postgres-an-owner-role
spec:
  deletionPolicy:  Orphan
  forProvider:
    role: "postgres"
    memberOfRef:
      name: "ownerrole"
---
apiVersion: postgresql.sql.crossplane.io/v1alpha1
kind: Database
metadata:
  name: db1
spec:
  deletionPolicy: Orphan
  forProvider:
    allowConnections: true
    owner: "ownerrole"
EOF
```

</details>
