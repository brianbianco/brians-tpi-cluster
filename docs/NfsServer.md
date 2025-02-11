# Install the NFS server

`sudo apt-get install -y nfs-kernel-server nfs-common`

# fstab entry for the SSD used for the share

`blkid <device name>`

`UUID=f6fbbd3e-c7ce-4efc-873a-cf471348bc0c  /mnt/tcssd  ext4  defaults,nofail  0  2`

# Setup your exports (example in config directory)

`exportfs -ra`

`sudo systemctl restart nfs-server nfs-mountd nfs-common`
