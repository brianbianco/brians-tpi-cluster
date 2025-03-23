# Helm

Update the dep charts with the following

`helm dependency update`

# Install one of the wrapper charts

`helm upgrade --install traefik ./traefik --namespace kube-system --create-namespace -f ./traefik/values.yaml`

# Often reviewing the values of a chart helps for debugging

E.G.

```
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm show values traefik/traefik --version 34.4.1
```
