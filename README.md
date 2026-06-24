# nest

This repository is a saved copy of a complete terminal and text-editor setup.
Run one command on a new computer and it will look and behave exactly like the
machine you set it up on: the same prompt, the same colors, the same editor,
the same shortcuts.

You do not need to understand every tool below to use it. Follow the numbered
steps and it will work. If a word is unfamiliar, check the **Glossary** at the
bottom.

---

## What you are installing (in plain terms)

| Thing | What it is, in one sentence |
|---|---|
| **zsh** | The program that runs when you type commands (a "shell"). It replaces the default one. |
| **starship** | Makes the line you type commands on (the "prompt") informative and good-looking. |
| **eza** | A nicer-looking replacement for the `ls` command that lists files. |
| **fzf** | Lets you search your command history and files by typing a few letters. |
| **nvm** | Installs and switches between versions of Node.js (only needed if you write JavaScript). |
| **Nerd Font** | A font that includes little icons. The prompt and editor use these icons. |
| **Neovim** | A keyboard-driven text editor (the command is `nvim`), set up for coding. |
| **tmux** | Lets you split one terminal window into several panes and keep sessions running. |

These are grouped into five **modules** you can install all at once or one at a
time: `tools`, `zsh`, `starship`, `neovim`, `tmux`.

---

## Before you start

You need two things already on the computer:

1. **A terminal.** This is the app where you type commands.
   - macOS: the built-in app is called **Terminal** (find it with Spotlight).
     A nicer free option is **iTerm2**, **Ghostty**, or **WezTerm**.
   - Linux: whatever terminal your system came with is fine.

2. **`git`**, a tool for downloading code. Check if you have it by typing:
   ```sh
   git --version
   ```
   If you see a version number, you are set. If you see "command not found":
   - macOS: run `xcode-select --install` and accept the popup.
   - Ubuntu/Debian: run `sudo apt-get install -y git`.

**macOS only — one extra tool:** this setup installs software using
**Homebrew**, the standard macOS software installer. Check for it with:
```sh
brew --version
```
If that says "command not found", install Homebrew first by following the one
command on <https://brew.sh>, then come back here.

---

## Install — step by step

### Step 1 — Download this setup onto the computer

Copy and paste this into your terminal. It puts the files in a folder called
`nest` inside your home directory, then moves you into that folder.

```sh
git clone <your-repo-url> ~/nest
cd ~/nest
```

Replace `<your-repo-url>` with the address of your copy of this repository. If
the files are already on the machine (for example you copied them by hand),
just run `cd ~/nest`.

### Step 2 — Run the installer

```sh
./install.sh
```

That is the whole installation. The script figures out what kind of computer
you are on, installs anything that is missing, and connects all the
configuration files. It is safe to run more than once — if something is already
installed, it is skipped, and your existing files are backed up before anything
is changed (see **"Is this safe?"** below).

You may be asked for your password once or twice. That is normal: installing
software sometimes needs permission.

### Step 3 — Start your new shell

```sh
exec zsh -l
```

This switches your current terminal over to the new setup. You should
immediately see the new prompt.

On **macOS** you are done. Close and reopen your terminal and the new setup
loads automatically every time.

On **Linux**, read the short section **"Logging in over SSH"** below — there is
one extra thing to know.

### Step 4 (one time) — Turn on the icon font

The prompt and editor use a special font with built-in icons. The installer
downloads it, but you have to tell your terminal app to use it. This is a
setting in your terminal, changed with the mouse, not a command:

- Open your terminal app's **Settings / Preferences**.
- Find the **Font** option.
- Choose **"JetBrainsMono Nerd Font"**.

If you skip this, everything still works — you will just see small empty boxes
where icons should be.

### Step 5 (optional) — Open the editor for the first time

```sh
nvim
```

The first time you open Neovim it downloads its add-ons and may take a minute.
This is normal and only happens once. To quit Neovim, type `:q` and press
Enter.

---

## Installing just one piece

You do not have to install everything. Each module is its own small script you
can run by itself. For example:

```sh
./modules/neovim.sh        # set up only the editor
./modules/tmux.sh          # set up only tmux
./modules/zsh.sh           # set up only the shell
```

Or use the main installer with options:

```sh
./install.sh --list                 # show the list of module names
./install.sh --dry-run              # show what WOULD happen, change nothing
./install.sh --only zsh,neovim      # install only these two
./install.sh --skip tmux            # install everything except tmux
./install.sh --help                 # show all options
```

`--dry-run` is a good way to see what the installer plans to do before letting
it do anything.

---

## Is this safe? (What the installer does to your files)

Yes, and here is exactly how it avoids surprises:

- **It never deletes your existing settings.** If you already have a file like
  `~/.zshrc` or `~/.zshenv`, the installer first renames it to
  `<name>.backup.<date>` so you can get it back, then puts the new one in place.
