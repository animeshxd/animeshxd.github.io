REPO=https://mirror.freedif.org/voidlinux/current
ARCH=x86_64

xbps-install -Su xbps

mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system

## configure time, etcs
xgenfstab -U /mnt > /mnt/etc/fstab

