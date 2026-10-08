# Load secrets from 1Password ("Bash Secrets" item in "Dev" vault)
# Caches locally so only the first terminal needs fingerprint auth.
#   load_secrets           — loads from cache; auto-refreshes if cache older than TTL
#   load_secrets refresh   — force re-fetch from 1Password and update cache
# TTL exists because a rotated secret is otherwise served stale forever
# (Jun 2026: a 3-week-old cache kept exporting a dead JIRA token).
_OP_CACHE="$HOME/.cache/op_secrets"
_OP_CACHE_TTL_DAYS=7

load_secrets() {
  local cache="$_OP_CACHE"

  if [[ "$1" != "refresh" ]] && [[ -f "$cache" ]]; then
    if [[ -n $(find "$cache" -mtime -"$_OP_CACHE_TTL_DAYS" 2>/dev/null) ]]; then
      source "$cache"
      return 0
    fi
    echo "[op_secrets] cache older than ${_OP_CACHE_TTL_DAYS}d — refreshing from 1Password…"
  fi

  if ! command -v op &>/dev/null; then
    echo "[warn] 1Password CLI not installed — secrets not loaded"
    [[ -f "$cache" ]] && source "$cache"
    return 1
  fi

  mkdir -p "$(dirname "$cache")"
  local tmp="${cache}.tmp.$$"
  if op item get 'Bash Secrets' --vault=Dev --format=json 2>/dev/null \
      | jq -r '.fields[] | select(.value != null and .value != "") | "export \(.label)=\(.value | @sh)"' \
      > "$tmp" && [[ -s "$tmp" ]]; then
    chmod 600 "$tmp"
    mv "$tmp" "$cache"
  else
    rm -f "$tmp"
    echo "[warn] op_secrets refresh failed — keeping previous cache (secrets may be stale)"
  fi
  [[ -f "$cache" ]] && source "$cache"
}

if command -v op &>/dev/null || [[ -f "$_OP_CACHE" ]]; then
  load_secrets
fi

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# bun
export BUN_INSTALL="$HOME/.bun"
PATH="$BUN_INSTALL/bin:$PATH"

# Additional paths
path_extras=(
  "$HOME/.local/bin"
  "/usr/local/go/bin"
  "/opt/nvim-linux-x86_64/bin"
  "$HOME/.pulumi/bin"
  "$HOME/dev/tools/jira-cli"
)

for p in "${path_extras[@]}"; do
  [[ -d "$p" ]] && PATH="$PATH:$p"
done
export PATH

[[ -d "$HOME/.terraform.d/plugin-cache" ]] && export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

# WSL: open links in the Windows browser
if [[ -n "$WSL_DISTRO_NAME" ]]; then
  export BROWSER=wslview
fi
