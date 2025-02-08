## Directories copied

/etc/rancher
/var/lib/rancher
/etc/systemd/system/k3s.service

## Commands run

curl -sfL https://get.k3s.io | sh -
systemctl stop k3s
k3s server --cluster-reset --cluster-reset-restore-path=/var/lib/rancher/k3s/server/db/snapshots/etcd-snapshot-<snapshot-id-I-wanted>
systemctl start k3s

## Post migration

Modified .kube/config to change host on workers
