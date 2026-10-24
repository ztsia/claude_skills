---
name: setup
description: Set a project up for the workflow plugin, or move a project that has its own copies of the workflow's agents, skills and scripts onto the plugin. Run by the owner as /workflow:setup.
disable-model-invocation: true
---

# Set a project up for the workflow

The plugin's files are in `${CLAUDE_PLUGIN_ROOT}`; its templates are in `templates/` there. Work on a
branch of its own (`workflow/setup`), never on a slice's branch, and open one PR. Read what the
project already has before writing anything, and never overwrite a file the project wrote: merge
into it.

## A new project

1. **`CLAUDE.md`** from `templates/CLAUDE.md`. Fill in what the repo and the owner have already
   said; leave the other `<…>` parts for the design sessions.
2. **`.claude/settings.json`**: merge in `templates/settings.json` (keep every key the project has).
   It enables `workflow@ztsia`, keeps `security-guidance` to its edit warnings and commit reviews
   (`ENABLE_STOP_REVIEW=0`) and runs the project's own `scripts/session-setup.sh`.
3. **`scripts/session-setup.sh`** from `templates/scripts/session-setup.sh`, with the project's own
   package manager and setup in place of the template's installs.
4. **`.claude/claude-security-guidance.md`** from `templates/claude-security-guidance.md`.
5. **QA's tooling**, once the project has a test suite: `templates/qa/*` into `qa/`, and
   `templates/scripts/mutants.mjs` into `scripts/`. Each file's header says how to adapt it.
   `templates/api/` holds examples (a route table, `Server-Timing` middleware) for a project with an
   API; the `database` skill says when to use them.
6. **`docs/`**, each only if missing:
   - `handoff.md`: *Where things stand*, *Decided*, *Open with the owner*, *Do first*, *Settled*.
   - `decisions.md`: a heading and an empty numbered list (D1, D2, …).
   - `local.md`: the queue of what only the owner can do, starting with the two steps below.
   - `cloud.md`: what a cloud session has and can reach, empty until measured.
7. **`.gitignore`**: add `qa-artifacts/`.
8. **Queue for the owner** in `docs/local.md`, with steps a phone can follow:
   - on each machine, once: `claude plugin install claude-security@claude-plugins-official` and
     `claude plugin install security-guidance@claude-plugins-official`
   - at claude.ai/code, for the project's cloud environment: paste
     `${CLAUDE_PLUGIN_ROOT}/scripts/cloud-setup.sh` into its setup script. Cloud sessions don't
     install the plugins a repository enables; this script places them where a session loads them.

## A project with its own copies

A project set up before the plugin has the workflow's files copied into it. Both copies load (a
plugin's agents and skills are namespaced, so `qa` and `workflow:qa` sit side by side), so the old
ones go. Move a project only between slices, never on a slice's branch.

1. **Agents and skills.** For each of `.claude/agents/{implementer,qa-reviewer,qa-eyes,scout}.md` and
   `.claude/skills/{qa,uiux,database,llm,security}/`, compare it with the plugin's version:
   `git diff --no-index <project copy> "${CLAUDE_PLUGIN_ROOT}/<agents|skills>/<name>"`. Sort each
   difference:
   - **true of this project only** (its stack, its patterns, a rule it chose): into
     `docs/workflow/<skill>.md`, one line each, saying what it adds or overrides
   - **a refreshed note newer than the plugin's** (a vendor, stack or component doc whose
     `last_checked` is later): to `docs/workflow/<skill>/<same path>`
   - **an improvement for every project**: a line in `docs/local.md` to open a PR to `ztsia/workflow`
     with it
   - **older than the plugin's**: dropped

   Then delete the project's copies, and `.claude/skills/dataflow/`, which the workflow no longer
   uses. Keep any other agent or skill the plugin doesn't have.
2. **`CLAUDE.md`.** Delete the parts the plugin's rules now hold: *Session rotation*, *Models and
   subagents*, the owner's general rules, the general conventions and the *Skills* table. Keep the
   project's own facts, in `templates/CLAUDE.md`'s sections. Where the project departs from the
   rules, write it under *Overrides*, with the decision that chose it.
3. **Scripts.** `scripts/usage.mjs` and `scripts/qa-report.mjs` are the plugin's now: delete them,
   and point any project doc that runs them at `node "${CLAUDE_PLUGIN_ROOT}/scripts/<name>"`. Keep
   the project's part of `scripts/session-start.sh` (its installs, a local database) as
   `scripts/session-setup.sh`, and delete the rest; the plugin's hook loads the rules, points at the
   handoff and names the newest slice branch. Keep `scripts/mutants.mjs` and `qa/`.
4. **`.claude/settings.json`**: merge in `templates/settings.json`, replacing the old hook that ran
   `scripts/session-start.sh`.
5. **Check:** start a fresh session in the project and confirm it opens with the workflow rules, that
   `/agents` lists `workflow:implementer`, and that the old names are gone. Say in the PR what moved
   where.
