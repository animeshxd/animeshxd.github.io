set -e

cat > pkglist <<EOF
alacritty
amd-ucode
ark
base
base-devel
bash-completion
bluedevil
bluez
bluez-utils
breeze-gtk
bridge-utils
catimg
cdrtools
clang
cmake
cups
dnsmasq
docker
docker-compose
dolphin
dotnet-sdk
firefox
flatpak
gimp
git
gperf
hplip
htop
iptables-nft
iwd
jdk-openjdk
jdk8-openjdk
lib32-libva-mesa-driver
lib32-mesa
lib32-mesa-vdpau
lib32-vulkan-radeon
libreoffice-fresh
libva-mesa-driver
libvirt
libxcrypt-compat
linux
linux-firmware
linux-headers
lsb-release
man-db
mesa-vdpau
neovim
networkmanager
ninja
nodejs
noto-fonts-cjk
noto-fonts-emoji
npm
obs-studio
openbsd-netcat
openjdk-src
openssh
p7zip
php
pipewire
pipewire-pulse
python-pip
python-pipx
qemu-base
reflector
rsync
sudo
telegram-desktop
tree
unrar
unzip
usbutils
v4l2loopback-dkms
vde2
vim
virt-manager
virt-viewer
vulkan-radeon
wayland-protocols
wayvnc
wget
xf86-video-amdgpu
yarn
zip
dnsmasq
bridge-utils
libguestfs
pipewire-jack
qt6-multimedia-ffmpeg
noto-fonts
plasma-desktop
plasma-nm
plasma-pa
plasma-systemmonitor
plasma-wayland-protocols
kde-gtk-config
kdeplasma-addons
kate
kcalc
krfb
kwallet-pam
kwalletmanager
discover
spectacle
xdg-desktop-portal-kde
EOF

cat > pkglist.aur <<EOF
paru-bin
rtl8821au-dkms-git
visual-studio-code-bin
EOF

ping -c 3 archlinux.org

cat > arch.conf <<EOF
title   Arch Linux
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
pacstrap -K $MOUNT base linux linux-firmware linux-headers vim sudo amd-ucode
genfstab -U $MOUNT >> $MOUNT/etc/fstab

cp pkglist $MOUNT/root/pkglist
cp pkglist.aur $MOUNT/root/pkglist.aur

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
locale-gen
pacman -Syu --noconfirm
pacman -S --needed - < /root/pkglist

useradd -m -G wheel user
echo "user:user" | chpasswd
echo "root:root" | chpasswd

systemctl enable NetworkManager
EOF
