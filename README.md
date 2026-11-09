# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## What's included

### Shell
- `.bashrc` - Bash shell configuration
- `bash/` - Modular bash configuration:
  - `.aliases.sh` - Shell aliases (exa, clipboard, tool launchers)
  - `.exports.sh` - Environment variables, PATH, and 1Password secrets integration
  - `.functions.sh` - Loader for modular function files
  - `.bash_functions/` - Function modules (Datadog, process tools, search)
  - `.claude/` - Claude Code project settings
  - `CLAUDE.md` - Claude Code context for the bash config

#### How it loads

`.bashrc` sources three entry files; `.functions.sh` is just a loop that auto-sources
every `*.sh` in `.bash_functions/` — drop a new file in there and it's picked up, no
registration needed.

```
~/.bashrc
   ├─ . bash/.exports.sh      env vars, PATH, 1Password secret loading
   ├─ . bash/.aliases.sh      exa-for-ls, clipboard (xclip), tool launchers
   └─ . bash/.functions.sh    loader loop ↓
          └─ for f in bash/.bash_functions/*.sh; do . "$f"; done
                ├─ process.sh    psf, pscmd
                ├─ search.sh     rgand, rgor
                └─ datadog.sh    ddlogs, ddlog-send, ddmonitor
```

Custom commands:

| Command | Purpose |
|---------|---------|
| `psf <name>` | Find processes by name, formatted |
| `pscmd <pid>` | Show a process's full command line, formatted |
| `rgand pat1 pat2 …` | ripgrep lines matching **all** patterns |
| `rgor pat1 pat2 …` | ripgrep lines matching **any** pattern |
| `ddlogs <query> [timeframe] [limit]` | Search Datadog logs |
| `ddlog-send <service> <message> [source] [tags]` | Send a log to Datadog |
| `ddmonitor <subcommand>` | Datadog monitor management (list/get/create/update/mute/…) |

#### Secrets (1Password)

Secrets are **never stored in plaintext** — they live in the **"Bash Secrets"** item in
the **"Dev"** 1Password vault. `load_secrets` (in `.exports.sh`) pulls them via the
`op` CLI, formats each field into an `export`, and caches the result to
`~/.cache/op_secrets` (mode `600`):

```bash
op item get 'Bash Secrets' --vault=Dev --format=json \
  | jq -r '.fields[] | ... | "export \(.label)=\(.value | @sh)"' > ~/.cache/op_secrets
```

- **First terminal after boot** authenticates once (fingerprint) and writes the cache.
- **Every later terminal** sources the cache instantly — no auth, no network.
- **After rotating/adding a secret:** `op item edit "Bash Secrets" --vault=Dev 'NEW_VAR=value'`
  then `load_secrets refresh` to re-fetch and rewrite the cache.
- Requires the 1Password desktop app with CLI integration enabled
  (Settings → Developer → Integrate with 1Password CLI). Non-secret config
  (ports, hostnames, paths) stays as plain `export` in `.exports.sh`.

### Dev tools
- `.gitconfig` - Git configuration with aliases and LFS setup
- `.ideavimrc` - IdeaVim plugin configuration for IntelliJ IDEA
- `.wezterm.lua` - WezTerm terminal configuration
- `.config/starship.toml` - Starship shell prompt (see below)
- `.local/bin/hikari` - Use the desktop ("hikari") as a server over Tailscale: zellij sessions,
  Claude Code, sending screenshots to it (`hikari paste`). Guide: [docs/hikari.md](docs/hikari.md)

