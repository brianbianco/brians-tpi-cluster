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

# Create SMTP password secret for Alertmanager email notifications
# Use a Gmail App Password (Google Account → Security → App Passwords)
kubectl create secret generic alertmanager-email-secret --from-literal=smtp-password='your-gmail-app-password' -n monitoring

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

## Alertmanager email notifications

Alertmanager is configured to send email to `brian.bianco@gmail.com` via Gmail SMTP.
The SMTP password is read from the `alertmanager-email-secret` secret (see Install above).

Watchdog alerts are silenced. All other alerts are grouped by `alertname` + `namespace`
and delivered with a 4-hour repeat interval for ongoing issues.

## Grafana dashboards

The following dashboards are pre-loaded at startup:

| Dashboard | Grafana ID | What it shows |
|---|---|---|
| Blackbox Exporter | 7587 | HTTP uptime for all cluster endpoints |
| Node Exporter Full | 1860 | Per-node CPU, memory, disk, network, temperature |
| Longhorn | 16888 | Volume health, replica sync, disk usage |
| Traefik | 17347 | Request rates, error rates, latency per route |
| PostgreSQL | 9628 | Connections, queries, replication (CNPG metrics) |

For an Ollama-specific dashboard, search https://grafana.com/grafana/dashboards for "Ollama".
For a CNPG-tailored PostgreSQL dashboard, search for "CloudNativePG".

## Grafana plugins

The **Infinity datasource** (`yesoreyeram-infinity-datasource`) is installed at startup.
It lets you query any JSON/REST/CSV endpoint as a Grafana datasource — useful for the
Garage admin API, Polaris REST catalog, or any service without a native Prometheus exporter.

## Loki log aggregation

The Grafana datasource for Loki is pre-configured in `values.yaml` and will become active
once Loki is deployed. See `helm/loki/README.md` for install instructions.

## Service monitors

The following ServiceMonitors / PodMonitors are configured:

| Service | How |
|---|---|
| Traefik | `templates/servicemonitor-traefik.yaml` (PodMonitor) |
| cert-manager | `templates/servicemonitor-cert-manager.yaml` |
| Longhorn | `manifests/servicemonitor-longhorn.yaml` |
| Ollama (all instances) | `manifests/servicemonitor-ollama.yaml` |
| Garage (S3) | Enabled via `helm/garage/values.yaml` |
| PostgreSQL (CNPG) | Enabled via `helm/postgres/cluster.yaml` `monitoring.enablePodMonitor` |

## Service Health Monitoring (Blackbox Exporter)

The `prometheus-blackbox-exporter` subchart probes all cluster ingress endpoints every 60s
over HTTPS. Results are available as the `probe_success` metric (1 = up, 0 = down).

Targets are defined as `Probe` CRDs in `manifests/blackbox-probes.yaml` — no Helm changes
needed to add or remove services.

Two probe modules are configured:

| Module | Behaviour | Used for |
|---|---|---|
| `http_2xx_follow` | Follows redirects, expects final 2xx | Web UIs with login pages |
| `http_reachable` | No redirect follow, accepts 2xx/3xx/4xx | API endpoints that return 401/403 |

### Adding a new probe target

Edit `manifests/blackbox-probes.yaml` and add the URL, then:

```bash
kubectl apply -f manifests/blackbox-probes.yaml
```
