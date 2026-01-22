# stuttgart-things/crossplane/postgres-db

## REQUIREMENTS

<details><summary><b>CONNECT TO POSTGRESDB</b></summary>

```bash
# GET SERVICE
kubectk get svc -m postgres

# GET USER
kubectl get pod -n postgres -l app.kubernetes.io/name=postgres -o yaml | grep -A5 POSTGRESES

# RUN SQL CLIENT
kubectl run -n postgres -it psql-client --rm --image=postgres --restart=Never -- bash

# CONNECT TO DB
psql \
  -h my-postgres-d499897318cc \
  -U appuser \
  -d appdb \
  -p 5432

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
  package: xpkg.upbound.io/crossplane-contrib/provider-sql:v0.13.0
EOF
```

```bash
kubectl apply -f - <<EOF
---
apiVersion: postgresql.sql.m.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: default
spec:
  sslMode: disable
  credentials:
    source: PostgreSQLConnectionSecret
    connectionSecretRef:
      name: postgresdb-creds
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
