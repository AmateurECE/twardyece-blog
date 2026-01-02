```
# When /etc/exports says:
/export		192.168.2.0/22(ro,fsid=0,no_subtree_check,sync)
/export/rootfs	192.168.2.0/22(ro,fsid=1,nohide,insecure,no_subtree_check,crossmnt,sync,no_root_squash)

# To mount it
ratarmount -o allow_root build/tmp-glibc/deploy/images/rpi-netboot-gadget/stereo-gadget-image-netboot-rpi-netboot-gadget.rootfs.tar.gz /export/rootfs

# To unmount it
fusermount -u /export/rootfs

# To mount it on the client
sudo mount -t nfs4 -o ro 192.168.2.60:/rootfs /mnt/Mount/
```
