# Partitioning my 3 512GB SSDs

# Create a GPT partition table

`sudo parted /dev/sda mklabel gpt`

# Create the first partition (189GB) and check alignment

`sudo parted /dev/sda mkpart primary 1049kB 189GB`

`sudo parted /dev/sda align-check optimal 1`

# Create the second partition (323GB) and check alignment

`sudo parted /dev/sda mkpart primary 189GB 512GB`

`sudo parted /dev/sda align-check optimal 2`

# Print the partition table to verify

`sudo parted /dev/sda print`

# Make the first partition ext4

`sudo mkfs -t ext4 /dev/sda1`

# Get blkid of parition

`sudo blkid /dev/sda1`

# Create /etc/fstab entry (example)

`UUID=37204e82-312d-49e1-8679-b54329a12892  /mnt/data  ext4  defaults,nofail  0  2`

