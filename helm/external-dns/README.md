# Install our custom external-dns chart

```
helm dependency build
helm upgrade --install external-dns-install . --namespace external-dns --create-namespace --set cloudflare.apiToken="YOUR_CLOUDFLARE_TOKEN" --wait
```
