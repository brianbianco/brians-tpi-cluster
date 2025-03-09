# Overview

Longhorn will be a distributed file system for our k3s cluster.

# Necessary packages

`sudo apt-get install -y open-iscsi nfs-common`

# bind mount data dirs

Since we are using a specific device for long horn, instead of altering the default data path
we will simply bind mount our device to the default

Adding this to the `/etc/fstab` should work

`mkdir -p /var/lib/longhorn`

`/mnt/longhorn /var/lib/longhorn none bind,nofail 0 0`

`sudo systemctl daemon-reload`

`sudo mount -a`

# Install

https://longhorn.io/docs/1.8.0/deploy/install/install-with-kubectl/

Download the latest yaml

wget https://raw.githubusercontent.com/longhorn/longhorn/v1.8.0/deploy/longhorn.yaml

Locate the frontend section and change `ClusterIP` to `LoadBalancer` if you want MetalLB to give it an external IP

`kubeclt apply -f longhorn.yaml`

# Setting up ingress with ssl

This is the configuration I used to have the frontend service use cert-manager and external-dns

```
---
# Source: longhorn/templates/deployment-ui.yaml
apiVersion: v1
kind: Service
metadata:
  name: longhorn-frontend
  namespace: longhorn-system
  labels:
    app: longhorn-ui
    app.kubernetes.io/instance: longhorn
    app.kubernetes.io/name: longhorn
    app.kubernetes.io/version: v1.8.0
spec:
  type: ClusterIP
  ports:
    - name: http
      port: 80
      targetPort: http
  selector:
    app: longhorn-ui
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn-ingress
  namespace: longhorn-system
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    external-dns.alpha.kubernetes.io/hostname: longhorn-ui.brians.computer
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  rules:
    - host: longhorn-ui.brians.computer
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: longhorn-frontend
                port:
                  number: 80
  tls:
    - hosts:
        - longhorn-ui.brians.computer
      secretName: longhorn-ui-tls
---
```

