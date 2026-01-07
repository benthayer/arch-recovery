# arch-restore

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

- Auto-detect disks/partitions
- Handle dual-boot scenarios
- Matrix screen animations

## Full Bootstrap Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. ARCH-RESTORE (~15 min)                                      │
│     Boot ISO → partition → ./install.sh → reboot                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  2. PERSONALIZATION (~45 min)                                   │
│     git clone https://github.com/benthayer/ben.git ~/.ben       │
│     ~/.ben/setup/configure.sh                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  3. AUTH DANCE (~10 min)                                        │
│     ssh-keygen, gh auth, gcloud auth, az login, doctl auth      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                           DONE
```

**Total recovery time: ~1 hour**

### What's Automated

| Component | Handled by |
|-----------|------------|
| Base Arch system | `arch-restore/install.sh` |
| i3 + sddm + NetworkManager | `arch-restore/install.sh` |
| All packages (pacman + AUR) | `~/.ben/setup/configure.sh` |
| Dotfiles + configs | `~/.ben/setup/configure.sh` |
| oh-my-zsh, nvm, node, bun | `~/.ben/setup/configure.sh` |
| toggl CLI | `~/.ben/setup/configure.sh` |
| Docker, CUPS, Bluetooth | `~/.ben/setup/configure.sh` |
| System configs (/etc) | `~/.ben/setup/configure.sh` |

### What's Manual (inherently interactive)

| What | Why |
|------|-----|
| SSH key generation | Passphrase decision |
| `gh auth login` | OAuth browser flow |
| `gcloud auth login` | OAuth browser flow |
| `az login` | OAuth browser flow |
| `doctl auth init` | Token input |
| `.passwords` file | Contains secrets |

## Usage

### Phase 1: Base System

```bash
# Boot Arch ISO, connect to WiFi
iwctl station wlan0 connect "YourWiFi"

# Get the script
curl -O https://raw.githubusercontent.com/benthayer/arch-restore/main/install.sh
chmod +x install.sh

# Partition your disk first (if needed)
# Example: fdisk /dev/nvme0n1
#   - Partition 1: 256MB, EFI System
#   - Partition 2: Rest, Linux filesystem

# Run it
./install.sh /dev/nvme0n1p1 /dev/nvme0n1p2

# Reboot
reboot
```

### Phase 2: Personalization

```bash
# Login as ben (password: changeme)
# Connect to WiFi
nmcli device wifi connect "YourWiFi" password "YourPassword"

# Clone and run
git clone https://github.com/benthayer/ben.git ~/.ben
~/.ben/setup/configure.sh

# Reboot
reboot
```

### Phase 3: Auth

```bash
ssh-keygen -t ed25519 -C "ben@benthayer.com"
gh auth login
gcloud auth login
az login
doctl auth init
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

- [x] Phase 1: MVP base system install
- [x] Phase 2: Personal config bootstrap (dotfiles, packages, tools)
- [ ] Phase 3: Auto-detect disks, handle different hardware
- [ ] Phase 4: Secrets via Keybase
- [ ] Phase 5: Custom ISO with script baked in
- [ ] Phase 6: Windows-to-Linux exe installer
- [ ] Phase 7: Matrix boot screens
- [ ] Phase 8: Voice activation ("Captain on deck")

## The Philosophy

Your entire local computer is a cache. Everything that matters is:
- On GitHub
- In Keybase
- Re-downloadable

This script rebuilds the cache from nothing.

"What disaster?"

