# Garage

Garage is an S3-compatible object store designed for small self-hosted clusters.
This wrapper chart vendors the upstream Garage Helm chart (from the Garage git repo)
with values pre-configured for the brians-tpi-cluster.

## Updating the upstream chart

The Garage Helm chart is vendored in `charts/garage/` (not published to a Helm
registry). To upgrade to a newer version, replace it from the upstream repo:

```bash
git clone https://git.deuxfleurs.fr/Deuxfleurs/garage /tmp/garage
git -C /tmp/garage checkout <new-version-tag>
rm -rf helm/garage/charts/garage
cp -r /tmp/garage/script/helm/garage helm/garage/charts/garage
helm dependency build helm/garage
```

## Install

Create the namespace and admin token secret first:

```bash
kubectl create namespace garage

kubectl create secret generic garage-admin-secret \
  --namespace garage \
  --from-literal=token=$(openssl rand -base64 32)
```

Then install:

```bash
helm upgrade --install garage . --namespace garage --create-namespace --wait
```

## Post-install: assign layout

Get the node IDs, then assign each pod to a zone (one zone per physical node):

```bash
kubectl exec --stdin --tty -n garage garage-0 -- ./garage status
```

```bash
kubectl exec -n garage garage-0 -- ./garage layout assign -z frog  -c 50G <node-id-0>
kubectl exec -n garage garage-1 -- ./garage layout assign -z marle -c 50G <node-id-1>
kubectl exec -n garage garage-2 -- ./garage layout assign -z robo  -c 50G <node-id-2>

kubectl exec -n garage garage-0 -- ./garage layout apply --version 1
```

Verify the cluster is healthy:

```bash
kubectl exec --stdin --tty -n garage garage-0 -- ./garage status
```

## Key management

Each service gets its own dedicated Garage access key scoped to only the buckets it needs.
Never share keys between services.

| Key name  | Used by                          | Buckets                       |
|-----------|----------------------------------|-------------------------------|
| `brian`   | Admin / personal access          | `misc`, `mlflow`              |
| `jupyter` | JupyterHub notebook pods         | `warehouse`, `misc`           |
| `polaris` | Apache Polaris (metadata writes) | `warehouse`                   |
| `spark`   | Spark Connect data + manifest writes | `warehouse`               |

Buckets:
- `warehouse` — All Iceberg table data and metadata for the Polaris catalog. Polaris writes metadata JSON here; Spark writes data and manifest files here.

To create a new key and grant bucket access:

```bash
kubectl exec -n garage garage-0 -- /garage key create <name>
kubectl exec -n garage garage-0 -- /garage bucket allow --read --write --owner <bucket> --key <key-id>
```

The corresponding Kubernetes secret should be named `<service>-s3-credentials` and
created in the service's namespace.

## Monitoring

The Garage ServiceMonitor is enabled in `values.yaml` (`monitoring.metrics.serviceMonitor.enabled: true`).
Prometheus scrapes the `/metrics` endpoint on the Garage service and places results in the
`monitoring` namespace. No additional setup required.

## Verify values

To see all available configuration options from the upstream chart:

```bash
helm show values charts/garage
```
