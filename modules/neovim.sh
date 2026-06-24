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

# Pinned stable release for the self-contained Linux tarball install (distro
# packages are routinely older than this config needs). Bump to upgrade.
NVIM_LINUX_VERSION="v0.12.3"

# True if a new-enough nvim is already on PATH.
neovim_meets_min() {
  command -v nvim >/dev/null 2>&1 || return 1
  local ver major minor
  ver="$(nvim --version 2>/dev/null | sed -n '1s/.*v\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')"
  [[ -z "$ver" ]] && return 1
  major="${ver%%.*}"; minor="${ver#*.}"
  (( major > NVIM_MIN_MAJOR || (major == NVIM_MIN_MAJOR && minor >= NVIM_MIN_MINOR) ))
}

# Install the official static tarball into ~/.local (no sudo), linked onto PATH
# via ~/.local/bin (already exported in .zshrc). Picks the asset by CPU arch so
# it works on x86_64 and Graviton/arm64.
install_neovim_linux_release() {
  local arch
  case "$(uname -m)" in
    x86_64|amd64)  arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) warn "unsupported arch '$(uname -m)' for the neovim tarball; install manually"; return 1 ;;
  esac
  local asset="nvim-linux-${arch}.tar.gz"
  local url="https://github.com/neovim/neovim/releases/download/${NVIM_LINUX_VERSION}/${asset}"
  local prefix="$HOME/.local" dest="$HOME/.local/nvim-linux-${arch}"
  log "downloading neovim ${NVIM_LINUX_VERSION} (${asset})"
  local tmp; tmp="$(mktemp -d)"
  if ! curl -fsSL "$url" -o "$tmp/nvim.tar.gz"; then
    warn "neovim download failed: $url"; rm -rf "$tmp"; return 1
  fi
  mkdir -p "$prefix" "$HOME/.local/bin"
  rm -rf "$dest"
  tar -C "$prefix" -xzf "$tmp/nvim.tar.gz"      # -> ~/.local/nvim-linux-<arch>/
  rm -rf "$tmp"
  ln -sf "$dest/bin/nvim" "$HOME/.local/bin/nvim"
  # Verify it runs (a too-old system glibc would fail here).
  if ! "$HOME/.local/bin/nvim" --version >/dev/null 2>&1; then
    warn "installed neovim will not run here (likely glibc too old)."
    warn "  try the older-glibc builds at github.com/neovim/neovim-releases"
    return 1
  fi
}

install_neovim() {
  if neovim_meets_min; then
    log "neovim $(nvim --version | sed -n '1s/.*\(v[0-9.]*\).*/\1/p') present (>= ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR})"
    return
  fi
  if command -v nvim >/dev/null 2>&1; then
    warn "neovim present but older than ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR}; installing a newer build"
  else
    log "installing neovim"
  fi
  case "$PKG" in
    brew) brew install neovim ;;
    apt|dnf|yum|pacman)
      # Prefer the pinned static tarball (current, reproducible, no sudo). Fall
      # back to the distro package only if the download or run fails.
      install_neovim_linux_release || { pkg_refresh; pkg_install neovim || warn "neovim install failed; install >= ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR} manually"; }
      ;;
    *) warn "no package manager for neovim — install it manually"; return ;;
  esac
  check_neovim_version
}

# Warn if the installed nvim is older than the config requires.
check_neovim_version() {
  command -v nvim >/dev/null 2>&1 || return 0
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
