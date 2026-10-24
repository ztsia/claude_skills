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

# The files of one plugin folder, one path per line relative to the repo, by the routes the VM's
# GitHub proxy allows for a repository the session doesn't have attached: raw.githubusercontent.com
# always; api.github.com only for an attached or allowed one.
list_files() { # <repo> <path>
  local list
  if list=$(curl -fsSL --max-time 60 "https://raw.githubusercontent.com/$1/main/$2/files.txt" 2>/dev/null); then
    sed -e 's/\r$//' -e '/^$/d' -e "s|^|$2/|" <<<"$list"
    return
  fi
  curl -fsSL --max-time 60 "https://api.github.com/repos/$1/git/trees/main?recursive=1" 2>/dev/null |
    python3 -c 'import json,sys; [print(t["path"]) for t in json.load(sys.stdin)["tree"]
      if t["type"]=="blob" and t["path"].startswith(sys.argv[1].rstrip("/")+"/")]' "$2" 2>/dev/null
}

# install <owner/repo> <plugin folder in the repo>...
install() {
  local repo=$1; shift
  local src; src=$(mktemp -d)
  # 1. A sparse clone. 2. Else each file from raw.githubusercontent.com.
  if timeout 120 git clone -q --depth 1 --filter=blob:none --sparse "https://github.com/$repo" "$src/repo" 2>/dev/null &&
     git -C "$src/repo" sparse-checkout set "$@" 2>/dev/null; then
    echo "cloud-setup: $repo cloned"
  else
    rm -rf "$src/repo"
    echo "cloud-setup: $repo clone failed, fetching its files one by one"
    local path f files
    for path in "$@"; do
      files=$(list_files "$repo" "$path")
      [ -n "$files" ] || { echo "cloud-setup: no file list for $repo/$path"; continue; }
      while read -r f; do
        mkdir -p "$src/repo/$(dirname "$f")"
        curl -fsSL --max-time 60 -o "$src/repo/$f" "https://raw.githubusercontent.com/$repo/main/$f" ||
          { echo "cloud-setup: could not fetch $repo/$f"; rm -rf "$src/repo/$path"; break; }
      done <<<"$files"
    done
  fi
  for path in "$@"; do
    local name; name=$(basename "$path")
    if [ -f "$src/repo/$path/.claude-plugin/plugin.json" ]; then
      rm -rf "${DEST:?}/$name" && cp -r "$src/repo/$path" "$DEST/$name" &&
        echo "cloud-setup: $name $(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$DEST/$name/.claude-plugin/plugin.json" | head -1) installed in $DEST"
    else
      echo "cloud-setup: $path not found in $repo"
    fi
  done
  rm -rf "$src"
}

install ztsia/workflow plugins/workflow
install anthropics/claude-plugins-official plugins/claude-security plugins/security-guidance

exit 0
