# Get the latest cert manager manifest from here
https://cert-manager.io/docs/installation/

As of the writing of this doc I got
https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.yaml

# Copy to the manifests directory to install

`cp cert-manager.yaml /var/lib/rancher/k3s/server/manifests/`

# Fill in and copy over the cert manager issuer manifet

I am using cloudflare and lets encrypt. Generate an API key, and then fill in the issuer manifest
copy it over to the manifests directory.

`cp cert-manager-le-cf-issuer.yaml /var/lib/rancher/k3s/server/manifests/`

## Check if the secrets have been created

`kubectl get secret -n cert-manager`

## Check if cluster-issuer exists

`kubectl get clusterissuer`

We can also describe the cluter issuer resources

`kubectl describe clusterissuer letsencrypt-staging`
`kubectl describe clusterissuer letsencrypt-production`

