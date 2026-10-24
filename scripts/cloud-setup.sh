#!/bin/bash
# Setup script for the cloud environment: paste it into claude.ai/code → the environment → Setup
# script. It runs as root before Claude Code starts, and the result is cached with the environment.
# Cloud sessions don't install the plugins a repo enables, but they load a plugin folder placed under
# ~/.claude/skills/ as <name>@skills-dir. This puts Anthropic's security plugins there.
# It always exits 0: a failed fetch leaves the session without the plugins, never without a session.
set -uo pipefail

REPO=anthropics/claude-plugins-official
PLUGINS="claude-security security-guidance"
DEST=~/.claude/skills
SRC=$(mktemp -d)
mkdir -p "$DEST"

# 1. A sparse clone. The VM's GitHub proxy may refuse a repository the session doesn't have attached.
fetch_clone() {
  timeout 120 git clone -q --depth 1 --filter=blob:none --sparse "https://github.com/$REPO" "$SRC/repo" 2>/dev/null &&
    git -C "$SRC/repo" sparse-checkout set $(printf 'plugins/%s ' $PLUGINS) 2>/dev/null
}

# 2. The file list from the API, each file from raw.githubusercontent.com.
fetch_raw() {
  local files
  files=$(curl -fsSL --max-time 60 "https://api.github.com/repos/$REPO/git/trees/main?recursive=1" |
    python3 -c 'import json,sys; [print(t["path"]) for t in json.load(sys.stdin)["tree"]
      if t["type"]=="blob" and t["path"].split("/")[:2] in [["plugins",p] for p in sys.argv[1:]]]' $PLUGINS) || return 1
  [ -n "$files" ] || return 1
  while read -r f; do
    f=${f%$'\r'}
    mkdir -p "$SRC/repo/$(dirname "$f")"
    curl -fsSL --max-time 60 -o "$SRC/repo/$f" "https://raw.githubusercontent.com/$REPO/main/$f" || return 1
  done <<<"$files"
}

if fetch_clone || { rm -rf "$SRC/repo"; fetch_raw; }; then
  for p in $PLUGINS; do
    if [ -f "$SRC/repo/plugins/$p/.claude-plugin/plugin.json" ]; then
      rm -rf "${DEST:?}/$p" && cp -r "$SRC/repo/plugins/$p" "$DEST/$p" && echo "cloud-setup: $p installed in $DEST"
    else
      echo "cloud-setup: $p not found in $REPO"
    fi
  done
else
  echo "cloud-setup: could not fetch $REPO; the security plugins are not loaded"
fi

rm -rf "$SRC"
exit 0
