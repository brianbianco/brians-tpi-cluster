# Overview

ExternalDNS is useful for allowing us to easily manage DNS records for our ingresses.
I will be using cloudflare for all of this

# Setup

As of the writing of the doc, this was the docs page.
https://kubernetes-sigs.github.io/external-dns/latest/

Specifically for cloudflare
https://kubernetes-sigs.github.io/external-dns/latest/docs/tutorials/cloudflare/

Fill out the manifest I provide in the manifests directory. This puts the cloudflare API keys into the kube-system

Remember that the api token for cloudflare must be base64 encoded. If you used echo to send it to base64 make sure to use the -n flag!

`echo -n 'MYTOKEN' | base64
