#!/usr/bin/env bash
# modules/neovim.sh — Neovim plus the versioned config in config/nvim.
#
# The config (config/nvim/init.lua) uses vim.pack, Neovim's native plugin
# manager, which requires Neovim >= 0.12. macOS (brew) ships a new enough
# build; Linux distro repos often lag, so we warn loudly if the installed
# version is too old rather than silently shipping a broken config.
#
# config/nvim is symlinked to ~/.config/nvim, so vim.pack's lock file
# (nvim-pack-lock.json) is written straight back into this repo and stays
# versioned. Plugin payloads live in ~/.local/share/nvim and are not linked.
#
# Run standalone:  ./modules/neovim.sh
# Or via the master installer:  ./install.sh
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

NVIM_MIN_MAJOR=0
NVIM_MIN_MINOR=12

install_neovim() {
  if command -v nvim >/dev/null 2>&1; then
    log "neovim present"
  else
    log "installing neovim"
    case "$PKG" in
      brew)   brew install neovim ;;
      apt)    pkg_refresh; pkg_install neovim ;;
      dnf|yum|pacman) pkg_refresh; pkg_install neovim ;;
      *) warn "no package manager for neovim — install it manually"; return ;;
    esac
  fi
  check_neovim_version
}

# Warn if the installed nvim is older than the config requires.
check_neovim_version() {
  command -v nvim >/dev/null 2>&1 || return
  local ver major minor
  ver="$(nvim --version 2>/dev/null | sed -n '1s/.*v\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')"
  [[ -z "$ver" ]] && { warn "could not determine neovim version"; return; }
  major="${ver%%.*}"; minor="${ver#*.}"
  if (( major < NVIM_MIN_MAJOR || (major == NVIM_MIN_MAJOR && minor < NVIM_MIN_MINOR) )); then
    warn "neovim $ver is older than ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR}; this config uses vim.pack and will error."
    warn "  Install a newer build: github.com/neovim/neovim/releases (nvim.appimage) or build from source."
  else
    log "neovim $ver OK (>= ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR})"
  fi
}

link_neovim_config() {
  # Symlink the whole config dir; backs up any existing real ~/.config/nvim.
  link_file "$REPO_DIR/config/nvim" "$HOME/.config/nvim"
}

module_neovim() {
  install_neovim
  link_neovim_config
  log "neovim config linked. Plugins install on first launch (nvim); treesitter parsers compile then too."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  common_init
  module_neovim
fi
