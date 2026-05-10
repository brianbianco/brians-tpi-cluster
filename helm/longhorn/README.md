# Installing longhorn


```
helm dependency build
helm upgrade --install longhorn-install . --namespace longhorn-system --create-namespace --wait
```

## Monitoring

A ServiceMonitor is defined in `manifests/servicemonitor-longhorn.yaml`. It scrapes the
Longhorn manager metrics endpoint (port 9500) and feeds into the Longhorn Grafana dashboard
(ID 16888) that is pre-loaded in kube-prometheus-stack.

# Upgrading

Longhorn must be upgraded one minor version at a time (e.g. 1.9 → 1.10 → 1.11).
For each step:

1. Update the version in `Chart.yaml` and `helm dependency update`
2. `helm upgrade --install longhorn-install . --namespace longhorn-system --wait`
3. Once the manager is running, go to the Longhorn UI → select all volumes → **Operations → Upgrade Engine**
4. Confirm all engine images show refcount 0 for the old version before moving to the next step

# disabling local-path as default storage class

To disable local-path as the default storage class to avoid ambiguity if a storage class isn't defined

```
kubectl annotate storageclass local-path storageclass.kubernetes.io/is-default-class-
```