- **It does not copy files; it links them.** Your settings live in this
  `nest` folder. The installer creates a "symlink" (a shortcut) from the
  place each tool looks (e.g. `~/.config/zsh/.zshrc`) back to the file in
  `nest`. This
  means when you edit a setting later, you edit it in one place and it is
  already saved with the rest of your setup.
- **It skips anything already installed**, so re-running it is cheap and safe.
- **It never touches your private keys.** See the next section.

---

## How your settings are wired up (the flow)

Every configuration file lives in this `nest` folder. The installer creates a
symlink from the place each tool looks, back to the file here. Most tools read
from an obvious location; two need a small redirect, explained below.

| File in this repo | Symlinked to | How the tool finds it |
|---|---|---|
| `config/zsh/zshenv` | `~/.zshenv` | zsh **always** reads `~/.zshenv` first; this stub sets `ZDOTDIR=~/.config/zsh` so the rest of the shell config is found there |
| `config/zsh/.zshrc` | `~/.config/zsh/.zshrc` | zsh reads `$ZDOTDIR/.zshrc` (i.e. this file) once `ZDOTDIR` is set above |
| `config/starship/starship.toml` | `~/.config/starship/starship.toml` | `.zshrc` exports `STARSHIP_CONFIG` pointing at this path |
| `config/nvim/` | `~/.config/nvim` | Neovim's standard config directory |
| `config/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` | tmux >= 3.1 reads this XDG path automatically |
| `config/tmux/tmux.conf.local` | `~/.config/tmux/tmux.conf.local` | the oh-my-tmux framework derives this from `tmux.conf`'s own path |

Two private files are **not** symlinked and **not** in this repo — they are real
files the installer seeds into `~/.config/zsh/` and never overwrites:

| File | Purpose |
|---|---|
| `~/.config/zsh/secrets.zsh` | API keys and tokens; `chmod 600`; sourced at the end of `.zshrc` |
| `~/.config/zsh/local.zsh` | per-machine tweaks; sourced at the end of `.zshrc` |

**The zsh startup order** (why the `~/.zshenv` redirect is needed): zsh has no
automatic support for an XDG config directory — left alone it reads `~/.zshrc`
from your home folder. The only file it guarantees to read first is `~/.zshenv`.
So the flow is:

```
~/.zshenv            -> sets ZDOTDIR=~/.config/zsh
  $ZDOTDIR/.zshrc    -> the real shell config (aliases, plugins, prompt)
    secrets.zsh      -> your private keys   (sourced near the end)
    local.zsh        -> per-machine tweaks  (sourced near the end)
```

The payoff: everything zsh-related lives together under `~/.config/zsh/`, and
every tool is a uniform `config/<tool>/` folder in this repo — the only file
that must sit directly in your home folder is the one-line `~/.zshenv` stub.

---

## Where to put your own customizations

Three kinds of changes, three places:

| You want to... | Edit this file | Shared across machines? |
|---|---|---|
| Add a shortcut you want on **every** computer | the `>>> YOUR ALIASES <<<` block in `config/zsh/.zshrc` | Yes (saved in this repo) |
| Add an API key or password | `~/.config/zsh/secrets.zsh` | **No** — kept private, never uploaded |
| Add something for **this one** computer only | `~/.config/zsh/local.zsh` | **No** |
| Change tmux (keys, colors, status bar) | `config/tmux/tmux.conf.local` | Yes (saved in this repo) |

The installer creates the two private files for you from examples in the
`examples/` folder, and never overwrites them once they exist. Your real
secrets stay on your machine and are kept out of this repository on purpose.

(An "alias" is just a short name for a longer command — for example, making
`ll` mean "list files in detail".)

---

## Logging in over SSH (Linux servers)

Skip this if you only use your own laptop.

When you connect to a Linux server with `ssh`, it usually starts the old shell
(bash), not zsh. The installer handles this for you automatically: the next
time you log in, it switches you into zsh by itself. You do not need to do
anything.

If you would rather make zsh the permanent default on that server, run:

```sh
./install.sh --chsh
```

One more thing: the icons in the prompt are drawn by the terminal app **on your
laptop**, using your laptop's font (from Step 4). So you only need to set the
Nerd Font on your own computer, not on every server you connect to.

---

## Updating later

To pull in newer settings or tools, just run the installer again:

```sh
cd ~/nest
./install.sh
```

Because everything is linked rather than copied, editing a file in `nest`
updates your live setup right away — no reinstall needed for your own tweaks.

---

## The tmux setup (split panes + status bar)

tmux lets you split one window into panes and keep work running after you close
the terminal. This setup uses **oh-my-tmux**, a popular ready-made tmux config,
with a few personal tweaks and a status bar colored to match the Neovim theme.

It is two files, and the split matters:

