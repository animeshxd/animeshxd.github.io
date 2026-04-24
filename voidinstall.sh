REPO=https://mirror.freedif.org/voidlinux/current
ARCH=x86_64

xbps-install -Su xbps

mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system

# TODO: configure time, language, etcs
xgenfstab -U /mnt > /mnt/etc/fstab

#TODO:  configure Hardware clock localtime, install ntpd

#TODO: install systemd-boot, vim, openssh, 

#TODO: tigger linux post-install hook for systemd-boot (xbps-reconfigure -f linux6.12)

ln -s /mnt/etc/sv/dhcpcd /mnt/var/service/
ln -s /mnt/etc/sv/sshd /mnt/var/service/

#TODO: start ntpd

#TODO: change password of root

#### MIGRATE TO NIRI ####


