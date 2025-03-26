# Create the credentials file secret

```
kubectl create namespace cloudflared
kubectl create secret generic cloudflare-tunnel-credentials --from-literal=credentials.json='{"AccountTag":"SAMPLE","TunnelID":"SAMPLE","TunnelSecret":"SAMPLE","Endpoint":""}' --namespace cloudflared
```


# Add the helm repo

```
helm repo add cloudflare https://cloudflare.github.io/helm-charts
helm repo update
```


# Install the chart

```
helm upgrade --install cloudflared cloudflare/cloudflare-tunnel --namespace cloudflared -f values.yaml
```

