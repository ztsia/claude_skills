#!/usr/bin/env bash
# TEMPLATE. Copy to scripts/session-setup.sh. The project's own SessionStart hook (.claude/settings.json):
# what a fresh cloud VM needs before work starts. The workflow plugin's hook already loads the rules
# and points at the handoff. Replace the installs with the project's own (package manager, a local
# database). It never fails the session: a broken step should surface when a command runs.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 0

# A local machine manages its own installs.
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0

if [ -f pnpm-lock.yaml ] && [ ! -d node_modules ]; then
  pnpm install --frozen-lockfile >/tmp/session-install.log 2>&1 \
    || echo "session-setup: pnpm install failed, see /tmp/session-install.log"
elif [ -f package-lock.json ] && [ ! -d node_modules ]; then
  npm ci >/tmp/session-install.log 2>&1 || echo "session-setup: npm ci failed, see /tmp/session-install.log"
fi

exit 0
