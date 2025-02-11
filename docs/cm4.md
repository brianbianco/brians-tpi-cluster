# Flashing the cm4 modules

`tpi flash --local --image-path /mnt/sdcard/ubuntu-24.04.1-preinstalled-server-arm64+raspi.img --node 1`

# SSH to the node

`ssh ubuntu@<ip-addr>`

Modify `/etc/netplan/50-cloud-init.yaml`

add ssh key to `/home/ubuntu/.ssh/authorized_keys`
