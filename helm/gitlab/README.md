# GitLab

Self-hosted GitLab CE via the official Helm chart. Uses our existing CloudNativePG PostgreSQL
cluster and Garage S3 for storage. Traefik + cert-manager handle ingress and TLS.

## Architecture

- **Web**: `https://gitlab.brians.computer` via Traefik ingress
- **SSH**: `git@gitlab.brians.computer` via Traefik TCP entrypoint (port 22 → internal port 2222)
- **Database**: External CloudNativePG at `postgres.brians.computer`
- **Object storage**: External Garage S3 at `https://garage.brians.computer`
- **Git storage**: Gitaly with Longhorn 50Gi PVC
- **Redis**: Bundled (in-cluster)
- **Registry**: Disabled (enable later — see bottom of this file)

## Notes on chart v9 (GitLab 18.x)

- **KAS (Kubernetes Agent Server)** cannot be disabled in chart v9 — the template renders it
  regardless of `gitlab.kas.enabled: false`. It is harmless but will always run.
- **cert-manager**: use `installCertmanager: false` (top-level) to prevent the chart from
  deploying its own bundled cert-manager. `certmanager.install` was removed in v9.
- **ARM boot times**: Puma (webservice) and Sidekiq take 5–10 minutes to boot on ARM hardware.
  The values file has startup/liveness probe overrides to accommodate this.
- **Migrations memory**: First-run migrations for GitLab 18.x require up to 3Gi RAM. The
  migrations resource limit in values.yaml reflects this.

## Pre-install

### 1. Update Traefik to add the SSH entrypoint

The Traefik values already include the SSH entrypoint. Upgrade Traefik first so port 22 is
available on the LoadBalancer before GitLab starts:

```bash
helm upgrade traefik traefik/traefik -n kube-system -f ../traefik/values.yaml
```

Verify port 22 appears:

```bash
kubectl get svc traefik -n kube-system
# Should show: 22:xxxxx/TCP,80:xxxxx/TCP,443:xxxxx/TCP
```

### 2. Add Helm repo

```bash
helm repo add gitlab https://charts.gitlab.io
helm repo update
```

### 3. Create namespace

```bash
kubectl create namespace gitlab
```

### 4. Create PostgreSQL database

The `app` user lacks `CREATEROLE`, so connect via exec into the pod as the `postgres` superuser:

```bash
kubectl exec -n postgres postgres-1 -- psql -U postgres -c \
  "CREATE USER gitlab WITH PASSWORD 'choose-a-strong-password';"

kubectl exec -n postgres postgres-1 -- psql -U postgres -c \
  "CREATE DATABASE gitlab OWNER gitlab;"
```

### 5. Create Garage S3 key and buckets

Garage has no CLI in the container PATH — use the admin HTTP API directly.
Get the admin token from the secret first:

```bash
GARAGE_TOKEN=$(kubectl get secret garage-admin-secret -n garage \
  -o jsonpath='{.data.token}' | base64 -d)
GARAGE_ADMIN=http://$(kubectl get svc garage-admin -n garage \
  -o jsonpath='{.spec.clusterIP}'):3903
```

Create the key:

```bash
curl -s -X POST \
  -H "Authorization: Bearer $GARAGE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "gitlab"}' \
  $GARAGE_ADMIN/v1/key
# Note the accessKeyId and secretAccessKey from the response
```

Create each bucket and grant access (replace `<KEY_ID>` with the accessKeyId from above,
and `<BUCKET_ID>` with the id returned from each bucket create):

```bash
for bucket in gitlab-lfs gitlab-artifacts gitlab-uploads gitlab-packages \
              gitlab-mr-diffs gitlab-terraform-state gitlab-ci-secure-files \
              gitlab-dependency-proxy; do
  # Create bucket
  BUCKET_ID=$(curl -s -X POST \
    -H "Authorization: Bearer $GARAGE_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"globalAlias\": \"$bucket\"}" \
    $GARAGE_ADMIN/v1/bucket | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")

  # Grant access
  curl -s -X POST \
    -H "Authorization: Bearer $GARAGE_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"bucketId\": \"$BUCKET_ID\", \"accessKeyId\": \"<KEY_ID>\", \"permissions\": {\"read\": true, \"write\": true, \"owner\": true}}" \
    $GARAGE_ADMIN/v1/bucket/allow
done
```

