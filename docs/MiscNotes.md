Last good known k3s start

ExecStart=/usr/local/bin/k3s \
          server \
          '--write-kubeconfig-mode' \
          '644' \
          '--disable' \
          'servicelb' \
          '--node-ip' \
          '192.168.4.170' \
          '--disable-cloud-controller' \
          '--cluster-init' \
          '--kubelet-arg=allowed-unsafe-sysctls=net.ipv4.ip_forward'
