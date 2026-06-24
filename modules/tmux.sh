#!/usr/bin/env bash
# modules/tmux.sh — tmux and its config.
#
# Config is the oh-my-tmux framework (github.com/gpakosz/.tmux), split into:
#   config/tmux/tmux.conf        the framework itself (vendored upstream, do NOT edit)
#   config/tmux/tmux.conf.local  YOUR settings — the single source of truth
# Both are symlinked into ~/.config/tmux; tmux >= 3.1 reads tmux.conf from the
# XDG location and the framework derives tmux.conf.local from the same path
# (see the TMUX_CONF probe in tmux.conf). No stray ~/.tmux.conf must exist, or
# it wins the probe ahead of the XDG path.
#
# The framework file is vendored from a pinned commit so installs are
# reproducible. To update it, re-download the same two files from a newer
# commit and re-apply the customizations block in .tmux.conf.local.
#   pinned: gpakosz/.tmux @ af33f07134b76134acca9d01eacbdecca9c9cda6
#
# Run standalone:  ./modules/tmux.sh
# Or via the master installer:  ./install.sh
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

install_tmux() {
  command -v tmux >/dev/null 2>&1 && { log "tmux present"; return; }
  log "installing tmux"
  pkg_refresh
  pkg_install tmux || warn "could not install tmux via $PKG — install it manually"
}

# oh-my-tmux's "copy to OS clipboard" needs a helper on Linux (xsel/xclip/
# wl-copy). On macOS pbcopy is built in. Best-effort; never fatal.
install_clipboard_helper() {
  [[ "$OS" == "linux" ]] || return 0
  if command -v xsel >/dev/null 2>&1 || command -v xclip >/dev/null 2>&1 \
     || command -v wl-copy >/dev/null 2>&1; then
    return 0
  fi
  log "installing clipboard helper (xclip) for tmux copy-to-clipboard"
  pkg_refresh
  pkg_install xclip || warn "no clipboard helper installed; tmux copy-to-OS-clipboard will be a no-op"
}

link_tmux_config() {
  # Retire any legacy ~/.tmux.conf so it doesn't win the framework's config
  # probe ahead of the XDG path (unless it is already our symlink).
  if [[ -e "$HOME/.tmux.conf" && ! -L "$HOME/.tmux.conf" ]]; then
    local backup="$HOME/.tmux.conf.backup.$(date +%Y%m%d%H%M%S)"
    warn "retiring legacy ~/.tmux.conf -> $backup"
    mv "$HOME/.tmux.conf" "$backup"
  fi
  link_file "$REPO_DIR/config/tmux/tmux.conf"       "$HOME/.config/tmux/tmux.conf"
  link_file "$REPO_DIR/config/tmux/tmux.conf.local" "$HOME/.config/tmux/tmux.conf.local"
}

module_tmux() {
  install_tmux
  install_clipboard_helper
  link_tmux_config
  # Warn if csi-u extended keys (Pi's preferred setup) won't be active.
  if command -v tmux >/dev/null 2>&1; then
    local v maj min; v="$(tmux -V | sed -n 's/^tmux \([0-9][0-9]*\.[0-9]*\).*/\1/p')"
    log "tmux $v installed; config linked"
    maj="${v%%.*}"; min="${v#*.}"; min="${min%%[!0-9]*}"
    if [[ -n "$maj" ]] && (( maj < 3 || (maj == 3 && min < 5) )); then
      warn "tmux $v < 3.5: Pi's 'extended-keys-format csi-u' is skipped (xterm format still works)"
    fi
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  common_init
  module_tmux
fi
