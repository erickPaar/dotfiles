# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Personal bash configuration files sourced by `~/.bashrc`. These files define shell aliases, environment variables, PATH extensions, and custom shell functions.

## Structure

- `.aliases.sh` - Shell aliases (exa for ls, clipboard via xclip, tool launchers)
- `.exports.sh` - Environment variables, PATH additions, and 1Password secret loading
- `.functions.sh` - Loader that sources all files from `.bash_functions/*.sh`
- `.bash_functions/` - Modular function files:
  - `process.sh` - Process inspection (`psf`, `pscmd`)
  - `search.sh` - Multi-pattern ripgrep wrappers (`rgand`, `rgor`)
  - `datadog.sh` - Datadog log/monitor CLI (`ddlogs`, `ddlog-send`, `ddmonitor`)

## How It's Loaded

`.functions.sh` auto-sources every `*.sh` file in `.bash_functions/`. To add new functions, create a new `.sh` file in that directory - no registration needed.

## Key Custom Commands

| Command | Purpose |
|---------|---------|
| `psf <name>` | Find processes by name with formatted output |
| `pscmd <pid>` | Show full command of a process, formatted |
| `rgand pat1 pat2 ...` | ripgrep lines matching ALL patterns |
| `rgor pat1 pat2 ...` | ripgrep lines matching ANY pattern |
| `ddlogs <query> [timeframe] [limit]` | Search Datadog logs |
| `ddlog-send <service> <message> [source] [tags]` | Send log to Datadog |
| `ddmonitor <subcommand>` | Full Datadog monitor management (list/get/create/update/delete/mute/search) |

## Secrets Management (1Password)

Secrets are stored in 1Password, not in plaintext. The `load_secrets` function in `.exports.sh` fetches all fields from the **"Bash Secrets"** item in the **"Dev"** vault and caches them to `~/.cache/op_secrets` (permissions `600`).

- **Requires**: 1Password desktop app with CLI integration enabled (Settings → Developer → Integrate with 1Password CLI)
- **First terminal after boot**: authenticates via fingerprint, fetches secrets, caches locally
- **Subsequent terminals**: loads from cache instantly, no auth needed
- **Add a secret**: `op item edit "Bash Secrets" --vault=Dev 'NEW_VAR=value'`, then `load_secrets refresh`
- **Reload after changes**: `load_secrets refresh` (re-fetches from 1Password and updates cache)
- Non-secret config (ports, hostnames, paths) stays as plain `export` in `.exports.sh`
- Never add secrets as plaintext exports — always add them to the 1Password item
