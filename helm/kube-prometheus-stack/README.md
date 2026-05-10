# kube-prometheus-stack

Prometheus + Grafana + Alertmanager for the TPI cluster.

## Install

```bash
# Create namespace
kubectl create namespace monitoring

# Create Grafana admin credentials secret
kubectl create secret generic grafana-secret \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=<your-password> \
  -n monitoring

# Fetch chart dependencies
helm dependency update ./helm/kube-prometheus-stack

# Install
helm upgrade --install kube-prometheus-stack ./helm/kube-prometheus-stack \
  --namespace monitoring \
  --wait
```

## URLs

- Grafana: https://grafana.brians.computer
- Prometheus: https://prometheus.brians.computer
- Alertmanager: https://alertmanager.brians.computer

## k3s notes

Controller-manager, scheduler, and kube-proxy monitors are disabled because k3s
runs these inside its single binary — there are no pods for the ServiceMonitors
to target. etcd metrics are scraped directly from port 2381 on the control-plane.

## Adding Loki later

The Grafana datasource for Loki is pre-configured in values.yaml. Once you install
Loki in the `monitoring` namespace it will appear automatically in Grafana.

## Service Health Monitoring (Blackbox Exporter)

The `prometheus-blackbox-exporter` subchart is included and probes all cluster ingress
endpoints every 60s over HTTPS. Results are available as the `probe_success` metric
(1 = up, 0 = down) and visualized in the pre-loaded Grafana dashboard
[Prometheus Blackbox Exporter (ID 7587)](https://grafana.com/grafana/dashboards/7587).

### Probe targets

Targets are defined as `Probe` CRDs in `manifests/blackbox-probes.yaml` — no Helm
changes needed to add or remove services.

Two probe modules are configured:

| Module | Behaviour | Used for |
|---|---|---|
| `http_2xx_follow` | Follows redirects, expects final 2xx | Web UIs with login pages |
| `http_reachable` | No redirect follow, accepts 2xx/3xx/4xx/404 | API endpoints that return 401/403/404 |

Current targets:

**Web UIs** (`blackbox-web-uis` Probe):
- grafana, prometheus, alertmanager, gitlab, jupyter, longhorn-ui, mlflow, chat (Open WebUI), garage-ui, ollama-general

**API endpoints** (`blackbox-api-endpoints` Probe):
- garage (S3 API), polaris (Iceberg REST catalog)

### Adding a new target

Edit `manifests/blackbox-probes.yaml` and add the URL under the appropriate probe, then:

```bash
kubectl apply -f manifests/blackbox-probes.yaml
```

Use `http_2xx_follow` for web UIs and `http_reachable` for API endpoints that don't
return 2xx on unauthenticated requests.

### Alerting on service down

```yaml
# Example PrometheusRule
- alert: ServiceDown
  expr: probe_success == 0
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "{{ $labels.instance }} is down"
```
