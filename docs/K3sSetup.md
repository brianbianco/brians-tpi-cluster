# Setup the controller

mkdir -p /etc/rancher/k3s/

Write the controller config

```
cat <<EOF > /etc/rancher/k3s/config.yaml
write-kubeconfig-mode: "0644"

disable:
  - servicelb
  - cloud-controller
  - traefik

node-ip: "192.168.4.183"

kubelet-arg:
  - "allowed-unsafe-sysctls=net.ipv4.ip_forward"

tls-san:
  - "192.168.4.183"
  - "k3s.brians.computer"
  - "magus.local.brians.computer"
  - "magus.local"

metrics-bind-address: "0.0.0.0"
node-label:
  - "hardware=rk1"
EOF
```

curl -sfL https://get.k3s.io | sh -

# Check the cluster status

`kubectl cluster-info`

`kubectl get nodes`

`kubectl get svc -A`

# Setup the worker agents

Get the server token from the leader

`cat /var/lib/rancher/k3s/server/token`
mkdir -p /etc/rancher/k3s/

```
cat <<EOF > /etc/rancher/k3s/config.yaml
server: https://192.168.4.183:6443
token: "YOUR_CLUSTER_TOKEN_HERE"
node-ip: "192.168.4.<THE_NODES_IP>"
data-dir: "/mnt/data/k3s"
kubelet-arg:
  - "allowed-unsafe-sysctls=net.ipv4.ip_forward"
node-label:
  - "hardware=cm4"
EOF
```

curl -sfL https://get.k3s.io | sh -s - agent

Add any labels like so

```
kubectl label node node-name node-role.kubernetes.io/worker=true
kubectl label node node-name my_key=my_val"
```

Copy over the `/etc/rancher/k3s/k3s.yaml` to the nodes `~/.kube/config` if you want kubectl to work

`scp /etc/rancher/k3s/k3s.yaml ubuntu@frog.local:.kube/config.yaml`

Make sure to edit the config and change the IP from 127.0.0.1 to the leaders IP

We should also link to the config on the controller server

```
mkdir -p ~/.kube
ln -s /etc/rancher/k3s/k3s.yaml ~/.kube/config
```

# Optionally change where the containerd images are stored

This would only be needed if you hadn't set the `data-dir` in the install config

`sudo systemctl stop k3s-agent`

`sudo mv /var/lib/rancher/k3s/agent/containerd /mnt/data/`
`sudo ln -s /mnt/data/containerd /var/lib/rancher/k3s/agent/containerd`
