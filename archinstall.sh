set -e


BASE_PACKAGES=(
  base
  linux
  linux-headers
  linux-firmware
  linux-lts-headers
  linux-lts
  amd-ucode
  sudo
  vim
  bash-completion
  networkmanager
  iwd
)


OTHER_PACKAGES=(
  mesa
  lib32-mesa
  xf86-video-amdgpu
  vulkan-radeon
  lib32-vulkan-radeon

  firefox
  alacritty

  git
  htop
  neovim
  openssh
  reflector
  rsync
  openbsd-netcat
  p7zip
  tree
  unrar
  zip
  unzip
  usbutils
  wget
  lsb-release
  man-db

  pipewire
  pipewire-pulse
  pipewire-jack

  base-devel
  cmake
  clang
  ninja

  dotnet-sdk
  openjdk-src
  jdk-openjdk
  jdk8-openjdk
  nodejs
  npm
  yarn
  php
  python-pip
  python-pipx

  bluez
  bluez-utils
  bluedevil

  gimp
  flatpak
  obs-studio
  v4l2loopback-dkms
  telegram-desktop
  libreoffice-fresh
  
  catimg
  cdrtools
  
  hplip
  cups
  
  iptables-nft
  bridge-utils
  dnsmasq
  vde2
  libguestfs
  libvirt
  virt-manager
  virt-viewer
  qemu-base

  docker
  docker-compose

  gperf
  libxcrypt-compat
  
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji

  wayland-protocols
  wayvnc
  qt6-multimedia-ffmpeg
  plasma-desktop
  plasma-nm
  plasma-pa
  plasma-systemmonitor
  plasma-wayland-protocols
  kde-gtk-config
  kdeplasma-addons
  breeze-gtk
  ark
  dolphin
  kate
  kcalc
  krfb
  kwallet-pam
  kwalletmanager
  discover
  spectacle
  xdg-desktop-portal-kde
)

AUR_PACKAGES=(
  paru-bin
  rtl8821au-dkms-git
  visual-studio-code-bin
)


ping -c 3 archlinux.org

cat > arch.conf <<EOF
title   Arch Linux LTS
linux   /vmlinuz-linux-lts
initrd  /initramfs-linux-lts.img
initrd 	/amd-ucode.img
options root=/dev/nvme0n1p6 rw
EOF

cat > /etc/pacman.d/mirrorlist <<EOF
##

## India
#Server = http://mirror.4v1.in/archlinux/\$repo/os/\$arch
#Server = https://mirror.4v1.in/archlinux/\$repo/os/\$arch
#Server = https://mirrors.abhy.me/archlinux/\$repo/os/\$arch
#Server = http://mirror.albony.in/archlinux/\$repo/os/\$arch
#Server = http://in.mirrors.cicku.me/archlinux/\$repo/os/\$arch
#Server = https://in.mirrors.cicku.me/archlinux/\$repo/os/\$arch
#Server = http://mirror.cse.iitk.ac.in/archlinux/\$repo/os/\$arch
#Server = http://in-mirror.garudalinux.org/archlinux/\$repo/os/\$arch
#Server = https://in-mirror.garudalinux.org/archlinux/\$repo/os/\$arch
#Server = http://archlinux.mirror.net.in/archlinux/\$repo/os/\$arch
#Server = https://archlinux.mirror.net.in/archlinux/\$repo/os/\$arch
#Server = http://mirrors.nxtgen.com/archlinux-mirror/\$repo/os/\$arch
#Server = https://mirrors.nxtgen.com/archlinux-mirror/\$repo/os/\$arch
#Server = http://mirrors.piconets.webwerks.in/archlinux-mirror/\$repo/os/\$arch
#Server = https://mirrors.piconets.webwerks.in/archlinux-mirror/\$repo/os/\$arch
Server = http://mirror.sahil.world/archlinux/\$repo/os/\$arch
Server = https://mirror.sahil.world/archlinux/\$repo/os/\$arch
EOF

MOUNT=/mnt
HOSTNAME=arch

pacman-key --init
pacman-key --populate archlinux
pacstrap -K $MOUNT ${BASE_PACKAGES[@]}
genfstab -U $MOUNT >> $MOUNT/etc/fstab

printf "%s\n" "${OTHER_PACKAGES[@]}" > $MOUNT/root/pkglist
printf "%s\n" "${AUR_PACKAGES[@]}" > $MOUNT/root/pkglist.aur

cp /etc/pacman.d/mirrorlist $MOUNT/etc/pacman.d/mirrorlist

sed -i 's/#en_US.UTF-8/en_US.UTF-8/' $MOUNT/etc/locale.gen
echo LANG=en_US.UTF-8 > $MOUNT/etc/locale.conf

echo $HOSTNAME > $MOUNT/etc/hostname

cat > $MOUNT/etc/hosts <<EOF
# Static table lookup for hostnames.
# See hosts(5) for details.
#
127.0.0.1	localhost
::1		localhost
EOF

sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' $MOUNT/etc/sudoers

sed -i 's/#Color/Color/' $MOUNT/etc/pacman.conf
sed -z 's/#\[multilib\]\n#Include/\[multilib\]\nInclude/g' -i $MOUNT/etc/pacman.conf

mkdir -p $MOUNT/etc/NetworkManager/conf.d/
cat > $MOUNT/etc/NetworkManager/conf.d/wifi_backend.conf <<EOF
[device]
wifi.backend=iwd
EOF

arch-chroot $MOUNT /bin/bash - <<EOF
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
timedatectl set-local-rtc 1
locale-gen
pacman -Syu --noconfirm
pacman -S --needed - < /root/pkglist

useradd -m -G wheel user
echo "user:user" | chpasswd
echo "root:root" | chpasswd

systemctl enable NetworkManager
EOF
