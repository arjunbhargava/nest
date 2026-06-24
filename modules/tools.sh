#!/usr/bin/env bash
# modules/tools.sh — general CLI tools shared by the rest of the setup:
# eza (modern ls), fzf (fuzzy finder), nvm (Node version manager), and the
# JetBrains Mono Nerd Font that starship and the neovim statusline need for
# their glyphs.
#
# Run standalone:  ./modules/tools.sh
# Or via the master installer:  ./install.sh
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

install_eza() {
  command -v eza >/dev/null 2>&1 && { log "eza present"; return; }
  log "installing eza"
  case "$PKG" in
    brew)   brew install eza ;;
    pacman) pkg_install eza ;;
    dnf|yum) pkg_install eza || warn "eza not in $PKG repos; install via 'cargo install eza' if needed" ;;
    apt)
      if ! pkg_install eza 2>/dev/null; then
        # Older Ubuntu/Debian: eza is not in the default repos. Add the
        # maintainer's apt repo (deb.gierens.de) as documented upstream.
        warn "eza not in apt; adding deb.gierens.de repository"
        $SUDO apt-get install -y gpg ca-certificates
        $SUDO mkdir -p /etc/apt/keyrings
        curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
          | $SUDO gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
          | $SUDO tee /etc/apt/sources.list.d/gierens.list >/dev/null
        $SUDO apt-get update -y
        pkg_install eza || warn "eza install still failed — skipping"
      fi
      ;;
    *) warn "no package manager for eza — skipping" ;;
  esac
}

install_fzf() {
  command -v fzf >/dev/null 2>&1 && { log "fzf present"; return; }
  log "installing fzf"
  pkg_install fzf || warn "fzf not installed via $PKG — clone github.com/junegunn/fzf manually"
}

# mosh: roaming, latency-tolerant SSH replacement. Makes typing over a slow or
# flaky link to a remote box feel local, and survives IP changes / sleep.
# Needs a UDP port range open to the host (e.g. an AWS security-group rule).
install_mosh() {
  command -v mosh >/dev/null 2>&1 && { log "mosh present"; return; }
  log "installing mosh"
  pkg_install mosh || warn "could not install mosh via $PKG — install it manually for roaming SSH"
}

install_nvm() {
  [[ -s "$HOME/.nvm/nvm.sh" ]] && { log "nvm present"; return; }
  log "installing nvm"
  local tmp; tmp="$(mktemp)"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh -o "$tmp"
  PROFILE=/dev/null bash "$tmp"   # PROFILE=/dev/null: don't let nvm edit our .zshrc
  rm -f "$tmp"
}

# Nerd Font (JetBrains Mono) so starship and the neovim statusline render glyphs.
install_font() {
  if [[ "$PKG" == "brew" ]]; then
    if brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
      log "nerd font present"
    else
      log "installing JetBrains Mono Nerd Font"
      brew install --cask font-jetbrains-mono-nerd-font || warn "font cask failed"
    fi
    return
  fi
  # Linux: drop the TTFs into ~/.local/share/fonts.
  local font_dir="$HOME/.local/share/fonts"
  if ls "$font_dir"/JetBrainsMono*Nerd* >/dev/null 2>&1; then
    log "nerd font present"; return
  fi
  log "installing JetBrains Mono Nerd Font to $font_dir"
  mkdir -p "$font_dir"
  local tmp; tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/JetBrainsMono.zip" \
      https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip; then
    ( cd "$tmp" && unzip -oq JetBrainsMono.zip -d "$font_dir" )
    command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$font_dir" >/dev/null 2>&1 || true
  else
    warn "font download failed — install a Nerd Font manually for glyphs"
  fi
  rm -rf "$tmp"
}

module_tools() {
  [[ "$PKG" == "none" ]] && { warn "no supported package manager; skipping tools"; return; }
  pkg_refresh
  install_font
  install_eza
  install_fzf
  install_mosh
  install_nvm
}

# Run directly only when executed, not when sourced by install.sh.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  common_init
  module_tools
fi
