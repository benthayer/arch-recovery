# arch-recovery

Disaster recovery script for Arch Linux. Boot from any Arch ISO, run this script, get a working system.

## Intent

"So you want to be the captain?"

This is a bare-metal recovery system. If your laptop dies, gets stolen, or you just want to nuke and start fresh:

1. Boot any Arch ISO (USB, netboot, whatever)
2. Connect to WiFi
3. Run this script
4. Reboot into a working i3 desktop

## What it does

- Formats boot (FAT32) and root (ext4) partitions
- Installs base system + i3 + sddm + essential packages
- Creates user `ben` with password `changeme`
- Sets up systemd-boot
- Enables NetworkManager and sddm

## What it doesn't do (yet)

- Personal config (dotfiles, SSH keys, API keys)
- Auto-detect disks/partitions
- Handle dual-boot scenarios
- Matrix screen animations

## Usage

```bash
# Boot Arch ISO, connect to WiFi
iwctl station wlan0 connect "YourWiFi"

# Get the script
curl -O https://raw.githubusercontent.com/benthayer/arch-recovery/main/install.sh
chmod +x install.sh

# Partition your disk first (if needed)
# Example: fdisk /dev/nvme0n1
#   - Partition 1: 256MB, EFI System
#   - Partition 2: Rest, Linux filesystem

# Run it
./install.sh /dev/nvme0n1 /dev/nvme0n1p1 /dev/nvme0n1p2

# Reboot
reboot
```

## Creating a Bootable USB from Windows

1. Download the Arch ISO: https://archlinux.org/download/
2. Download Rufus: https://rufus.ie/
3. Insert USB drive
4. Open Rufus:
   - Select your USB drive
   - Select the Arch ISO
   - Partition scheme: GPT
   - Target system: UEFI
   - Click Start
5. Boot from USB (usually F12 or F2 at startup)

Alternative tools:
- [balenaEtcher](https://etcher.balena.io/) — simpler, just select ISO and drive
- [Ventoy](https://ventoy.net/) — install once, then just drag ISOs onto the USB

## Roadmap

- [ ] Phase 1: MVP (this script)
- [ ] Phase 2: Auto-detect disks, handle different hardware
- [ ] Phase 3: Personal config bootstrap (Keybase, dotfiles)
- [ ] Phase 4: Custom ISO with script baked in
- [ ] Phase 5: Windows-to-Linux exe installer
- [ ] Phase 6: Matrix boot screens
- [ ] Phase 7: Voice activation ("Captain on deck")

## The Philosophy

Your entire local computer is a cache. Everything that matters is:
- On GitHub
- In Keybase
- Re-downloadable

This script rebuilds the cache from nothing.

"What disaster?"

