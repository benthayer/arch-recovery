# TODO

## Next Up: Deploy Key for Bootstrap

Create a read-only deploy key for the `ben` repo with memorable passphrase.

```bash
ssh-keygen -t ed25519 -a 100 -C "deploy key for ben repo" -f deploy_key
# Use memorable passphrase (test with: npx zxcvbn-cli "your passphrase")
```

Security math:
- `-a 100` = ~$300k to crack
- Passphrase with ~10^14 guesses
- Read-only access to dotfiles — not worth attacking

Store the encrypted key in this repo. Passphrase is memorized.

Bootstrap flow:
1. `install.sh` → reboot
2. Copy deploy key from this repo, decrypt with memorized passphrase
3. `git clone git@github.com:benthayer/ben.git ~/.ben`
4. `~/.ben/setup/configure.sh`
5. Later: get real SSH key from 1Password for full access

---

## Remaining Gaps

### Minor Fixes

- [ ] Add `[[ -f ]]` guards to profile sourcing (`.passwords`, `.env`, `az.completion`, `.cargo/env`)
- [ ] Default background image or graceful fallback in i3 config
- [ ] Toggl API token setup (first-run prompt or docs)

### Bootstrap Flow

- [ ] Consider single entry point script that does clone + configure in one step
- [ ] Add `--help` to install.sh and configure.sh

## Future Phases

### Phase 3: Auto-detect Hardware

- [ ] Detect available disks and partitions
- [ ] Interactive partition selection
- [ ] Handle NVMe vs SATA vs USB naming
- [ ] Detect CPU (Intel vs AMD) for microcode

### Phase 4: Secrets via Keybase

- [ ] Install Keybase in configure.sh
- [ ] Pull `.passwords` from Keybase filesystem
- [ ] Pull `.env` from Keybase filesystem
- [ ] Pull SSH keys from Keybase (or generate + upload)

### Phase 5: Custom ISO

- [ ] Archiso customization with install.sh baked in
- [ ] Auto-start installer on boot
- [ ] Include WiFi setup wizard

### Phase 6: Windows Installer

- [ ] WSL-based bootstrapper
- [ ] Partition resizing from Windows
- [ ] Dual-boot setup automation

### Phase 7: Matrix Boot

- [ ] Plymouth theme with matrix rain
- [ ] Boot splash customization
- [ ] "System online" animation

### Phase 8: Voice Activation

- [ ] "Captain on deck" voice recognition
- [ ] Trigger full restore from voice command
- [ ] Because why not

## Ideas / Maybe

- [ ] Declarative package list (parse packages.txt instead of hardcoding)
- [ ] Diff current system against packages.txt
- [ ] Rollback/snapshot support via btrfs
- [ ] Remote restore trigger (SSH into fresh system, run script)
- [ ] Encrypted secrets in repo (age/sops) instead of Keybase

