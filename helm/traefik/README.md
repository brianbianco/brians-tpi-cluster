# Installing Traefik

```
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm install traefik traefik/traefik --namespace kube-system --create-namespace
```

# Install our custom configuration chart

`helm upgrade --install traefik-config . --namespace kube-system -f values.yaml`
