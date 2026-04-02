#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════
#  CachyOS GNOME Desktop — Replication Script
#  PaperWM tiling + Blur My Shell + Ghostty
# ═══════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

divider() { echo -e "\n${DIM}$(printf '%.0s─' {1..60})${NC}\n"; }

section() {
    divider
    echo -e "${GREEN}${BOLD}[$1]${NC}"
}

ask() {
    echo -en "${CYAN}${BOLD}:: ${NC}${BOLD}$1${NC} [Y/n] "
    read -r reply
    [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

echo -e "${BOLD}${RED}"
cat << 'BANNER'
   ╔══════════════════════════════════════╗
   ║  CachyOS GNOME Desktop Installer    ║
   ║  PaperWM + Blur My Shell + Ghostty  ║
   ╚══════════════════════════════════════╝
BANNER
echo -e "${NC}"
echo -e "  ${DIM}This will install packages, GNOME extensions,${NC}"
echo -e "  ${DIM}keybindings, and app configs to replicate the DE.${NC}"

# ─────────────────────────────────────────────
section "1/6 — Install repo packages"

if [[ ! -f "$SCRIPT_DIR/packages-repo.txt" ]]; then
    echo -e "   ${RED}packages-repo.txt not found${NC}"
    exit 1
fi

echo -e "   ${DIM}$(wc -l < "$SCRIPT_DIR/packages-repo.txt") packages from official repos${NC}"
if ask "Install repo packages?"; then
    # Filter out already-installed packages
    to_install=()
    while IFS= read -r pkg; do
        pacman -Qq "$pkg" &>/dev/null || to_install+=("$pkg")
    done < "$SCRIPT_DIR/packages-repo.txt"

    if (( ${#to_install[@]} > 0 )); then
        echo -e "   ${DIM}${#to_install[@]} packages to install${NC}"
        sudo pacman -S --needed --noconfirm "${to_install[@]}"
    else
        echo -e "   ${GREEN}All repo packages already installed.${NC}"
    fi
fi

# ─────────────────────────────────────────────
section "2/6 — Install AUR packages"

if [[ ! -f "$SCRIPT_DIR/packages-aur.txt" ]]; then
    echo -e "   ${RED}packages-aur.txt not found${NC}"
    exit 1
fi

echo -e "   ${DIM}$(wc -l < "$SCRIPT_DIR/packages-aur.txt") packages from AUR${NC}"

# Ensure paru is available
if ! command -v paru &>/dev/null; then
    echo -e "   ${YELLOW}paru not found — installing...${NC}"
    sudo pacman -S --needed --noconfirm paru
fi

if ask "Install AUR packages?"; then
    to_install=()
    while IFS= read -r pkg; do
        pacman -Qq "$pkg" &>/dev/null || to_install+=("$pkg")
    done < "$SCRIPT_DIR/packages-aur.txt"

    if (( ${#to_install[@]} > 0 )); then
        echo -e "   ${DIM}${#to_install[@]} packages to install${NC}"
        paru -S --needed --noconfirm "${to_install[@]}"
    else
        echo -e "   ${GREEN}All AUR packages already installed.${NC}"
    fi
fi

# ─────────────────────────────────────────────
section "3/6 — Install GNOME extensions"

EXTENSIONS=(
    "blur-my-shell@aunetx"
    "appindicatorsupport@rgcjonas.gmail.com"
    "caffeine@patapon.info"
    "paperwm@paperwm.github.com"
    "AlphabeticalAppGrid@stuarthayhurst"
    # vicinae is a standalone app, not a shell extension
)

echo -e "   Extensions to install:"
for ext in "${EXTENSIONS[@]}"; do
    echo -e "   ${DIM}• $ext${NC}"
done

if ask "Install GNOME extensions?"; then
    for ext in "${EXTENSIONS[@]}"; do
        result=$(busctl --user call org.gnome.Shell.Extensions \
            /org/gnome/Shell/Extensions \
            org.gnome.Shell.Extensions \
            InstallRemoteExtension s "$ext" 2>&1) || true
        if echo "$result" | grep -q "successful"; then
            echo -e "   ${GREEN}installed${NC} $ext"
        else
            echo -e "   ${YELLOW}skipped${NC}  $ext (may need manual install or already present)"
        fi
    done
    echo ""
    echo -e "   ${YELLOW}Note:${NC} Extensions activate after next login."
fi

# ─────────────────────────────────────────────
section "4/6 — Apply GNOME settings (dconf)"

echo -e "   This applies:"
echo -e "   ${DIM}• Dark mode with slate accent${NC}"
echo -e "   ${DIM}• PaperWM tiling with vim keybindings${NC}"
echo -e "   ${DIM}• Blur My Shell config${NC}"
echo -e "   ${DIM}• Custom keybindings (Super+T=Ghostty, Super+Shift+Space=Vicinae)${NC}"
echo -e "   ${DIM}• Workspace navigation (Super+1-9)${NC}"
echo -e "   ${DIM}• Mutter: no edge tiling, no modal attach${NC}"

if ask "Apply GNOME dconf settings?"; then
    dconf load /org/gnome/ < "$SCRIPT_DIR/gnome-settings.dconf"
    echo -e "   ${GREEN}Settings applied.${NC}"
fi

# ─────────────────────────────────────────────
section "5/6 — Deploy app configs"

configs=(
    "config/ghostty/config:$HOME/.config/ghostty/config"
    "config/vicinae/settings.json:$HOME/.config/vicinae/settings.json"
)

for entry in "${configs[@]}"; do
    src="${entry%%:*}"
    dst="${entry##*:}"
    src_path="$SCRIPT_DIR/$src"

    if [[ -f "$src_path" ]]; then
        echo -e "   ${DIM}$src -> $dst${NC}"
    fi
done

if ask "Deploy app configs? (existing files will be backed up)"; then
    for entry in "${configs[@]}"; do
        src="${entry%%:*}"
        dst="${entry##*:}"
        src_path="$SCRIPT_DIR/$src"

        if [[ -f "$src_path" ]]; then
            mkdir -p "$(dirname "$dst")"
            if [[ -f "$dst" ]]; then
                cp "$dst" "${dst}.bak.$(date +%s)"
                echo -e "   ${YELLOW}backed up${NC} $dst"
            fi
            cp "$src_path" "$dst"
            echo -e "   ${GREEN}deployed${NC} $dst"
        fi
    done
fi

# ─────────────────────────────────────────────
section "6/6 — Enable services"

services_system=(
    "gdm"
    "bluetooth"
    "NetworkManager"
    "tailscaled"
    "ufw"
    "postgresql"
    "fstrim.timer"
)

services_user=(
    "vicinae"
    "wireplumber"
    "pipewire"
    "pipewire-pulse"
)

echo -e "   ${BOLD}System services:${NC}"
for svc in "${services_system[@]}"; do
    echo -e "   ${DIM}• $svc${NC}"
done
echo -e "   ${BOLD}User services:${NC}"
for svc in "${services_user[@]}"; do
    echo -e "   ${DIM}• $svc${NC}"
done

if ask "Enable services?"; then
    for svc in "${services_system[@]}"; do
        sudo systemctl enable "$svc" 2>/dev/null && \
            echo -e "   ${GREEN}enabled${NC} $svc" || \
            echo -e "   ${YELLOW}skip${NC}    $svc (already enabled or not found)"
    done

    for svc in "${services_user[@]}"; do
        systemctl --user enable "$svc" 2>/dev/null && \
            echo -e "   ${GREEN}enabled${NC} $svc (user)" || \
            echo -e "   ${YELLOW}skip${NC}    $svc (user, already enabled or not found)"
    done
fi

# ═══════════════════════════════════════════════
divider
echo -e "${GREEN}${BOLD}  Installation complete.${NC}"
echo ""
echo -e "  ${BOLD}What's set up:${NC}"
echo -e "  ${DIM}• GNOME + PaperWM tiling (Super+H/J/K/L navigation)${NC}"
echo -e "  ${DIM}• Blur My Shell, Caffeine, AppIndicator extensions${NC}"
echo -e "  ${DIM}• Ghostty terminal (Super+T)${NC}"
echo -e "  ${DIM}• Vicinae launcher (Super+Shift+Space)${NC}"
echo -e "  ${DIM}• Dark mode, slate accent, Papirus icons${NC}"
echo ""
echo -e "  ${YELLOW}Log out and back in to activate everything.${NC}"
echo ""
