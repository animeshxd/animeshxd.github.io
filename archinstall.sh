#!/usr/bin/env bash
set -e

readonly MOUNT_DIR="/mnt"
readonly TARGET_HOSTNAME="arch"
readonly TARGET_TIMEZONE="Asia/Kolkata"

# PARTTYPE
readonly GUID_EFI="c12a7328-f81f-11d2-ba4b-00a0c93ec93b" # EFI System
readonly GUID_XBOOTLDR="bc13c2ff-59e6-4262-a352-b275fd6f7172" # Linux extended boot
readonly GUID_ROOT="4f68bce3-e8cd-4db1-96e7-fbcaf984b709" # Linux root (x86-64)


readonly BASE_PACKAGES=(
  base
  linux
  linux-headers
  linux-firmware-amdgpu
  linux-firmware-realtek
  amd-ucode
  sudo
  vim
  bash-completion
  iwd
)

readonly OTHER_PACKAGES=(
  mesa xf86-video-amdgpu vulkan-radeon
  firefox alacritty git htop neovim openssh reflector rsync openbsd-netcat
  7zip tree unrar zip unzip usbutils wget lsb-release man-db
  pipewire pipewire-pulse pipewire-jack
  base-devel cmake clang ninja gdb nodejs npm python-pip python-pipx 
  bluez bluez-utils bluedevil
  hplip cups
  libvirt virt-manager virt-viewer qemu-base docker docker-compose docker-buildx
  noto-fonts noto-fonts-cjk noto-fonts-emoji
  
  thunar tumbler hyprland awww
  waybar dunst wofi wl-clipboard grim slurp playerctl pavucontrol
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk gnome-keyring
  polkit-gnome dart-sass

  # wayland-protocols
  # qt6-multimedia-ffmpeg
  # plasma-desktop
  # plasma-nm
  # plasma-pa
  # plasma-systemmonitor
  # plasma-wayland-protocols
  # kde-gtk-config
  # kdeplasma-addons
  # breeze-gtk
  # ark
  # dolphin
  # kwallet-pam
  # kwalletmanager
  # discover
  # spectacle
  # xdg-desktop-portal-kde
)

readonly AUR_PACKAGES=(
  paru-bin
  visual-studio-code-bin
)

validate_partition_type() {
  local mount_point="$1"
  local expected_guid="${2,,}"
  local type_label="$3"
  local device
  local actual_guid

  device=$(findmnt -n -o SOURCE --target "$mount_point")
  
  if [[ -z "$device" ]]; then
    echo "Error: Could not resolve block device for $mount_point"
    exit 1
  fi

  actual_guid=$(lsblk -no PARTTYPE "$device" | tr '[:upper:]' '[:lower:]')

  if [[ "$actual_guid" != "$expected_guid" ]]; then
    echo "Error: $device ($mount_point) does not match the expected type: $type_label"
    echo "Expected: $expected_guid"
    echo "Found:    ${actual_guid:-None}"
    exit 1
  fi
}

check_prerequisites() {
  if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root."
    exit 1
  fi

  if [[ ! -d /sys/firmware/efi/efivars ]]; then
    echo "Error: System is not booted in UEFI mode."
    exit 1
  fi
  echo "Checking Internet Connection".
  if ! ping -c 1 archlinux.org &> /dev/null; then
    echo "Error: No internet connection."
    exit 1
  fi

  for target in "$MOUNT_DIR" "$MOUNT_DIR/boot" "$MOUNT_DIR/efi"; do
    if ! mountpoint -q "$target"; then
      echo "Error: $target is not mounted."
      exit 1
    fi
  done

  validate_partition_type "$MOUNT_DIR/efi" "$GUID_EFI" "EFI System"
  validate_partition_type "$MOUNT_DIR" "$GUID_ROOT" "Linux root (x86-64)"
  validate_partition_type "$MOUNT_DIR/boot" "$GUID_XBOOTLDR" "Linux extended boot"
}

