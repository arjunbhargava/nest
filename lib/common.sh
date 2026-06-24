#!/usr/bin/env bash
# lib/common.sh — shared helpers for the my-env installer and its modules.
#
# This file is SOURCED, never executed. Both install.sh and every
# modules/*.sh source it to get logging, platform detection, package-manager
# wrappers, and the idempotent symlink helper. Sourcing twice is a no-op.

# --- guard against double-sourcing ----------------------------------------
[[ -n "${_MYENV_COMMON_LOADED:-}" ]] && return 0
_MYENV_COMMON_LOADED=1

# --- paths ----------------------------------------------------------------
# REPO_DIR = parent of this lib/ directory, resolved regardless of caller CWD.
COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$COMMON_DIR/.." && pwd)"

PLUGIN_DIR="$HOME/.zsh/plugins"
ZSH_CFG_DIR="$HOME/.config/zsh"

# --- pretty logging --------------------------------------------------------
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }

# --- OS / package-manager detection ---------------------------------------
OS="unknown"; PKG="none"; DISTRO_ID=""
detect_platform() {
  case "$(uname -s)" in
    Darwin) OS="macos"; PKG="brew" ;;
    Linux)
      OS="linux"
      [[ -r /etc/os-release ]] && DISTRO_ID="$(. /etc/os-release && echo "${ID:-} ${ID_LIKE:-}")"
      if   command -v apt-get >/dev/null 2>&1; then PKG="apt"
      elif command -v dnf     >/dev/null 2>&1; then PKG="dnf"
      elif command -v yum     >/dev/null 2>&1; then PKG="yum"
      elif command -v pacman  >/dev/null 2>&1; then PKG="pacman"
      else PKG="none"; fi
      ;;
  esac
}

# sudo only if not already root and sudo exists.
SUDO=""
need_sudo() { [[ "$(id -u)" -ne 0 ]] && command -v sudo >/dev/null 2>&1 && SUDO="sudo"; }

# common_init: run platform + sudo detection exactly once, and announce it.
# Every module calls this; the guard makes repeated calls free.
_MYENV_INIT_DONE=""
common_init() {
  [[ -n "$_MYENV_INIT_DONE" ]] && return 0
  detect_platform
  need_sudo
  log "platform: OS=$OS  pkg=$PKG  distro='${DISTRO_ID# }'"
  _MYENV_INIT_DONE=1
}

# --- package-manager wrappers ---------------------------------------------
pkg_install() {  # pkg_install <pkg> [pkg...]
  case "$PKG" in
    brew)   brew install "$@" ;;
    apt)    $SUDO apt-get install -y "$@" ;;
    dnf)    $SUDO dnf install -y "$@" ;;
    yum)    $SUDO yum install -y "$@" ;;
    pacman) $SUDO pacman -S --noconfirm "$@" ;;
    *) return 1 ;;
  esac
}

# Refresh package indexes at most once per process (apt/pacman only).
_MYENV_REFRESHED=""
pkg_refresh() {
  [[ -n "$_MYENV_REFRESHED" ]] && return 0
  _MYENV_REFRESHED=1
  case "$PKG" in
    apt)    $SUDO apt-get update -y ;;
    pacman) $SUDO pacman -Sy --noconfirm ;;
    *) : ;;
  esac
}

# --- config linking --------------------------------------------------------
# link_file <source-in-repo> <dest>: idempotent symlink. Works for files and
# directories. Backs up any pre-existing real file/dir before linking.
link_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    [[ "$(readlink "$dest")" == "$src" ]] && { log "linked: $dest"; return; }
  fi
  if [[ -e "$dest" ]]; then
    local backup="$dest.backup.$(date +%Y%m%d%H%M%S)"
    warn "backing up existing $dest -> $backup"
    mv "$dest" "$backup"
  fi
  ln -s "$src" "$dest"
  log "linked: $dest -> $src"
}
