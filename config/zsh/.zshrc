#!/usr/bin/env zsh
# Portable .zshrc — managed by ~/nest (https://github.com/<you>/nest)
# Works on macOS (Homebrew) and Linux (apt/dnf/pacman + ~/.zsh/plugins).
# Edit the clearly-marked sections below for your own aliases; put machine-
# specific values and secrets in the local files sourced at the very end.

# ---------------------------------------------------------------------------
# Helper: source the first candidate path that exists. Lets one .zshrc work
# across machines where the same plugin lives in different locations.
# ---------------------------------------------------------------------------
_source_first() {
  local candidate
  for candidate in "$@"; do
    if [[ -r "$candidate" ]]; then
      source "$candidate"
      return 0
    fi
  done
  return 1
}

# Resolve Homebrew prefix once (empty string on machines without brew).
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
else
  BREW_PREFIX=""
fi

# ===========================================================================
# >>> YOUR ALIASES <<<  (portable; versioned in ~/nest)
# Add aliases you want on every machine here.
# ===========================================================================
alias l='ls -alh'

# eza replaces ls only if it is installed; otherwise plain ls stays usable.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lah --group-directories-first --git'
  alias la='eza -a  --group-directories-first'
  alias lt='eza --tree --level=2 --group-directories-first'
fi
# ===========================================================================
# <<< END YOUR ALIASES <<<
# ===========================================================================

# ---------------------------------------------------------------------------
# PATH
# ---------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
# Add the current directory to PYTHONPATH (kept from your original setup).
export PYTHONPATH="${PYTHONPATH:+${PYTHONPATH}:}."

# ---------------------------------------------------------------------------
# History + completion (sane defaults)
# ---------------------------------------------------------------------------
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY INC_APPEND_HISTORY
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000 SAVEHIST=100000

autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' menu select

# ---------------------------------------------------------------------------
# zsh-autosuggestions
# ---------------------------------------------------------------------------
_source_first \
  "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'   # dim grey

# ---------------------------------------------------------------------------
# history-substring-search: type a prefix, then up/down filters matches
# ---------------------------------------------------------------------------
_source_first \
  "$HOME/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  "$BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  "/usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  "/usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ---------------------------------------------------------------------------
# fzf: prefer the built-in `fzf --zsh` (v0.48+); fall back to ~/.fzf.zsh
# ---------------------------------------------------------------------------
if command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
  source <(fzf --zsh)
else
  _source_first "$HOME/.fzf.zsh"
fi

# ---------------------------------------------------------------------------
# nvm (loaded lazily-ish; guarded so it is a no-op when nvm is absent)
# ---------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
_source_first "$NVM_DIR/nvm.sh"
_source_first "$NVM_DIR/bash_completion"

# ---------------------------------------------------------------------------
# conda (only initializes if a conda install is found; tries common prefixes)
# ---------------------------------------------------------------------------
for _conda_base in "$HOME/miniconda3" "$HOME/anaconda3" "/opt/anaconda3" "/opt/miniconda3" "/opt/homebrew/anaconda3"; do
  if [[ -x "$_conda_base/bin/conda" ]]; then
    __conda_setup="$("$_conda_base/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)"
    if [[ $? -eq 0 ]]; then
      eval "$__conda_setup"
    elif [[ -f "$_conda_base/etc/profile.d/conda.sh" ]]; then
      source "$_conda_base/etc/profile.d/conda.sh"
    else
      export PATH="$_conda_base/bin:$PATH"
    fi
    unset __conda_setup
    break
  fi
done
unset _conda_base

# ---------------------------------------------------------------------------
# starship prompt (only if installed; otherwise a minimal built-in fallback)
# ---------------------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
  eval "$(starship init zsh)"
else
  # Fallback prompt so a fresh machine without starship is still usable.
  setopt PROMPT_SUBST
  PROMPT='%F{blue}%n%f@%F{green}%m%f:%F{magenta}%~%f
%F{white}→%f '
fi

# ===========================================================================
# >>> LOCAL / MACHINE-SPECIFIC <<<  (NOT versioned — never committed)
# Secrets (API keys, tokens) live in ~/.config/zsh/secrets.zsh
# Per-machine aliases/exports/PATH tweaks live in ~/.config/zsh/local.zsh
# Both are optional; this is a no-op if they do not exist.
# ===========================================================================
_source_first "$HOME/.config/zsh/secrets.zsh"
_source_first "$HOME/.config/zsh/local.zsh"
# ===========================================================================
# <<< END LOCAL <<<
# ===========================================================================

# ---------------------------------------------------------------------------
# zsh-syntax-highlighting: MUST be the LAST thing sourced.
# ---------------------------------------------------------------------------
_source_first \
  "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
