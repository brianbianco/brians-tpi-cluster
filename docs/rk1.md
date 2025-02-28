# tpi usb -n 4 flash
# tpi power -n 4 on
# tpi flash --local --image-path /mnt/sdcard/ubuntu-24.04-preinstalled-server-arm64-turing-rk1.img --node 4

# set the node back to non flash mode (forgot command, find it and put it here)

# tpi usb -n 4 device
# tpi power -n 4 off
# tpi power -n 4 on

# Connect to rk1 via picom
# picocom /dev/ttyS4 -b 115200
# Setup ubuntu users password (defaults to ubuntu) and add ssh pubkey to authorized keys


# Make sure to change to ondemand if running server only?
# /usr/lib/systemd/system/cpu-governor.service

# Install to NVMe drive if desired
# sudo ubuntu-rockchip-install /dev/nvme0n1

