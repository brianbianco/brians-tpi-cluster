# Traefik Install and Upgrade Instructions

## Phase 1: Install Core Traefik

```bash
helm repo add traefik https://helm.traefik.io/traefik
helm repo update

helm upgrade --install traefik traefik/traefik -n kube-system --create-namespace -f values.yaml
```

## Phase 2: Apply CRD-Based Resources

Wait for Traefik pods to be ready and apply custom IngressRoute:

```bash
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=traefik -n kube-system --timeout=120s
kubectl apply -f traefik-dashboard.yaml
```

## Future Upgrades

1. Upgrade the core chart:
```bash
helm upgrade traefik traefik/traefik -n kube-system -f values.yaml
```

2. Reapply CRD-based resources:
```bash
kubectl apply -f traefik-dashboard.yaml
```
