#!/usr/bin/env bash
# modules/zsh.sh — the shell itself: zsh, the three zsh plugins, the portable
# .zshrc, the local secrets/local.zsh seeds, and the mechanism that lands you
# in zsh after an SSH login (bash handoff on Linux, optional chsh).
#
# zsh has no XDG auto-discovery, so a one-line ~/.zshenv (home/.zshenv) sets
# ZDOTDIR=~/.config/zsh; the real .zshrc (config/zsh/.zshrc) and the private
# secrets.zsh / local.zsh all live under ~/.config/zsh.
#
# Run standalone:  ./modules/zsh.sh [--chsh]
# Or via the master installer:  ./install.sh
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

# Set by the caller (master installer passes --chsh through; standalone parses
# its own args in the direct-exec guard below).
DO_CHSH="${DO_CHSH:-0}"

install_zsh() {
  command -v zsh >/dev/null 2>&1 && { log "zsh present"; return; }
  log "installing zsh"
  pkg_refresh
  pkg_install zsh || warn "could not install zsh via $PKG — install it manually"
}

# Clone the three zsh plugins into ~/.zsh/plugins so the SAME .zshrc works on
# every OS regardless of how (or whether) the distro packages them.
install_zsh_plugins() {
  command -v git >/dev/null 2>&1 || pkg_install git || { warn "git missing; skipping plugins"; return; }
  mkdir -p "$PLUGIN_DIR"
  local name url
  while read -r name url; do
    [[ -z "$name" ]] && continue
    if [[ -d "$PLUGIN_DIR/$name/.git" ]]; then
      log "updating plugin $name"
      git -C "$PLUGIN_DIR/$name" pull --quiet --ff-only || warn "could not update $name"
    else
      log "cloning plugin $name"
      git clone --depth 1 "$url" "$PLUGIN_DIR/$name" || warn "could not clone $name"
    fi
  done <<'PLUGINS'
zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting
zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search
PLUGINS
}

link_zsh_config() {
  # ~/.zshenv points ZDOTDIR at ~/.config/zsh; retire any legacy real ~/.zshrc
  # so it can't shadow the relocated config (harmless once ZDOTDIR is set, but
  # we keep $HOME clean).
  link_file "$REPO_DIR/home/.zshenv" "$HOME/.zshenv"
  if [[ -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    local backup="$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    warn "retiring legacy ~/.zshrc -> $backup"
    mv "$HOME/.zshrc" "$backup"
  fi

  mkdir -p "$ZSH_CFG_DIR"
  link_file "$REPO_DIR/config/zsh/.zshrc" "$ZSH_CFG_DIR/.zshrc"

  # Seed local files from examples WITHOUT overwriting anything that exists.
  if [[ ! -e "$ZSH_CFG_DIR/secrets.zsh" ]]; then
    cp "$REPO_DIR/examples/secrets.zsh.example" "$ZSH_CFG_DIR/secrets.zsh"
    chmod 600 "$ZSH_CFG_DIR/secrets.zsh"
    log "created $ZSH_CFG_DIR/secrets.zsh (fill in your own secrets; not versioned)"
  else
    log "secrets.zsh already exists — leaving it untouched"
  fi
  if [[ ! -e "$ZSH_CFG_DIR/local.zsh" ]]; then
    cp "$REPO_DIR/examples/local.zsh.example" "$ZSH_CFG_DIR/local.zsh"
    log "created $ZSH_CFG_DIR/local.zsh (machine-specific tweaks; not versioned)"
  else
    log "local.zsh already exists — leaving it untouched"
  fi
}

# On Linux/AWS the login shell is usually bash. Rather than rely on chsh (often
# unavailable on ephemeral instances), append a guarded hook to ~/.bashrc that
# hands interactive logins over to zsh. Idempotent via a marker line.
setup_bash_handoff() {
  [[ "$OS" == "linux" ]] || return
  command -v zsh >/dev/null 2>&1 || return
  local marker="# >>> my-env: hand off to zsh >>>"
  local rc="$HOME/.bashrc"
  if [[ -f "$rc" ]] && grep -qF "$marker" "$rc"; then
    log "bash->zsh handoff already present in ~/.bashrc"
    return
  fi
  log "adding bash->zsh handoff to ~/.bashrc"
  cat >> "$rc" <<EOF

$marker
# If zsh is available and this is an interactive shell, switch to zsh.
if [ -t 1 ] && command -v zsh >/dev/null 2>&1 && [ -z "\$ZSH_VERSION" ]; then
  export SHELL="\$(command -v zsh)"
  exec zsh -l
fi
# <<< my-env: hand off to zsh <<<
EOF
}

maybe_chsh() {
  [[ "$DO_CHSH" -eq 1 ]] || return
  local zsh_path; zsh_path="$(command -v zsh)" || { warn "zsh not found; cannot chsh"; return; }
  if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
    log "registering $zsh_path in /etc/shells"
    echo "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null || warn "could not edit /etc/shells"
  fi
  log "setting login shell to $zsh_path (you may be prompted for your password)"
  chsh -s "$zsh_path" || warn "chsh failed — use the .bashrc handoff instead"
}

module_zsh() {
  install_zsh
  install_zsh_plugins
  link_zsh_config
  setup_bash_handoff
  maybe_chsh
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  for arg in "$@"; do
    case "$arg" in
      --chsh) DO_CHSH=1 ;;
      *) err "unknown argument: $arg"; exit 2 ;;
    esac
  done
  common_init
  module_zsh
fi
