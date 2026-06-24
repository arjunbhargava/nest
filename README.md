# nest

A portable terminal and editor setup. One command reconstitutes the same
shell, prompt, colors, editor, and keybindings on a new machine.

Everything is organized into five **modules** that can be installed together or
individually: `tools`, `zsh`, `starship`, `neovim`, `tmux`.

| Tool | Role |
|---|---|
| **zsh** | The shell. Replaces the system default. |
| **starship** | Prompt: git/context-aware, fast. |
| **eza** | Modern `ls` replacement. |
| **fzf** | Fuzzy finder for history and files. |
| **nvm** | Node version manager (only relevant if you write JS). |
| **Nerd Font** | JetBrains Mono patched with icon glyphs; used by the prompt, statusline, and editor. |
| **Neovim** | Editor (`nvim`), configured for coding (LSP, treesitter, completion). |
| **tmux** | Terminal multiplexer (panes, persistent sessions). |

---

## Before you run the installer

Work through this checklist first. The installer is idempotent and backs up
anything it replaces, but two things need your attention up front: secrets and
any existing shell config.

1. **Prerequisites.**
   - A terminal (iTerm2 / Ghostty / WezTerm on macOS; anything on Linux).
   - `git` (`git --version`). macOS: `xcode-select --install`. Debian/Ubuntu:
     `sudo apt-get install -y git`.
   - macOS only: Homebrew (`brew --version`; install from <https://brew.sh>).

2. **Plan your secrets.** API keys and tokens are **not** stored in this repo.
   They live in `~/.config/zsh/secrets.zsh` (`chmod 600`, gitignored, sourced at
   the end of `.zshrc`). The installer seeds that file from
   `examples/secrets.zsh.example` *only if it does not already exist*, and never
   overwrites it.
   - **Migrating from an existing setup?** If your current `~/.zshrc`,
     `~/.zshenv`, or `~/.profile` exports keys, copy them into
     `~/.config/zsh/secrets.zsh`. The installer backs those files up but does
     **not** migrate their contents — any exported variables stop loading until
     you move them. Do this before or immediately after Step 2; until then your
     keys are absent from new shells.
   - Never commit real secrets. `secrets.zsh` and `local.zsh` are gitignored;
     keep real values out of `.zshrc` and the `examples/` templates.

3. **Know what gets replaced.** Existing `~/.zshrc`, `~/.zshenv`, and
   `~/.tmux.conf` are renamed to `*.backup.<date>` and replaced with symlinks
   into this repo. Nothing is deleted. See **Is this safe?** below.

---

## Install

```sh
git clone <your-repo-url> ~/nest
cd ~/nest
./install.sh            # detects the platform, installs what's missing, links configs
exec zsh -l             # switch the current terminal to the new setup
```

`./install.sh` is safe to re-run: installed tools are skipped and existing
files are backed up before linking. It may prompt for your password when
installing system packages.

Then:

4. **Fill in secrets.** Edit `~/.config/zsh/secrets.zsh` with your real keys (or
   confirm the values you migrated in step 2). Run `exec zsh -l` to reload.

5. **Select the font.** In your terminal's settings, set the font to
   **JetBrainsMono Nerd Font** (the installer downloads it). Without this,
   icons render as empty boxes; everything else still works.

6. **First Neovim launch** (optional): `nvim`. Plugins and treesitter parsers
   install on first run — one-time, takes a minute. Quit with `:q`.

On macOS you're done; new terminals load the setup automatically. On Linux, see
**Logging in over SSH**.

---

## Installing a single module

Each module is a standalone script:

```sh
./modules/neovim.sh
./modules/tmux.sh
./modules/zsh.sh
```

Or drive the orchestrator:

```sh
./install.sh --list                 # module names
./install.sh --dry-run              # show the plan, change nothing
./install.sh --only zsh,neovim      # only these
./install.sh --skip tmux            # everything except tmux
./install.sh --help
```

---

## Is this safe?

- **Existing settings are backed up, never deleted.** A pre-existing `~/.zshrc`
  / `~/.zshenv` is renamed to `*.backup.<date>` before the new one is linked.
- **Configs are linked, not copied.** Your settings live in this repo; the
  installer symlinks each tool's expected path (e.g. `~/.config/zsh/.zshrc`)
  back to the file here. Editing once updates the live setup.
- **Installed tools are skipped**, so re-running is cheap.
- **Private keys are never touched or committed.** See **Secrets**, above, and
  the wiring table below.

---

## How your settings are wired up

Every config file lives in this repo and is symlinked into place. Most tools
read from an obvious location; zsh and starship need a small redirect.

| Repo file | Symlinked to | How the tool finds it |
|---|---|---|
| `config/zsh/zshenv` | `~/.zshenv` | zsh always reads `~/.zshenv` first; this stub sets `ZDOTDIR=~/.config/zsh` |
| `config/zsh/.zshrc` | `~/.config/zsh/.zshrc` | zsh reads `$ZDOTDIR/.zshrc` once `ZDOTDIR` is set |
| `config/starship/starship.toml` | `~/.config/starship/starship.toml` | `.zshrc` exports `STARSHIP_CONFIG` pointing here |
| `config/nvim/` | `~/.config/nvim` | Neovim's standard config dir |
| `config/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` | tmux >= 3.1 reads this XDG path |
| `config/tmux/tmux.conf.local` | `~/.config/tmux/tmux.conf.local` | oh-my-tmux derives this from `tmux.conf`'s path |

Two private files are real (not symlinks) and not in the repo. The installer
seeds them from `examples/` and never overwrites them:

| File | Purpose |
|---|---|
| `~/.config/zsh/secrets.zsh` | API keys / tokens; `chmod 600`; sourced at the end of `.zshrc` |
| `~/.config/zsh/local.zsh` | per-machine tweaks; sourced at the end of `.zshrc` |

zsh has no XDG auto-discovery — left alone it reads `~/.zshrc` from `$HOME`. The
only file it reliably reads first is `~/.zshenv`, so the stub there redirects
everything else under `~/.config/zsh/`:

```
~/.zshenv            sets ZDOTDIR=~/.config/zsh
  $ZDOTDIR/.zshrc    shell config (aliases, plugins, prompt)
    secrets.zsh      private keys      (sourced near the end)
    local.zsh        per-machine tweaks (sourced near the end)
```

The result: everything zsh-related is under `~/.config/zsh/`, every tool is a
uniform `config/<tool>/` directory, and the one-line `~/.zshenv` stub is the
only thing that must sit in `$HOME`.

---

## Customizing

| Goal | Edit | Versioned? |
|---|---|---|
| Alias/function for **every** machine | `>>> YOUR ALIASES <<<` block in `config/zsh/.zshrc` | Yes |
| API key or token | `~/.config/zsh/secrets.zsh` | No (private) |
| **This machine only** (PATH, env, aliases) | `~/.config/zsh/local.zsh` | No (private) |
| tmux keys/colors/status bar | `config/tmux/tmux.conf.local` | Yes |

---

## Logging in over SSH (Linux servers)

Skip if you only use your laptop. SSH into a Linux box usually starts bash, not
zsh. The installer adds a guarded hook to `~/.bashrc` that hands interactive
logins to zsh automatically. To make zsh the login shell permanently instead:

```sh
./install.sh --chsh
```

Prompt/statusline icons are drawn by the terminal on your *laptop* using its
font, so you only set the Nerd Font locally — never on the servers.

---

## Updating

```sh
cd ~/nest
./install.sh
```

Because configs are linked, editing a file in `nest` updates the live setup
immediately — no reinstall needed for your own tweaks.

---

## tmux

Uses **oh-my-tmux** with local customizations and a Nord status bar. Two files:

- `config/tmux/tmux.conf` — the oh-my-tmux framework, vendored unchanged from a
  pinned commit. **Do not edit.**
- `config/tmux/tmux.conf.local` — your settings (prefix, splits, mouse, colors,
  status bar). Edit this, then `prefix r` to reload a running session.

Customizations:

- Prefix `Ctrl-a`; split with `prefix |` (horizontal) and `prefix -` (vertical).
- Mouse on, 10,000-line scrollback.
- Nord status bar: session name left; battery, time, date, and an SSH-aware
  `user@host` right (the host follows you into ssh sessions).
- Copy in tmux also copies to the system clipboard.

> **Pi compatibility.** If you use the Pi coding agent, it launches its own tmux
> sessions against this config. It keeps the `extended-keys` settings Pi needs
> for `Shift+Enter` / `Ctrl+Enter` and disables oh-my-tmux's automatic plugin
> updates so session launch stays fast. Pi picks this config up automatically
> because tmux >= 3.1 reads the XDG path `~/.config/tmux/tmux.conf`.

---

## Troubleshooting

- **Empty boxes instead of icons** — Nerd Font not selected in the terminal
  (Step 5).
- **Plain prompt, no colors** — starship didn't install. Re-run
  `./modules/starship.sh` and read the warnings.
- **`command not found` for nvim/brew/eza in a fresh login** — the shell isn't
  finding Homebrew. `.zshrc` bootstraps `brew shellenv`; confirm brew is
  installed and re-run `exec zsh -l`.
- **Neovim errors on startup** — needs Neovim >= 0.12 (`nvim --version`). Distro
  builds are often too old; use a release from
  <https://github.com/neovim/neovim/releases>.
- **tmux status bar shows boxes / `<E0B0>`** — Nerd Font again (Step 5); those
  are Powerline glyphs.
- **`prefix r` says "no such file"** — a tmux server started before this config
  was installed. Run `tmux source-file ~/.config/tmux/tmux.conf` once, or
  `tmux kill-server` and reopen.
- **Restore a previous setup** — backups sit next to the originals:
  ```sh
  rm ~/.zshenv                                    # remove the symlink first
  mv ~/.zshrc.backup.<date>  ~/.zshrc
  mv ~/.zshenv.backup.<date> ~/.zshenv            # may hold old keys
  ```

---

## Repository layout

```
nest/
├── install.sh                 # orchestrator; runs the modules in dependency order
├── lib/
│   └── common.sh              # shared helpers (logging, platform detection, link_file)
├── modules/
│   ├── tools.sh               # eza, fzf, nvm, Nerd Font
│   ├── zsh.sh                 # shell, plugins, config/zsh/.zshrc
│   ├── starship.sh            # prompt
│   ├── neovim.sh              # editor
│   └── tmux.sh                # tmux
├── config/
│   ├── zsh/zshenv             # ZDOTDIR stub      (-> ~/.zshenv)
│   ├── zsh/.zshrc             # shell config      (-> ~/.config/zsh/.zshrc)
│   ├── starship/starship.toml # prompt            (-> ~/.config/starship/starship.toml)
│   ├── nvim/                  # editor            (-> ~/.config/nvim)
│   └── tmux/                  # framework + local (-> ~/.config/tmux)
└── examples/
    └── *.example              # templates for the private secrets/local files
```

Modules always run in order (`tools`, `zsh`, `starship`, `neovim`, `tmux`)
regardless of how they're requested, since later ones depend on earlier ones.