- `config/tmux/tmux.conf` — the oh-my-tmux framework itself. It is downloaded
  unchanged from the project (pinned to a specific version). **Do not edit
  it.**
- `config/tmux/tmux.conf.local` — **your** settings. This is the single source of
  truth: prefix key, splits, mouse, colors, and the status bar all live here.
  Edit this file and run `./install.sh` (or just `./modules/tmux.sh`).

What the tweaks give you:

- Prefix key is `Ctrl-a` (instead of the default `Ctrl-b`).
- Split side-by-side with `prefix |`, stacked with `prefix -`.
- Mouse on, 10,000-line scrollback.
- A Nord-colored status bar showing the session name on the left and the time,
  date, and `user@host` on the right (the `user@host` makes it obvious which
  machine you are on when you SSH around).
- Copy in tmux also copies to your system clipboard.

To apply changes to a **running** tmux, press `prefix r` (reload), or fully
restart with `tmux kill-server` and reopen.

> **A note on Pi.** If you use the Pi coding agent, it launches its own tmux
> sessions. This config is intentionally compatible with that: it keeps the
> `extended-keys` settings Pi needs for `Shift+Enter` / `Ctrl+Enter`, and it
> turns off oh-my-tmux's automatic plugin updates so launching a session stays
> fast. Pi's sessions automatically use this same config because tmux >= 3.1
> reads it from the XDG location `~/.config/tmux/tmux.conf`.

---

## If something goes wrong

- **I see empty boxes instead of icons.** The Nerd Font is not selected in your
  terminal. Redo Step 4.
- **The prompt looks plain / no colors.** `starship` may not have installed.
  Re-run `./modules/starship.sh` and read any warnings it prints.
- **Neovim shows errors on startup.** The config needs Neovim version 0.12 or
  newer. Check your version with `nvim --version`. On Linux the version from
  the system installer is often too old; download a newer build from
  <https://github.com/neovim/neovim/releases>.
- **The tmux status bar shows boxes or `<E0B0>` instead of arrows.** That is
  the Nerd Font again — set it in your terminal (Step 4). The arrows are
  Powerline icons that the font provides.
- **I want my old setup back.** Your previous files were saved next to the new
  ones with a `.backup.<date>` ending. For example, to restore a former shell
  config and its environment file:
  ```sh
  mv ~/.zshrc.backup.20260624153000  ~/.zshrc     # use your actual backup name
  mv ~/.zshenv.backup.20260624153000 ~/.zshenv    # (this one may hold old keys)
  ```
  Then remove the `~/.zshenv` symlink first if it points into `nest`.

---

## Glossary

- **Terminal** — the app where you type commands.
- **Shell** — the program inside the terminal that reads and runs your commands
  (here, zsh).
- **Prompt** — the text at the start of the line where you type, e.g. the part
  that shows the current folder.
- **Dotfile** — a settings file whose name starts with a dot, like `.zshrc`.
  The dot hides it from normal file listings. These hold your configuration.
- **Symlink (symbolic link)** — a shortcut that points to a file somewhere
  else. The installer uses these so your settings can live in `nest` while
  the system finds them in their usual spots.
- **Package manager** — the tool that installs software on your system
  (Homebrew on macOS; apt, dnf, yum, or pacman on Linux). The installer detects
  which one you have and uses it.
- **Module** — one of the five installable pieces of this setup: `tools`,
  `zsh`, `starship`, `neovim`, `tmux`.
- **SSH** — a way to log in to another computer (usually a server) over the
  network from your terminal.

---

## For the curious: how the repository is organized

```
nest/
├── install.sh                 # the one command you run; it calls the modules below
├── lib/
│   └── common.sh              # shared helper code used by every module
├── modules/
│   ├── tools.sh               # eza, fzf, nvm, and the Nerd Font
│   ├── zsh.sh                 # the shell, its add-ons, and config/zsh/.zshrc
│   ├── starship.sh            # the prompt and its settings
│   ├── neovim.sh              # the editor and its settings
│   └── tmux.sh                # tmux and its settings
├── config/
│   ├── zsh/zshenv             # ZDOTDIR stub     (linked to ~/.zshenv; points zsh at config/zsh)
│   ├── zsh/.zshrc             # shell settings   (linked to ~/.config/zsh/.zshrc)
│   ├── starship/starship.toml # prompt settings  (linked to ~/.config/starship/starship.toml)
│   ├── nvim/                  # editor settings  (linked to ~/.config/nvim)
│   └── tmux/                  # tmux framework + YOUR settings (linked to ~/.config/tmux)
└── examples/
    └── *.example              # templates for your private secrets/local files
```

The modules always run in a sensible order (`tools`, then `zsh`, `starship`,
`neovim`, `tmux`) no matter how you ask for them, because some pieces depend on
others being in place first.
