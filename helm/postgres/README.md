# PostgreSQL (CloudNativePG)

Deploys a single-instance PostgreSQL server.

## Install Instructions

```
# Create namespace
kubectl create namespace postgres

# Create Postgres credentials secret
kubectl create secret generic app-user -n postgres --type=kubernetes.io/basic-auth --from-literal=username=app --from-literal=password='the-password'

# Add Helm repo and install chart
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

helm install postgres cnpg/cloudnative-pg -n postgres

# Create the cluster
kubectl apply -f cluster.yaml

# Optionally create the load balancer (for external DNS auto entries)
kubectl apply -f service.yaml
```

## Monitoring

`cluster.yaml` has `monitoring.enablePodMonitor: true`. The CNPG operator automatically
creates a PodMonitor and attaches a metrics exporter sidecar to each Postgres pod —
no separate exporter deployment needed. Metrics are scraped by Prometheus and visible
in the PostgreSQL dashboard (ID 9628) pre-loaded in Grafana. For a CNPG-specific
dashboard, search https://grafana.com/grafana/dashboards for "CloudNativePG".

# Creating new users / databases

```
kubectl exec -n postgres -it postgres-0 -- psql -U postgres

CREATE USER myuser WITH PASSWORD 'mypassword';
CREATE DATABASE mydb OWNER myuser;
```
