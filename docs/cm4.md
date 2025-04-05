# Flashing the cm4 modules

`tpi flash --local --image-path /mnt/sdcard/ubuntu-24.04.1-preinstalled-server-arm64+raspi.img --node 1`

# Add pub key to authorized keys

```
tpi advanced msd --node 1

mkdir -p /mnt/node<num>

mount /dev/sda2 /mnt/node1/

cat /root/.ssh/authorized_keys >> /mnt/node1/home/ubuntu/.ssh/authorized_keys

umount /mnt/node1

tpi power off -n 1

tpi power on -n 1

ssh ubuntu@<node_ip>

sudo hostnamectl set-hostname <new_host_name>.local
```

Nuke password if you dont want it set

```
sudo passwd -d $(whoami)
```

Modify `/etc/netplan/50-cloud-init.yaml`

# Install nfs common

```
sudo apt-get install nfs-common
```

# Add fstab entry if using NFS

```
robo.local:/mnt/tcssd/nfs  /mnt/nfs  nfs4  rw,sync,auto,nofail,x-systemd.automount  0  0
```

# Install avahi for mDNS discovery

```
sudo apt-get update
sudo apt-get install -y avahi-daemon avahi-discover avahi-utils libnss-mdns mdns-scan
```

# Install docker

```
sudo apt-get install -y docker.io
```

# Install nfs server if we are going to share

```
sudo apt-get install -y nfs-kernel-server
```

# Set vim as the default editor

```
sudo update-alternatives --set editor /usr/bin/vim.basic
```


