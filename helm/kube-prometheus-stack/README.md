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
