# AGENTS.md

## Repo Overview
Collection of Bash scripts for Fedora Linux system setup (package installs, driver config, SSH permissions), organized into **modules** (subdirectories). No build system, no test suite. Run `./menu.sh` for an interactive menu.

## Module Structure
| Module | Purpose |
|--------|---------|
| `system/` | System maintenance: Btrfs snapshots, cleanup, codecs, temp/cache |
| `desktop/` | Desktop environment: KDE auto-login, GNOME dark mode, Waydroid, tweaks |
| `dev/` | Development tools: .NET, Java, VS Code setup |
| `nvidia/` | NVIDIA 390xx driver: install, repair, kernel 6/7 variants |
| `vm/` | Virtual machines: QEMU/KVM, GNOME Boxes, VirtualBox |
| `wine/` | Wine management: fix, install, remove |
| `shell/` | Shell/user config: Oh My Bash, SSH permissions |

## Critical Rules
- Most scripts **must not run as root**: They use `sudo` internally. Root execution triggers `check_root` and exits immediately (exceptions: `shell/fix-ssh-permission.sh`, `system/create-restore-point.sh`, `system/restore-system.sh`).
- Scripts modify system state: Install packages, add repos (e.g, VS Code Microsoft repo), edit `/etc` configs. Run with caution.

## Script-Specific Notes
- `shell/fix-ssh-permission.sh`: Minimal, no validation (no Fedora/root checks, no `set -e`), runs `chmod` on `~/.ssh`
- `dev/install-dotnet10-fedora.sh`: Supports Fedora 42+ (warns on older versions)
- `desktop/install-gnome-tweaks-extentions.sh`, `dev/install-vscode-dotnet10-fedora.sh`: Target Fedora 44 (warns on version mismatch)
- `nvidia/install-nvidia-fedora-390xx-kernel-6.sh`: Installs NVIDIA 390xx drivers (GeForce GT 630M/620M), disables Wayland, uses `sudo` directly (no root check)
