#!/usr/bin/env bash
# SessionStart hook (.claude/settings.json). Points a session at the handoff and, in a cloud session,
# names the newest unmerged slice branch whose handoff differs from main's. Copy it into a project's
# scripts/ and add the project's own setup at the end (installs, a local database).
# It never fails the session: a broken step should surface when a command runs, not at startup.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 0

# The handoff comes first for every session, local or cloud (CLAUDE.md, Session rotation).
[ -f docs/handoff.md ] && echo "Read docs/handoff.md before anything else, and rewrite it before you end."

# Everything below is cloud only. A local machine manages its own installs.
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0

# A slice handed off mid-way lives on its unmerged branch, B<NN>/<brief> (CLAUDE.md, One brief, one
# branch). Name the newest one whose handoff differs from main's, as a safety net: the owner's
# message names the branch to continue from. The harness's claude/* branches are checked too.
if timeout 60 git fetch -q origin main '+refs/heads/B*:refs/remotes/origin/B*' \
    '+refs/heads/claude/*:refs/remotes/origin/claude/*' 2>/dev/null; then
  for ref in $(git for-each-ref --sort=-committerdate --format='%(refname:short)' \
      'refs/remotes/origin/B[0-9][0-9]/' refs/remotes/origin/claude/); do
    git merge-base --is-ancestor "$ref" origin/main 2>/dev/null && continue
    git diff --quiet origin/main..."$ref" -- docs/handoff.md 2>/dev/null && continue
    echo "A newer handoff is on $ref ($(git log -1 --format=%cr "$ref")). If you're continuing a slice, read it there."
    break
  done
fi

# Project dependencies: install once per fresh VM. Replace with the project's own package manager.
if [ -f pnpm-lock.yaml ] && [ ! -d node_modules ]; then
  pnpm install --frozen-lockfile >/tmp/session-install.log 2>&1 \
    || echo "session-start: pnpm install failed, see /tmp/session-install.log"
elif [ -f package-lock.json ] && [ ! -d node_modules ]; then
  npm ci >/tmp/session-install.log 2>&1 || echo "session-start: npm ci failed, see /tmp/session-install.log"
fi

exit 0
