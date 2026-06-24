#!/usr/bin/env bash
# install.sh — set up this terminal environment on a new machine.
#
# Master orchestrator. Shared helpers live in lib/common.sh; each kind of
# setup is a self-contained script in modules/ that can also be run on its own
# (e.g. ./modules/neovim.sh). This script just detects the platform once and
# runs the modules you ask for, in dependency order.
#
# Safe to re-run (idempotent): backs up existing dotfiles before symlinking,
# never overwrites your secrets, and skips tools already present.
#
# Usage:
#   ./install.sh                      # everything
#   ./install.sh --chsh               # everything, and set zsh as login shell
#   ./install.sh --no-tools           # everything except the tools module
#   ./install.sh --only zsh,neovim    # just those modules
#   ./install.sh --skip tmux,tools    # everything except those
#   ./install.sh --list               # list module names and exit
#   ./install.sh --dry-run            # print which modules would run, do nothing
#   ./install.sh --help
#
# Modules (run in this order):  tools  zsh  starship  neovim  tmux
#
# Supports: macOS (Homebrew), Ubuntu/Debian (apt), Fedora/RHEL/Amazon Linux
# (dnf/yum), Arch (pacman). Falls back to upstream installers where a distro
# does not package a tool.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_DIR/lib/common.sh"

# Canonical run order. Tools (font + CLI utils) first so later modules have
# their glyphs/deps; zsh before starship; neovim and tmux are independent.
ALL_MODULES=(tools zsh starship neovim tmux)

DO_CHSH=0
DRY_RUN=0
SELECTED=()   # empty => run ALL_MODULES (minus any --skip)
SKIP=()

# --- arg parsing -----------------------------------------------------------
# Split a comma- or space-separated list into the global _SPLIT array.
# (Avoids bash 4.3 namerefs so this runs on stock macOS bash 3.2.)
_SPLIT=()
_split() { local IFS=', '; read -ra _SPLIT <<< "$1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --chsh)     DO_CHSH=1 ;;
    --no-tools) SKIP+=(tools) ;;
    --only)     shift; _split "${1:-}"; SELECTED=("${_SPLIT[@]}") ;;
    --only=*)   _split "${1#*=}"; SELECTED=("${_SPLIT[@]}") ;;
    --skip)     shift; _split "${1:-}"; SKIP+=("${_SPLIT[@]}") ;;
    --skip=*)   _split "${1#*=}"; SKIP+=("${_SPLIT[@]}") ;;
    --list)     printf '%s\n' "${ALL_MODULES[@]}"; exit 0 ;;
    --dry-run)  DRY_RUN=1 ;;
    --help|-h)  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) err "unknown argument: $1"; exit 2 ;;
  esac
  shift
done

# --- resolve the module list ----------------------------------------------
_in_list() { local x="$1"; shift; for e in "$@"; do [[ "$e" == "$x" ]] && return 0; done; return 1; }

if [[ "${#SELECTED[@]}" -eq 0 ]]; then
  SELECTED=("${ALL_MODULES[@]}")
fi

# Validate names and apply --skip, preserving canonical order.
RUN=()
for m in "${ALL_MODULES[@]}"; do
  _in_list "$m" "${SELECTED[@]}" || continue
  _in_list "$m" "${SKIP[@]:-}"   && { log "skipping module: $m"; continue; }
  RUN+=("$m")
done
# Catch typos in --only that don't match any known module.
for m in "${SELECTED[@]}"; do
  _in_list "$m" "${ALL_MODULES[@]}" || { err "unknown module: $m (see --list)"; exit 2; }
done

# --- source modules so their module_<name> functions are available --------
export DO_CHSH   # consumed by the zsh module's maybe_chsh
for m in "${ALL_MODULES[@]}"; do
  source "$REPO_DIR/modules/$m.sh"
done

# ===========================================================================
main() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "dry run — would run modules: ${RUN[*]:-<none>}"
    exit 0
  fi
  common_init
  [[ "$PKG" == "none" ]] && warn "no supported package manager found; tool installs will be skipped"

  for m in "${RUN[@]:-}"; do
    [[ -z "$m" ]] && continue
    echo
    log "=== module: $m ==="
    "module_$m"
  done

  echo
  log "done. Start a new shell:  exec zsh -l"
  if [[ "$OS" == "linux" && "$DO_CHSH" -eq 0 ]] && _in_list zsh "${RUN[@]:-}"; then
    log "next SSH login will auto-switch to zsh via ~/.bashrc"
  fi
  return 0
}

main
