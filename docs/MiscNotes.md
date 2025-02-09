## Installing the server

Last time I ran a cluster these were my startup options for k3s

```
ExecStart=/usr/local/bin/k3s \
          server \
          '--write-kubeconfig-mode' \
          '644' \
          '--disable' \
          'servicelb' \
          '--node-ip' \
          '192.168.4.170' \
          '--disable-cloud-controller' \
          '--kubelet-arg=allowed-unsafe-sysctls=net.ipv4.ip_forward'
```


--write-kubeconfig-mode 644: Sets the kubeconfig file permissions to 644.
--disable servicelb: Disables the built-in ServiceLB (Klipper Load Balancer).
--node-ip 192.168.4.170: Specifies the IP address for the node.
--disable-cloud-controller: Disables the cloud controller manager.
#--cluster-init: Initializes a new cluster with embedded etcd (required for HA setups). Not recommneded for wimpy nodes
--kubelet-arg=allowed-unsafe-sysctls=net.ipv4.ip_forward: Allows the net.ipv4.ip_forward sysctl.

I ran the install like so

`curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --disable servicelb --node-ip 192.168.4.170 --disable-cloud-controller --kubelet-arg=allowed-unsafe-sysctls=net.ipv4.ip_forward" sh -`


## Installing the Agents

curl -sfL https://get.k3s.io | K3S_URL=https://k3s.example.com K3S_TOKEN=mypassword sh -s
