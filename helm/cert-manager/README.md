# Install cert-manager

```
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.17.1 --set crds.enabled=true --wait
```

# Install our cert-manager config

```
helm upgrade --install cert-manager-config . --namespace cert-manager --set cloudflare.apiToken="<API_TOKEN>" --wait
```

# Make sure things look good

```
kubectl get clusterissuers
kubectl describe clusterissuer letsencrypt-prod
kubectl describe clusterissuer letsencrypt-staging
```