configure_mirrors() {
  reflector -c India --threads 50 --sort age --sort rate --sort score --sort delay \
    --download-timeout 3 --connection-timeout 3 --save /etc/pacman.d/mirrorlist
}

install_base_system() {
  pacman -Sy --needed --noconfirm archlinux-keyring
  pacman-key --init
  pacman-key --populate archlinux
  pacstrap -K "$MOUNT_DIR" "${BASE_PACKAGES[@]}"
  genfstab -U "$MOUNT_DIR" >> "$MOUNT_DIR/etc/fstab"
}

configure_system_files() {
  cp /etc/pacman.d/mirrorlist "$MOUNT_DIR/etc/pacman.d/mirrorlist"
  
  printf "%s\n" "${OTHER_PACKAGES[@]}" > "$MOUNT_DIR/root/pkglist"
  printf "%s\n" "${AUR_PACKAGES[@]}" > "$MOUNT_DIR/root/pkglist.aur"

  sed -i 's/#en_US.UTF-8/en_US.UTF-8/' "$MOUNT_DIR/etc/locale.gen"
  echo "LANG=en_US.UTF-8" > "$MOUNT_DIR/etc/locale.conf"
  echo "$TARGET_HOSTNAME" > "$MOUNT_DIR/etc/hostname"

  cat > "$MOUNT_DIR/etc/hosts" <<EOF
127.0.0.1    localhost
::1          localhost
EOF

  sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' "$MOUNT_DIR/etc/sudoers"
  sed -i 's/#Color/Color/' "$MOUNT_DIR/etc/pacman.conf"
  # sed -z 's/#\[multilib\]\n#Include/\[multilib\]\nInclude/g' -i "$MOUNT_DIR/etc/pacman.conf"

  cat > "$MOUNT_DIR/etc/resolv.conf" <<EOF
# Resolver configuration file.
# See resolv.conf(5) for details.
nameserver 1.1.1.3
nameserver 1.0.0.3
EOF
}

configure_bootloader() {
  local root_dev
  local root_uuid
  
  root_dev=$(findmnt -n -o SOURCE --target "$MOUNT_DIR")
  root_uuid=$(blkid -s UUID -o value "$root_dev")

  if [[ -z "$root_dev" ]]; then
    echo "Error: Could not determine root device."
    exit 1
  fi

  mkdir -p "$MOUNT_DIR/boot/loader/entries/"
  cat > "$MOUNT_DIR/boot/loader/entries/arch.conf" <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$root_uuid rw
EOF
}

configure_networking() {
  mkdir -p "$MOUNT_DIR/etc/systemd/network/"
  
  cat > "$MOUNT_DIR/etc/systemd/network/10-wired.network" <<EOF
[Match]
Name=en*

[Link]
RequiredForOnline=routable

[Network]
DHCP=yes
EOF

  cat > "$MOUNT_DIR/etc/systemd/network/20-wifi.network" <<EOF
[Match]
Name=wl*

[Link]
RequiredForOnline=routable

[Network]
Policy=down
DHCP=yes
IgnoreCarrierLoss=3s
EOF
}

execute_chroot_operations() {
  arch-chroot "$MOUNT_DIR" /bin/bash - <<EOF
ln -sf /usr/share/zoneinfo/$TARGET_TIMEZONE /etc/localtime
hwclock --hctosys --localtime
locale-gen

# Sync and install secondary packages
pacman -Syu --noconfirm
pacman -S --needed --noconfirm - < /root/pkglist

# Setup user
useradd -m -G wheel user
echo "user:user" | chpasswd
echo "root:root" | chpasswd

# Enable essential services
systemctl enable systemd-networkd
systemctl enable iwd
EOF
}



main() {
  check_prerequisites
  configure_mirrors
  install_base_system
  configure_system_files
  configure_bootloader
  configure_networking
  execute_chroot_operations
  
  echo "Base installation complete."
}

main "$@"
