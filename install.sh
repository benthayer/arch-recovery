#!/bin/bash
# Arch Linux Recovery Install Script
# Usage: ./install.sh /dev/nvme0n1 /dev/nvme0n1p1 /dev/nvme0n1p2
#                     disk         boot-part       root-part

set -e

DISK=$1
BOOT=$2
ROOT=$3

if [[ -z "$DISK" || -z "$BOOT" || -z "$ROOT" ]]; then
  echo "Usage: $0 <disk> <boot-partition> <root-partition>"
  echo "Example: $0 /dev/nvme0n1 /dev/nvme0n1p1 /dev/nvme0n1p2"
  exit 1
fi

echo "Installing to: $DISK (boot: $BOOT, root: $ROOT)"
echo "This will FORMAT these partitions. Press Enter to continue or Ctrl+C to abort."
read -r

# Format
mkfs.fat -F32 "$BOOT"
mkfs.ext4 -F "$ROOT"

# Mount
mount "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$BOOT" /mnt/boot

# Pacstrap
pacstrap /mnt base linux linux-firmware amd-ucode intel-ucode \
  networkmanager i3 xorg-server xorg-xinit sddm zsh git firefox terminator

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
cp /usr/lib/locale/locale-archive /mnt/usr/lib/locale/

# Timezone + hostname
ln -sf /usr/share/zoneinfo/America/New_York /mnt/etc/localtime
echo "arch" > /mnt/etc/hostname

# User
useradd -R /mnt -m -G wheel -s /bin/zsh ben
echo "ben:changeme" | chpasswd -R /mnt
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /mnt/etc/sudoers

# Services
systemctl --root=/mnt enable NetworkManager sddm

# Boot
mkdir -p /mnt/boot/EFI/BOOT /mnt/boot/loader/entries
cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /mnt/boot/EFI/BOOT/BOOTX64.EFI

cat > /mnt/boot/loader/loader.conf << EOF
default arch.conf
timeout 3
EOF

cat > /mnt/boot/loader/entries/arch.conf << EOF
title Arch Linux
linux /vmlinuz-linux
initrd /amd-ucode.img
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=$ROOT rw
EOF

# The bastard
arch-chroot /mnt mkinitcpio -P

# Done
umount -R /mnt
echo ""
echo "=========================================="
echo "Done. Base system installed."
echo "Reboot and login as 'ben' with password 'changeme'"
echo "Personal config (dotfiles, SSH keys) not included."
echo "=========================================="

