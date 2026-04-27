REPO=https://mirror.freedif.org/voidlinux/current
ARCH=x86_64

xbps-install -Su xbps

mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

readonly BASE_SYSTEM=(
  linux linux-firmware linux-firmware-amd wifi-firmware systemd-boot kmod
  base-files glibc-locales tzdata iana-etc runit-void eudev acpid kbd libgcc
  xbps removed-packages
  bash dash bash-completion nvi vim
  shadow sudo
  coreutils findutils grep gzip sed gawk less which file procps-ng util-linux usbutils
  e2fsprogs dosfstools
  iproute2 iputils dhcpcd iwd openssh ntpd traceroute
  man-pages mdocml
)

XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" "${BASE_SYSTEM[@]}"

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


