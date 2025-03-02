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
