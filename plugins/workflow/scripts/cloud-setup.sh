#!/bin/bash
# Setup script for the cloud environment: paste it into claude.ai/code → the environment → Setup
# script. It runs as root before Claude Code starts, and the result is cached with the environment.
# Cloud sessions don't install the plugins a repo enables, but they load a plugin folder placed under
# ~/.claude/skills/ as <name>@skills-dir. This puts the workflow plugin and Anthropic's security
# plugins there.
# It always exits 0: a failed fetch leaves the session without a plugin, never without a session.
set -uo pipefail

DEST=~/.claude/skills
mkdir -p "$DEST"

# install <owner/repo> <plugin folder in the repo>...
install() {
  local repo=$1; shift
  local src; src=$(mktemp -d)
  # 1. A sparse clone. The VM's GitHub proxy may refuse a repository the session doesn't have attached.
  # 2. Else the file list from the API, each file from raw.githubusercontent.com.
  if ! { timeout 120 git clone -q --depth 1 --filter=blob:none --sparse "https://github.com/$repo" "$src/repo" 2>/dev/null &&
         git -C "$src/repo" sparse-checkout set "$@" 2>/dev/null; }; then
    rm -rf "$src/repo"
    local files
    files=$(curl -fsSL --max-time 60 "https://api.github.com/repos/$repo/git/trees/main?recursive=1" |
      python3 -c 'import json,sys; [print(t["path"]) for t in json.load(sys.stdin)["tree"]
        if t["type"]=="blob" and any(t["path"].startswith(p.rstrip("/")+"/") for p in sys.argv[1:])]' "$@" 2>/dev/null) || files=
    if [ -z "$files" ]; then echo "cloud-setup: could not fetch $repo"; rm -rf "$src"; return; fi
    while read -r f; do
      f=${f%$'\r'}
      mkdir -p "$src/repo/$(dirname "$f")"
      curl -fsSL --max-time 60 -o "$src/repo/$f" "https://raw.githubusercontent.com/$repo/main/$f" ||
        { echo "cloud-setup: could not fetch $repo/$f"; rm -rf "$src"; return; }
    done <<<"$files"
  fi
  for path in "$@"; do
    local name; name=$(basename "$path")
    if [ -f "$src/repo/$path/.claude-plugin/plugin.json" ]; then
      rm -rf "${DEST:?}/$name" && cp -r "$src/repo/$path" "$DEST/$name" && echo "cloud-setup: $name installed in $DEST"
    else
      echo "cloud-setup: $path not found in $repo"
    fi
  done
  rm -rf "$src"
}

install ztsia/workflow plugins/workflow
install anthropics/claude-plugins-official plugins/claude-security plugins/security-guidance

exit 0
