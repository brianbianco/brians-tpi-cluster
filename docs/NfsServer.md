# Install the NFS server

`sudo apt-get install -y nfs-kernel-server nfs-common`

# Create the share directory and set ownership

`sudo mkdir -p /mnt/data/share`

`sudo chown -R nobody:nogroup /mnt/data/share`

# fstab entry for the SSD used for the share

`blkid <device name>`

`UUID=f6fbbd3e-c7ce-4efc-873a-cf471348bc0c  /mnt/data  ext4  defaults,nofail  0  2`

# Setup your exports

```
/mnt/data/share 192.168.4.0/22(rw,sync,no_subtree_check,all_squash,insecure)
/mnt/data/share 127.0.0.1(rw,sync,no_subtree_check,all_squash,insecure)
/mnt/data/share 10.42.3.0/24(rw,sync,no_subtree_check,all_squash,insecure)
```

`exportfs -ra`

`sudo systemctl restart nfs-server nfs-mountd nfs-common`

