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
