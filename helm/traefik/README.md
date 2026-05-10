# Traefik Install and Upgrade Instructions

## Entrypoints

| Entrypoint | Internal port | External port | Purpose |
|---|---|---|---|
| web | 8000 | 80 | HTTP |
| websecure | 8443 | 443 | HTTPS |
| ssh | 2222 | 22 | GitLab SSH (TCP passthrough) |

The `ssh` entrypoint uses an internal port of 2222 because Traefik runs non-root and cannot
bind privileged ports directly. The MetalLB LoadBalancer maps external port 22 → 2222.
Routing is handled by `helm/gitlab/ssh-route.yaml` (an `IngressRouteTCP`).

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