> **Neovim** is *not* tracked here — it lives in its own repo at
> [`erickPaar/neovim-config`](https://github.com/erickPaar/neovim-config)
> (cloned to `~/.config/nvim`). Kept separate because its Lazy `lazy-lock.json`
> lifecycle and nested git repo don't play well inside chezmoi.

### Shell prompt (Starship)

Cross-shell prompt rendered from `.config/starship.toml`. Layout:

- **Left:** directory (`🏡` for home, truncated to repo root) → git branch → git status → kotlin → java → nodejs → `➜` (green) / `✗` (red on failure)
- **Right:** command duration (only if the command ran >2s) → `HH:MM` clock

Notable settings:
- `command_timeout = 1000` — drops any module that takes >1s, so large git repos never stall the prompt
- `git_status` and `kotlin`/`java` modules enabled (version shown only inside relevant projects)
- `package`, `git_commit`, `aws`, `python` disabled to cut clutter
- Uses ANSI color names, so it adapts to the active WezTerm theme rather than hard-coded hex

### Terminal multiplexer (Zellij)
- `.config/zellij/config.kdl` — main config (theme, persistence, keys). A template: the laptop keeps
  `copy_command "xclip …"`, the desktop (hikari) copies through the terminal (OSC 52)
- `.config/zellij/layouts/hikari.kdl` — default layout: one [zjstatus](https://github.com/dj95/zjstatus) bar at the top
- `.config/zellij/layouts/dev.kdl` — dev layout (editor + shell + logs)
- `.config/zellij/plugins/zjstatus.wasm` — fetched by chezmoi (`.chezmoiexternal.toml`, pinned v0.25.0, checksum-verified);
  `run_onchange_after_zellij-permissions.sh` grants its permissions so the bar never waits on a prompt
- `.local/bin/zellij-help` — the key guide, opened by `Alt /`
- `.local/bin/zellij-tab-state` — shows each Claude Code session's state in its tab name (hooks below)

Keys and bar adapted from [claude-zellij-workspace](https://github.com/erickPaar/claude-zellij-workspace), without czw.

**Locked is the resting mode**: every key goes to the program inside (Claude Code, nvim). Only `Alt` keys are zellij's:

| Keys | Action |
|---|---|
| `Alt 1` … `Alt 9` | Go to tab 1 … 9 (the number in the bar) |
| `Alt 0` | Previous tab |
| `Alt h` / `Alt l` | Pane or tab on the left / right |
| `Alt g` | Command mode: one key, then locked again (`t` tabs, `p` panes, `s` scroll, `/` search, `e` scrollback in editor, `f` fullscreen, `o` session, `d` detach, `?` guide, `Esc`) |
| `Alt /` | The key guide, in a floating pane |

The bar (top): the mode on the left, with that mode's keys; the tabs centered; on the right, how many
sessions need you and are done, the session and the clock. Needs a Nerd Font in the terminal (MesloLGS NF).

**Claude Code tab markers**: a tab shows `◐ name` while Claude works, `● name` when it needs you (a permission
prompt or a question; it also rings the bell, which Windows Terminal can turn into a taskbar flash with
`"bellStyle": ["window", "taskbar"]`), and `✓ name` when it's done. Add to the `hooks` in `~/.claude/settings.json`:

```json
"SessionStart":     [{ "hooks": [{ "type": "command", "command": "\"$HOME/.local/bin/zellij-tab-state\" clear 2>/dev/null || true", "timeout": 5 }] }],
"UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "\"$HOME/.local/bin/zellij-tab-state\" working 2>/dev/null || true", "timeout": 5 }] }],
"PostToolUse":      [{ "matcher": "*", "hooks": [{ "type": "command", "command": "\"$HOME/.local/bin/zellij-tab-state\" unblock 2>/dev/null || true", "timeout": 5, "async": true }] }],
"Notification":     [{ "hooks": [{ "type": "command", "command": "\"$HOME/.local/bin/zellij-tab-state\" attention 2>/dev/null || true", "timeout": 5 }] }],
"Stop":             [{ "hooks": [{ "type": "command", "command": "\"$HOME/.local/bin/zellij-tab-state\" done 2>/dev/null || true", "timeout": 5 }] }],
"SessionEnd":       [{ "hooks": [{ "type": "command", "command": "\"$HOME/.local/bin/zellij-tab-state\" clear 2>/dev/null || true", "timeout": 5 }] }]
```

Changing an existing session to the new bar: a running tab keeps the bars it was created with, and
`zellij action override-layout` can drop panes when a session has several tabs. Start the session fresh
instead (`zellij delete-session NAME --force`, then `zellij attach -c NAME`).

### i3 Window Manager
Central configs and recovery scripts for a bulletproof i3 setup:

- `i3/config` — main keybindings, workspaces, appearance
- `i3/postswitch.sh` — unified monitor change handler (compositor, polybar, keyboard, cursor, wallpaper)
- `i3/fix-keyboard.sh` — re-applies `br,us` layout with Alt+Shift toggle
- `i3/flatten.sh` — flattens the current workspace (resets container nesting)
- `i3/center-mouse.sh` — warps mouse to focused window center on keyboard focus
- `i3/gather-workspaces.sh` — gathers all workspaces to the current monitor (after unplug)
- `i3/move-workspace.sh` — moves current workspace between monitors with compositor restart (prevents ghosting)
- `i3status/config` — fallback status bar config (polybar is primary)

### Polybar
- `polybar/config.ini` — Tokyo Night themed status bar with PipeWire/battery/wifi/layout modules
- `polybar/launch.sh` — multi-monitor launch script with timeout and fallback
- `polybar/layout.sh` — shows current container layout (H-Split, V-Split, Tabbed, Stacked)
- `polybar/scripts/bluetooth-status.sh` — bluetooth indicator: red (service down), grey (off), cyan (idle), green with device name (connected)
- `polybar/scripts/awsvpn-status.sh` — AWS VPN connection status
- `polybar/scripts/1password-status.sh` — 1Password agent status

Polybar click handlers route through scripts in `i3/`:
- BT module → left: `blueman-manager`, right: `i3/bluetooth-toggle.sh` (power toggle)
- AWS VPN module → left: `i3/awsvpn-toggle.sh`
- 1Password module → left: `i3/1password-toggle.sh`

### Compositor
- `picom/picom.conf` — kept for reference. Currently using xcompmgr (lighter on Intel Raptor Lake iGPU)

### Application Launcher
- `rofi/config.rasi` — Tokyo Night themed Rofi launcher

### Notifications
- `dunst/dunstrc` — Tokyo Night themed notification daemon

### AirPods (LibrePods + snixembed)

ANC switching, ear-detection auto-pause, and per-pod battery on Linux. Not chezmoi-tracked (binaries live in `~/bin/` and `~/.local/share/`), but the i3/polybar wiring is:

- `i3/config` → autostarts `snixembed --fork` (must come before any tray app) and `~/bin/librepods`
- `i3/bluetooth-toggle.sh` — polybar right-click power toggle
- `polybar/scripts/bluetooth-status.sh` — polybar indicator

**snixembed** (`~/.local/bin/snixembed`) bridges modern `StatusNotifierItem` apps to polybar's older XEmbed tray. Not packaged for Ubuntu — built from source:
```bash
sudo apt install valac libgtk-3-dev libdbusmenu-gtk3-dev
git clone https://git.sr.ht/~steef/snixembed /tmp/snixembed
cd /tmp/snixembed && make && cp snixembed ~/.local/bin/
```

**LibrePods** (`~/bin/librepods` → wrapper around `~/.local/share/librepods/AppRun`). The Rust rewrite ships only as an AppImage from `ci-linux-rust.yml` CI artifacts. Ubuntu 24.04 dropped `libfuse2` so the AppImage is extracted, not run directly:
```bash
gh run download <LATEST_RUN_ID> --repo kavishdevar/librepods --name librepods-x86_64.AppImage
chmod +x librepods-x86_64.AppImage
./librepods-x86_64.AppImage --appimage-extract
mv squashfs-root ~/.local/share/librepods
```
The launcher wrapper at `~/bin/librepods` forces `LIBGL_ALWAYS_SOFTWARE=1 WGPU_BACKENDS=gl` — Iced/wgpu ghosts on Intel + NVIDIA Optimus without it.

Pair AirPods via `blueman-manager` (left-click the polybar BT indicator). LibrePods picks them up automatically once paired.

### Monitor Management (autorandr)
Three profiles with symlinked postswitch scripts (all point to `i3/postswitch.sh`):
- `autorandr/mobile/` — laptop only (eDP-1)
- `autorandr/home/` — external monitor on the left of laptop
- `autorandr/work/` — external monitor above laptop

## Desktop environment

Tokyo Night color scheme across all components:

| Component | Tool | Notes |
|-----------|------|-------|
| Window manager | i3wm | Gaps, vim-style navigation, container tree model |
| Status bar | Polybar | Layout indicator, keyboard, battery, wifi, CPU, memory, audio |
| Compositor | xcompmgr | Lightweight shadows (picom caused high CPU on Intel iGPU) |
| Launcher | Rofi | App launcher and window switcher |
| Notifications | Dunst | Styled notification popups |
| Terminal | WezTerm | GPU-accelerated, Tokyo Night theme |
| Shell prompt | Starship | Git/Kotlin/Java context, right-aligned duration + clock |
| Multiplexer | Zellij | Persistent sessions, modal keybinds, layout templates |
| Wallpaper | feh | Wallpapers in `~/Pictures/Wallpapers/` |
| Monitors | autorandr | Auto-switches profiles on plug/unplug |
| Audio | PipeWire | Volume keys via `wpctl` |
| Bluetooth | BlueZ + blueman | GUI via `blueman-manager`; polybar indicator + power toggle |
| Tray bridge | snixembed | StatusNotifierItem → XEmbed for polybar (Vala, built from source) |
| AirPods | LibrePods (Rust) | ANC modes, ear detection, battery — software rendering forced for Optimus |

### Dependencies

```bash
sudo apt install i3 polybar xcompmgr rofi dunst feh autorandr xdotool wireplumber \
                 blueman valac libgtk-3-dev libdbusmenu-gtk3-dev
```

(The last three are build deps for `snixembed`; see the AirPods section.)

Zellij isn't in apt — install from the official GitHub release:
```bash
curl -fsSL https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz \
  | tar -xz -C /tmp && install -m 0755 /tmp/zellij ~/.local/bin/zellij
```

Starship (shell prompt) — install the binary, then add the init hook to `.bashrc` (already wired in this repo's `.bashrc`):
```bash
curl -sS https://starship.rs/install.sh | sh
# .bashrc: eval "$(starship init bash)"
```

### Essential keybindings

| Key | Action |
|-----|--------|
| `$mod+Return` | Open terminal |
| `$mod+d` | App launcher (Rofi) |
| `$mod+h/j/k/l` | Focus left/down/up/right |
| `$mod+Shift+h/j/k/l` | Move window |
| `$mod+1-0` | Switch workspace |
| `$mod+w` | Tab siblings |
| `$mod+e` | Untab / toggle H/V |
| `$mod+v` / `$mod+b` | Next window opens below/right |

### Wezterm keybindings (subset)

| Key | Action |
|-----|--------|
| `Ctrl+Alt+H` / `Ctrl+Alt+L` | Previous / next wezterm tab |
| `Ctrl+Shift+H/J/K/L` | Wezterm pane direction |
| `Ctrl+Shift+D` / `Ctrl+Shift+R` | Wezterm pane split horizontal / vertical |
| `Ctrl+Shift+W` | Close wezterm pane |

### Zellij keybindings

| Key | Action |
|-----|--------|
| `Alt+p` then `n / r / d / x` | PANE mode — new / split right / split down / close |
| `Ctrl+T` then `n / 1-9` | TAB mode — new tab / jump to tab |
| `Alt+h` / `Alt+l` | Zellij tab prev / next |
| `Alt+arrow` | Pane focus (crosses tab edge — MoveFocusOrTab) |
| `Ctrl+S` then `j/k/PgUp/PgDn` | SCROLL mode |
| `Alt+o` then `d` | SESSION mode → detach |
| `Ctrl+G` | LOCKED — pass every key through to the inner program |
| `Ctrl+Q` | Quit zellij and kill the session (use detach instead) |

### Recovery keybindings

| Key | Action |
|-----|--------|
| `$mod+Shift+f` | Flatten workspace (fix nesting) |
| `$mod+Shift+p` | Relaunch polybar (fix missing bar) |
| `$mod+Ctrl+k` | Re-apply keyboard layout (fix Alt+Shift) |
| `$mod+o` | Move workspace to other monitor |
| `$mod+Shift+o` | Gather all workspaces to current monitor |

### Keyboard layouts

`br,us` with Alt+Shift toggle. System-level fix applied to `/etc/default/keyboard` so the setting persists across X11 events.

### Touchpad

Tap-to-click and natural scrolling enabled via `xinput` in the i3 config. Device name is hardcoded — adjust for different laptops.

### Audio (PipeWire)

Volume keys use `wpctl` (not `pactl`):
```
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
```

### Monitor profiles

Autorandr manages three profiles — saved by monitor EDID (hardware fingerprint), auto-detected on plug/unplug:

- **mobile** — laptop only
- **home** — external monitor to the left
- **work** — external monitor above

Save a new profile after configuring with `xrandr`:
```bash
autorandr --save <profile-name> --force
```

All profiles share the same postswitch hook (`i3/postswitch.sh`) that restarts the compositor, relaunches polybar, restores the keyboard layout, fixes the cursor, and restores the wallpaper.

## Documentation

Interactive guides in `~/Documents/`, grouped by tool:

`~/Documents/i3/`:
- `i3.html` — i3wm entry point
- `i3-cheatsheet.html` — i3 keybindings, containers, concepts, desktop
- `i3-concepts.html` — i3 container tree model with SVG diagrams
- `i3-practice.html` — i3 interactive lessons (learn by manipulating a simulated tree)

`~/Documents/zellij/`:
- `zellij.html` — zellij entry point
- `zellij-cheatsheet.html` — zellij modes, CLI, config, layouts, sessions
- `zellij-concepts.html` — sessions/tabs/panes hierarchy, mode state machine, persistence model, key-conflict analysis
- `zellij-practice.html` — zellij interactive lessons (drive a simulated session)

Terminal helpers:
- `i3tree` — prints the container tree with focus markers (installed in `~/bin/`)

## Install

```bash
chezmoi init https://github.com/erickPaar/dotfiles.git
chezmoi diff    # review changes
chezmoi apply   # apply to home directory
```

On first `init` chezmoi asks for this machine's git email and keeps it in
`~/.config/chezmoi/chezmoi.toml`, so no email is stored in this repo.

## WSL

On WSL (detected from the kernel release) `.chezmoiignore` skips the X11 desktop
(i3, polybar, picom, rofi, dunst, autorandr, autostart, `.xinputrc`) and `.wezterm.lua`,
which belongs in the Windows home instead. Tools without sudo go to `~/.local/bin`
(starship, eza, fd as `fdfind`, git-lfs).

## Update

```bash
chezmoi update
```

## Add new files

```bash
chezmoi add ~/.some-config
cd $(chezmoi source-path) && git add -A && git commit -m "feat: add some-config" && git push
```
