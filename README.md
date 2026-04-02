# CachyOS GNOME Desktop

Replicable GNOME desktop environment config for CachyOS (Arch-based, x86-64-v3).

## What's included

- **Window management**: PaperWM tiling with vim-style navigation
- **Shell**: Blur My Shell, Caffeine, AppIndicator, Alphabetical App Grid
- **Launcher**: Vicinae (Super+Shift+Space)
- **Terminal**: Ghostty (Super+T)
- **Look**: Dark mode, slate accent, Papirus icons, Adwaita theme
- **Keybindings**: Super+H/J/K/L window nav, Super+1-9 workspaces

## Quick start

```bash
git clone https://github.com/JacobWLMS/cachyos-gnome.git
cd cachyos-gnome
chmod +x install.sh
./install.sh
```

## Files

```
.
├── install.sh                  # Interactive installer
├── packages-repo.txt           # Official repo packages
├── packages-aur.txt            # AUR packages
├── gnome-settings.dconf        # Full GNOME/extension dconf dump
├── extension-settings.dconf    # Extension settings only
└── config/
    ├── ghostty/config          # Ghostty terminal config
    └── vicinae/settings.json   # Vicinae launcher config
```

## Keybindings

### PaperWM (tiling)
| Key | Action |
|-----|--------|
| `Super+H/J/K/L` | Focus left/down/up/right |
| `Super+Shift+H/J/K/L` | Move window left/down/up/right |
| `Super+F` | Toggle maximize width |
| `Super+Shift+F` | Toggle fullscreen |
| `Super+Q` | Close window |
| `Super+R` | Cycle width (1/3, 1/2, 2/3) |
| `Super+C` | Center horizontally |
| `Super+[/]` | Slurp in / Barf out |

### Workspaces
| Key | Action |
|-----|--------|
| `Super+2-9` | Switch to workspace |
| `Super+Shift+1-9` | Move window to workspace |
| `Super+I/U` | Workspace up/down |

### Apps
| Key | Action |
|-----|--------|
| `Super+T` | Ghostty terminal |
| `Super+Shift+Space` | Vicinae launcher |
