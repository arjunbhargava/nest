#!/usr/bin/env bash
# modules/starship.sh — the starship prompt and its config.
# Glyphs require a Nerd Font; the full installer (or ./modules/tools.sh)
# installs JetBrains Mono Nerd Font. Running this module alone does not.
#
# Run standalone:  ./modules/starship.sh
# Or via the master installer:  ./install.sh
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

install_starship() {
  command -v starship >/dev/null 2>&1 && { log "starship present"; return; }
  log "installing starship"
  if [[ "$PKG" == "brew" ]]; then
    brew install starship
  else
    # Official installer: pinned to the vendor domain, downloaded to a temp
    # file first (no blind curl | sh).
    local tmp; tmp="$(mktemp)"
    curl -fsSL https://starship.rs/install.sh -o "$tmp"
    sh "$tmp" --yes
    rm -f "$tmp"
  fi
}

link_starship_config() {
  link_file "$REPO_DIR/config/starship/starship.toml" "$HOME/.config/starship/starship.toml"
}

module_starship() {
  install_starship
  link_starship_config
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  common_init
  module_starship
fi
