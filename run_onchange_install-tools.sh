#!/usr/bin/env bash
# Install the CLI tools these dotfiles expect into ~/.local, without sudo.
# chezmoi reruns this whenever the file changes; each tool is skipped when
# already present, so a rerun only adds what is missing.
#   FORCE=1 ~/.local/share/chezmoi/run_onchange_install-tools.sh   reinstalls everything
set -euo pipefail

BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$BIN" "$SHARE"

have() { [[ -z "${FORCE:-}" ]] && { command -v "$1" >/dev/null 2>&1 || [[ -x "$BIN/$1" ]]; }; }
step() { printf '\n==> %s\n' "$1"; }

# URL of the first asset of a repo's latest GitHub release matching a regex.
gh_asset() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    jq -r --arg re "$2" '[.assets[].browser_download_url | select(test($re))][0]'
}

# ---- shell ---------------------------------------------------------------
have chezmoi || { step chezmoi; sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BIN"; }
have starship || { step starship; curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$BIN" >/dev/null; }
have eza || { step eza; curl -fsSL "$(gh_asset eza-community/eza 'x86_64-unknown-linux-gnu\.tar\.gz$')" | tar -xz -C "$TMP" && install -m755 "$TMP/eza" "$BIN/"; }
have fdfind || { step fd; curl -fsSL "$(gh_asset sharkdp/fd 'x86_64-unknown-linux-gnu\.tar\.gz$')" | tar -xz -C "$TMP" && install -m755 "$TMP"/fd-*/fd "$BIN/fdfind"; }
have git-lfs || { step git-lfs; curl -fsSL "$(gh_asset git-lfs/git-lfs 'linux-amd64.*\.tar\.gz$')" | tar -xz -C "$TMP" && install -m755 "$TMP"/git-lfs-*/git-lfs "$BIN/"; }
have zellij || { step zellij; curl -fsSL https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz | tar -xz -C "$TMP" && install -m755 "$TMP/zellij" "$BIN/"; }

# ---- runtimes ------------------------------------------------------------
# Node 22 for Claude Code plugin hooks; the distro's node is often too old.
if [[ -n "${FORCE:-}" || ! -x "$SHARE/node22/bin/node" ]]; then
  step "node 22"
  v=$(curl -fsSL https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false and (.version | startswith("v22.")))][0].version')
  curl -fsSL "https://nodejs.org/dist/$v/node-$v-linux-x64.tar.xz" -o "$TMP/node.tar.xz"
  curl -fsSL "https://nodejs.org/dist/$v/SHASUMS256.txt" | grep " node-$v-linux-x64.tar.xz\$" | awk -v f="$TMP/node.tar.xz" '{print $1"  "f}' | sha256sum -c --quiet -
  rm -rf "$SHARE/node22" && mkdir -p "$SHARE/node22" && tar -xJf "$TMP/node.tar.xz" -C "$SHARE/node22" --strip-components=1
fi

# Go goes in ~/.local/share/go; .exports.sh puts its bin on PATH.
if [[ -n "${FORCE:-}" || ! -x "$SHARE/go/bin/go" ]]; then
  step go
  v=$(curl -fsSL 'https://go.dev/dl/?mode=json' | jq -r '.[0].version')
  sha=$(curl -fsSL 'https://go.dev/dl/?mode=json' | jq -r --arg f "$v.linux-amd64.tar.gz" '.[0].files[] | select(.filename == $f) | .sha256')
  curl -fsSL "https://go.dev/dl/$v.linux-amd64.tar.gz" -o "$TMP/go.tgz"
  echo "$sha  $TMP/go.tgz" | sha256sum -c --quiet -
  rm -rf "$SHARE/go" && tar -xzf "$TMP/go.tgz" -C "$SHARE"
fi

# Flutter stable in ~/.local/share/flutter; .exports.sh puts its bin on PATH.
if [[ -n "${FORCE:-}" || ! -x "$SHARE/flutter/bin/flutter" ]]; then
  step flutter
  base=https://storage.googleapis.com/flutter_infra_release/releases
  rel=$(curl -fsSL "$base/releases_linux.json" | jq -c '.current_release.stable as $h | .releases[] | select(.hash == $h)')
  curl -fsSL "$base/$(jq -r .archive <<<"$rel")" -o "$TMP/flutter.tar.xz"
  echo "$(jq -r .sha256 <<<"$rel")  $TMP/flutter.tar.xz" | sha256sum -c --quiet -
  rm -rf "$SHARE/flutter" && tar -xJf "$TMP/flutter.tar.xz" -C "$SHARE"
  "$SHARE/flutter/bin/flutter" --disable-analytics >/dev/null 2>&1 || true
  "$SHARE/flutter/bin/flutter" config --no-analytics >/dev/null 2>&1 || true
fi

# ---- language tooling ----------------------------------------------------
# uv; ruff, pyrefly and import-linter come per project from `uv run`.
have uv || { step uv; curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$BIN" UV_NO_MODIFY_PATH=1 sh >/dev/null; }
have golangci-lint || { step golangci-lint; curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b "$BIN" >/dev/null; }
have tflint || { step tflint; curl -fsSL "$(gh_asset terraform-linters/tflint 'tflint_linux_amd64\.zip$')" -o "$TMP/tflint.zip" && unzip -oq "$TMP/tflint.zip" -d "$TMP" && install -m755 "$TMP/tflint" "$BIN/"; }
have shellcheck || { step shellcheck; curl -fsSL "$(gh_asset koalaman/shellcheck 'linux\.x86_64\.tar\.xz$')" | tar -xJ -C "$TMP" && install -m755 "$TMP"/shellcheck-*/shellcheck "$BIN/"; }
have yq || { step yq; curl -fsSL "$(gh_asset mikefarah/yq 'yq_linux_amd64$')" -o "$TMP/yq" && install -m755 "$TMP/yq" "$BIN/"; }

# ---- cloud ---------------------------------------------------------------
if ! have aws; then
  step "aws cli"
  curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o "$TMP/aws.zip"
  unzip -oq "$TMP/aws.zip" -d "$TMP"
  "$TMP/aws/install" -i "$SHARE/aws-cli" -b "$BIN" --update >/dev/null
fi

# ---- Claude Code ---------------------------------------------------------
# czw: Claude Code sessions as zellij tabs (the settings hooks call it).
if ! have czw; then
  step czw
  src="$HOME/projects/claude-zellij-workspace"
  [[ -d "$src" ]] || git clone -q https://github.com/erickPaar/claude-zellij-workspace "$src"
  make -C "$src" install >/dev/null
fi

printf '\ntools ready\n'
