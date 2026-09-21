# `qa` — what it is and what it needs

Ported verbatim from `ztsia/GCO_events`. The skill itself is thin; the value is in the
`qa-reviewer` subagent and the disposable-database arrangement around it, so all the moving
parts are here rather than the `SKILL.md` alone.

## Files, and where they must live in a consuming project

| File | Required | Why |
|---|---|---|
| `.claude/skills/qa/SKILL.md` | yes | The skill. Sets up the run and hands off. |
| `.claude/agents/qa-reviewer.md` | yes | The subagent the skill spawns. Without it the skill is inert. |
| `scripts/qa-db.sh` | yes | Drops and recreates the disposable QA database. |
| `scripts/db-extensions.sql` | yes | Sourced by `qa-db.sh`. |
| `scripts/session-start.sh` | yes | `qa-db.sh` calls it when Postgres is not already up. |
| `scripts/local-db.sh` | yes | Started by `session-start.sh`. |
| `scripts/qa-report.mjs` | yes | Renders `results.json` + PNGs into one self-contained `report.html`. |
| `playwright.config.ts` | for the browser phase | Repo root. Single worker on purpose. |

Paths are the ones `SKILL.md` and the agent hard-code, so copying this tree over a project
resolves as-is.

## Not portable without edits

The port is faithful, which also means it is still GCO-shaped. Before using it elsewhere:

- **Spec layout.** The agent's only source of truth is `docs/spec/`, and the skill reads the
  module row from `docs/modules.md` §3. A project without those files needs those two pointers
  rewritten.
- **Domain non-negotiables.** `claim_seats()`, blast idempotency, template pinning and the
  check-in manifest authorization check are named throughout as the Blocker criteria. Replace
  with the consuming project's own.
- **Stack.** `pnpm`, local Postgres 16 on port 55432, `gco_qa` as the database name, Chromium 141
  with `@playwright/test` pinned to 1.56.1, `qa/e2e` as the test directory.
- **Test suites not included.** `qa/backend/` and `qa/e2e/` in the source repo are GCO test code,
  not part of the skill.
