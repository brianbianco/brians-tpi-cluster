# Promtail

DaemonSet that ships pod logs from every cluster node to Loki.

Install Loki first before deploying Promtail.

## Add the Helm repo

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

## Install

```bash
helm dependency update ./helm/promtail

helm upgrade --install promtail ./helm/promtail \
  --namespace monitoring \
  --wait
```

## Verify

```bash
# One Promtail pod should be running on each node
kubectl get pods -n monitoring -l app.kubernetes.io/name=promtail -o wide
```
