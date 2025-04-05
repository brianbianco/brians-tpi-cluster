# Exposing traefik dashboard

This is left for refernce but the helm directory has a chart with values for setting up
the dashboard

Copy over the traefik manifest from the manifests directory to `/var/lib/rancher/k3s/server/manifests/`

If MetalLB is not yet setup, and there is not otherwise an external ip you should be able to connect to the dashboard
via node port.


This should show you the running service. See what port 9000 is forwarded to

```
kubectl get svc -n kube-system

kubectl get pods -n kube-system -o wide
```

You should see the service running, as well as the nodes IP. Simply go to

http://<node-address>:<dashboard-port>/dashboard
