# hikari: the desktop as a server

`hikari` is the desktop: a Windows PC whose Ubuntu (WSL) runs as a server. You reach it from the laptop over Tailscale and use it from a terminal: zellij sessions, Claude Code, long jobs. They keep running when the laptop disconnects.

| Name on the tailnet | What it is |
|---|---|
| `hikari` | The desktop's Windows side (Remote Desktop) |
| `hikari-wsl` | The desktop's Ubuntu (SSH, zellij, Claude Code) |

The `hikari` command (`~/.local/bin/hikari`, from this repo) wraps all of it.

---

## Daily use

```bash
hikari              # open the zellij session "main" on the desktop, or reopen it
hikari blog         # a separate session called "blog"
hikari ls           # the desktop's zellij sessions
```

Inside the session, start Claude Code in a project folder:

```bash
cd ~/Development/projects/<project>
claude
```

To leave everything running, press `Alt+o`, then `d` (detach). Later, `hikari` puts you back exactly where you were, with Claude still mid-task if it was working.

If the laptop's Wi-Fi drops, nothing on the desktop stops. Run `hikari` again once you're back online.

### zellij keys

Both machines use this repo's zellij config (`dot_config/zellij/config.kdl.tmpl`), so the keys are the same on each. Every key goes to the program inside (Claude Code) except these:

| Keys | Action |
|---|---|
| `Alt /` | Key guide (floating; any key closes it) |
| `Alt 1` … `Alt 9` | Go to that tab (the number in the bar) |
| `Alt h` / `Alt l` | Pane or tab left / right |
| `Alt g`, then `d` | Detach (leave the session running) |
| `Alt g`, then `t`, `n` | New tab (`r` rename, `x` close) |
| `Alt g`, then `p`, `r` / `d` | Split pane right / down |
| `Alt g`, then `s` | Scroll mode (`j`/`k`, `PgUp`/`PgDn`, `s` search, `Esc` to leave) |

The bar at the top shows the mode and its keys on the left, the tabs in the middle, and on the right how many Claude sessions need you (`●`) or are done (`✓`). The same markers appear in the tab names, with `◐` while Claude works.

> **zellij inside zellij.** If you run `hikari` from a laptop terminal that is itself in zellij, the laptop's zellij catches the `Alt` keys first. Run `hikari` from a terminal tab that isn't in zellij.

The desktop's copy of the config leaves out `copy_command`. Text you copy in its zellij then travels through the terminal (OSC 52) to the laptop's clipboard; `xclip` on the desktop couldn't reach it over SSH.

---

## Sending a screenshot to Claude on the desktop

Image paste doesn't work in a Claude session on the desktop. Claude reads the clipboard of the machine it runs on, and SSH only carries text.

1. On the laptop, press `Win+Shift+S` and select the area. That copies it as an image.
2. In a laptop terminal, run `hikari paste`. The image is saved as a PNG in the desktop's `~/inbox`, and its path replaces the image on your clipboard.
3. In the desktop's Claude session, press `Ctrl+V` to paste the path, and ask about it.

It works for files too: select them in Explorer, press `Ctrl+C`, then run `hikari paste`. They keep their names, with the date and time in front.

---

## Other ways in

| Need | How |
|---|---|
| A plain shell | `ssh hikari` |
| The desktop's Windows screen | `mstsc /v:hikari` (Win+R). Log in with the Windows account's password; a PIN doesn't work over Remote Desktop. |
| A web app running on the desktop | `hikari tunnel 3000`, then open `http://localhost:3000` on the laptop |
| VS Code | The Remote - SSH extension. Add a `Host hikari` entry to **Windows'** `~\.ssh\config` (VS Code reads that one, not WSL's), then connect to `hikari`. |
| Big folders | `rsync -rth --partial --info=progress2 <src>/ hikari:<dest>/`. Run it again to resume. Add `-c -n` for a dry run that compares by checksum. |

---

## Setup (once)

**On the desktop**, in Ubuntu:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh --hostname hikari-wsl
```

Keep WSL running without a window open: add a Windows Task Scheduler task that runs at startup and starts WSL with a long-running command. Also set Windows' sleep to **Never**.

**On the laptop:**

```bash
hikari setup <your-linux-user-on-the-desktop>
```

That adds a `Host hikari` entry to `~/.ssh/config` and tests the login. Apply this repo on the desktop too (`chezmoi init --apply erickPaar/dotfiles`), so both machines share the zellij config, bar and keys. The config template leaves out `copy_command` on the desktop by itself.

---

## When something's wrong

| What you see | What to do |
|---|---|
| `hikari-wsl is offline` | The desktop is asleep or off, or its WSL isn't running. Connect with Remote Desktop to check, or wake the PC. |
| `hikari-wsl is not on your tailnet` | Run the desktop setup above. |
| `Tailscale SSH requires an additional check` and a link | Open the link and approve. The command continues on its own. These approvals come from the SSH rule's `check` action in the tailnet's access controls. A longer `checkPeriod` makes them rarer. |
| After the desktop restarts | `hikari` reopens `main`. zellij restores the tabs and panes (`session_serialization`), and each pane's command waits for `Enter` before starting again. |
| A frozen terminal after a Wi-Fi drop | Wait about 90 seconds (`ServerAliveInterval 30`), or press `Enter`, `~`, `.` to close it at once. Then run `hikari`. |
