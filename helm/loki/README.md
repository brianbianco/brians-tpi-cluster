# Loki

Grafana Loki in single-binary mode for cluster-wide log aggregation.

The Grafana datasource for Loki is pre-configured in `helm/kube-prometheus-stack/values.yaml`
and will become active as soon as Loki is running.

## Add the Helm repo

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

## Install

```bash
helm dependency update ./helm/loki

helm upgrade --install loki ./helm/loki \
  --namespace monitoring \
  --wait
```

## Verify

```bash
# Check the Loki pod is running
kubectl get pods -n monitoring -l app.kubernetes.io/name=loki

# Query Loki directly
kubectl port-forward -n monitoring svc/loki 3100:3100
curl http://localhost:3100/ready
```

## Log exploration

Open Grafana → Explore → select the **Loki** datasource.

Useful LogQL queries:
- All cluster logs: `{namespace=~".+"}`
- Errors only: `{namespace=~".+"} |= "error" | logfmt`
- Specific namespace: `{namespace="monitoring"}`
- Specific pod: `{pod=~"ollama.*"}`
