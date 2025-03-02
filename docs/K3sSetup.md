# First create the config directory

mkdir -p /etc/rancher/k3s/

# Write our desired starting config

```
cat <<EOF > /etc/rancher/k3s/config.yaml
write-kubeconfig-mode: "0644"
disable:
  - servicelb
  - cloud-controller
node-ip: "192.168.4.184"
kubelet-arg:
  - "allowed-unsafe-sysctls=net.ipv4.ip_forward"
#tls-san:
#  - "magus.local.brians.computer"
EOF
```

# Run the installer for the leader

curl -sfL https://get.k3s.io | sh -

# Check the cluster status

`kubectl cluster-info`

`kubectl get nodes`

`kubectl get svc -A`

# Setup the worker agents

Get the server token from the leader

`cat /var/lib/rancher/k3s/server/token`

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.4.184:6443 K3S_TOKEN=<server_token> sh -s

Label the node

`kubectl label nodes node-name node-role.kubernetes.io/worker=true`

Copy over the `/etc/rancher/k3s/k3s.yaml` to the nodes `~/.kube/config` if you want kubectl to work

`scp /etc/rancher/k3s/k3s.yaml ubuntu@frog.local:.kube/config.yaml`

Make sure to edit the config and change the IP from 127.0.0.1 to the leaders IP

# Optionally change where the containerd images are stored

There is likely a way to handle this before the agent install, for now i've settled for moving it
after the fact if i want the containerd files to be on a different device

`sudo systemctl stop k3s-agent`

`sudo cp -r /var/lib/rancher/k3s/agent/containerd /mnt/data/containerd`

`sudo ln -s /mnt/data/containerd /var/lib/rancher/k3s/agent/containerd`