### 6. Create secrets

```bash
# PostgreSQL credentials (password chosen in step 4)
kubectl create secret generic gitlab-postgres-secret \
  --namespace gitlab \
  --from-literal=password='the-password-you-chose'

# Garage S3 connection (fog YAML format — fill in key/secret from step 5)
kubectl create secret generic gitlab-s3-secret \
  --namespace gitlab \
  --from-literal=connection="$(cat <<'EOF'
provider: AWS
region: garage
aws_access_key_id: YOUR_GARAGE_ACCESS_KEY
aws_secret_access_key: YOUR_GARAGE_SECRET_KEY
aws_signature_version: 4
enable_signature_v4_streaming: false
host: garage.brians.computer
endpoint: https://garage.brians.computer
path_style: true
EOF
)"

# Gitaly auth token
kubectl create secret generic gitlab-gitaly-secret \
  --namespace gitlab \
  --from-literal=token=$(openssl rand -hex 32)

# Shell auth token
kubectl create secret generic gitlab-shell-secret \
  --namespace gitlab \
  --from-literal=secret=$(openssl rand -hex 32)

# Initial root password
kubectl create secret generic gitlab-initial-root-password \
  --namespace gitlab \
  --from-literal=password=$(openssl rand -base64 24)
```

## Install

```bash
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --timeout 600s \
  --version 9.11.3 \
  -f values.yaml
```

GitLab takes 10–15 minutes to fully start on ARM. Monitor progress:

```bash
kubectl get pods -n gitlab -w
```

The migrations job must complete before the webservice becomes ready. Watch for
`gitlab-migrations-* Completed` before expecting the webservice to pass readiness.

Once all pods are running, apply the SSH TCP route:

```bash
kubectl apply -f ssh-route.yaml
```

## Post-install

### TLS certificate

The chart's bundled cert-manager (now disabled) will have issued a self-signed certificate
on first boot. Force our real Let's Encrypt cert by deleting the secret — cert-manager
will re-issue it immediately via DNS-01:

```bash
kubectl delete secret gitlab-wildcard-tls -n gitlab
# Watch the challenge complete:
kubectl get challenge -n gitlab -w
```

### Retrieve root password

```bash
kubectl get secret gitlab-initial-root-password -n gitlab \
  -o jsonpath='{.data.password}' | base64 -d
```

Log in at `https://gitlab.brians.computer` as `root` with this password.

### Verify SSH

```bash
# Should respond: "Welcome to GitLab, @root!" (after adding your SSH key in the UI)
ssh -T git@gitlab.brians.computer
```

## Upgrading

```bash
helm upgrade gitlab gitlab/gitlab \
  --namespace gitlab \
  --timeout 600s \
  --version 9.11.3 \
  -f values.yaml
```

## Enabling the container registry

Create the bucket via the Garage admin API first (see step 5 pattern above):

```bash
BUCKET_ID=$(curl -s -X POST \
  -H "Authorization: Bearer $GARAGE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"globalAlias": "gitlab-registry"}' \
  $GARAGE_ADMIN/v1/bucket | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")

curl -s -X POST \
  -H "Authorization: Bearer $GARAGE_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"bucketId\": \"$BUCKET_ID\", \"accessKeyId\": \"<KEY_ID>\", \"permissions\": {\"read\": true, \"write\": true, \"owner\": true}}" \
  $GARAGE_ADMIN/v1/bucket/allow
```

Then add to values.yaml and upgrade:

```yaml
registry:
  enabled: true

global:
  hosts:
    registry:
      name: registry.gitlab.brians.computer
  appConfig:
    registry:
      bucket: gitlab-registry
```
