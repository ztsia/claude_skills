# claude_skills

Shared Claude Code skills, agents and workflow, taken from the projects that proved them (Sen's
build first). A project copies what it needs and keeps its own copy, so a change here never breaks a
project mid-slice.

## What's here

| Path | What it is |
|---|---|
| `CLAUDE.md` | The workflow template: handoff rotation, one brief one branch, the owner's rules, models and subagents (the main session as the brain, complete briefs, choosing a model per task), QA tiers. Fill in its `<…>` parts |
| `.claude/agents/implementer.md` | Carries out a batch already decided; Haiku at high effort by default, Sonnet when the main session judges the task needs it |
| `.claude/agents/qa-reviewer.md` | Independent QA: criteria from the spec first, the sweep's results, breakage checks and its own probes, database and RLS probes, what it costs, journeys with screenshots; spawns its helpers |
| `.claude/agents/qa-eyes.md` | The eyes pass: each changed screen and each tap's filmstrip, looked at as a person would, with fixed questions |
| `.claude/agents/scout.md` | Cheap Haiku lookups over long logs or unfamiliar code |
| `.claude/skills/qa/` | How a slice is QA'd: diff-driven and measured, mechanical checks first, the helpers' templates, the reviewer, escapes and the retro, the three fix tiers, the published report |
| `.claude/skills/uiux/` | shadcn/ui components, one set of shared patterns, calm card-based structure (what's primary, facts vs actions, a block per kind), the size hierarchy, and the phone-first checklist. Its shadcn docs are re-pulled from shadcn's repo by `scripts/refresh.mjs` once they're 90 days old or the project's components or base library differ |
| `.claude/skills/database/` | Data layer and backend security: RLS per request, on plain Postgres and on Supabase; every route in one table, swept |
| `.claude/skills/llm/` | Model calls in a product: prompts, checking an existing prompt, API errors, caching, cost, moving models, and evals (`docs/evals.md`), plus dated notes per vendor in `docs/vendors/` (Anthropic, OpenAI, Google) that a session refreshes from the official docs once they're 90 days old or a project calls a model they don't list |
| `.claude/skills/security/` | A product's own code without vulnerabilities: trust boundaries, access control per object, injection, XSS, secrets, uploads, SSRF, webhooks, abuse limits (`docs/web.md`), dependencies, secrets in the repo, CI and containers (`docs/supply-chain.md`), checking code and reporting a finding (`docs/review.md`), plus dated notes per stack in `docs/stacks/` (TypeScript, Python, Go). A session reads only the note for the stack it's working in, and refreshes it from the official docs once it's 90 days old |
| `.claude/claude-security-guidance.md` | The project's security rules, read by the `security-guidance` plugin's reviews. Add the project's own lines |
| `.claude/skills/dataflow/` | Client state |
| `.claude/settings.json`, `scripts/session-start.sh` | The SessionStart hook: points a session at the handoff and the newest slice branch. `ENABLE_STOP_REVIEW=0` keeps `security-guidance` to its edit warnings and commit reviews |
| `scripts/cloud-setup.sh` | The cloud environment's setup script: places Anthropic's `claude-security` and `security-guidance` plugins under `~/.claude/skills/`, where a cloud session loads them |
| `scripts/usage.mjs` | What a session cost, by agent and model, from the transcripts; `--log <slice>` keeps a row in `docs/usage.md` |
| `scripts/qa-report.mjs` | Renders QA's results into the report page the `qa` skill publishes |
| `templates/qa/` | Starting files for QA's tooling: `limits.ts` (judging metrics against human limits and main), `mutants.ts` (the breakage checks' shape), `escapes.md` (the escape log) |
| `templates/scripts/mutants.mjs` | Runs the breakage checks in a git worktree |
| `templates/api/` | A Hono API's route table (for the route sweep) and `Server-Timing` middleware, as examples |
| `examples/devpos-CLAUDE.md` | An earlier project's CLAUDE.md, for reference |

## Using it in a project

From the project's root:

```bash
git clone --depth 1 https://github.com/ztsia/claude_skills /tmp/claude_skills
mkdir -p .claude scripts
cp -r /tmp/claude_skills/.claude/agents /tmp/claude_skills/.claude/skills .claude/
cp /tmp/claude_skills/.claude/claude-security-guidance.md .claude/
cp /tmp/claude_skills/.claude/settings.json .claude/   # or merge its hook into yours
cp /tmp/claude_skills/scripts/*.mjs /tmp/claude_skills/scripts/*.sh scripts/
cp /tmp/claude_skills/CLAUDE.md CLAUDE.md               # then fill in the <…> parts
# QA's tooling starts from templates/: each file's header says how to adapt it
mkdir -p qa && cp /tmp/claude_skills/templates/qa/* qa/ && cp /tmp/claude_skills/templates/scripts/mutants.mjs scripts/
echo "qa-artifacts/" >> .gitignore
```

Then, in the project:
- Fill in `CLAUDE.md`: the project, its non-negotiables, stack, commands and layout.
- Create `docs/handoff.md`, `docs/decisions.md` and, when the build is sliced, `docs/modules.md` and
  `docs/briefs/`.
- Give the e2e setup an env var that writes each screenshot to a file (QA's sweep needs it).
- Tailor `uiux` and `database` to the project's stack in place, the way Sen did; keep the rules.
- Delete the `security` stack notes for stacks the project doesn't use, if you like; a session reads
  only the one it needs either way.
- Fill in `<security checks>` in `CLAUDE.md` from the stack note's *Checks to run*, and add it to CI.

The security plugins, once per machine and once per cloud environment:
- **Locally:** `claude plugin install claude-security@claude-plugins-official` and
  `claude plugin install security-guidance@claude-plugins-official` (user scope, the default).
- **In the cloud:** paste `scripts/cloud-setup.sh` into the environment's setup script at
  claude.ai/code. Cloud sessions don't install the plugins a repository enables, which is why the
  rest of the kit is plain files in `.claude/`; a plugin folder under `~/.claude/skills/` does load.

## Where the rules came from

Each rule here was measured or hit in a real build (Sen's, October 2026), and the reasoning travels
with it:

- **The main session is the brain.** The strongest model is there to think. When Sen's briefs
  asked only for correct data and states, the screens came back as plain lists of text, and the
  fault was the brief, not the model that built them. When the brief named what's primary on each
  screen and pointed at two finished reference screens, every model built well.
- **Haiku by default, at `high`.** The same brief ran on Sonnet and on Haiku, twice. Eight screens:
  Haiku $0.11 against Sonnet $1.12, comparable. Seventeen screens: Haiku $0.21 against Sonnet $3.43,
  comparable, once the brief stated its working directory; the run that lacked it edited the wrong
  checkout. Every Haiku slip so far traced to something the brief left unsaid. Per token Haiku is a
  twentieth of Sonnet's price, so `high` effort still leaves it about ten times cheaper, and
  Anthropic's docs recommend `high` for long agent tasks and strict instruction following.
- **Calm, card-based screens.** An owner's phone review found screens correct but plain: facts and
  actions drawn alike, no icons, nothing primary. The structure rules in `uiux` fixed it across
  forty screens in one pass, built by five agents from one set of blocks.
- **Measure, don't guess causes.** Two bugs the owner found on a phone after QA passed. Sign-in took
  seconds because the function ran in another region from the database. A deploy needed several
  restarts to arrive and re-downloaded 3.7 MB. No run measured time, and none spanned a deploy. QA
  now records time, bytes, CPU and memory from the runs it already makes, judges them against human
  limits and the default branch, and has the reviewer find each flag's cause; no check names one.
- **Check the routes once, for all of them.** One slice's QA took four runs (about $60), mostly
  finding input edge cases one route at a time. A route table and a sweep of the same bad requests
  at every route replaced that.
- **Run what a fresh browser never does, and break the code on purpose.** The lived-in journeys
  (a deploy, resume, offline, a slow network, 200% text), on their first run, found text drawn over
  text at 200% font size on three screens. The breakage checks, on theirs, found a row lock no test
  held.
- **Date every model fact, and refresh it.** The `llm` skill's first vendor docs (as `prompt`) were
  copies of each vendor's guide, written for Claude Opus 4.6, GPT-5 and Gemini 3. By October 2026
  the newest models rejected or ignored three things they taught: sampling parameters
  (`temperature`), prefilled replies and thinking budgets. On Claude 5.5 each is an HTTP 400. The
  named frameworks they picked between (CRAFT, CO-STAR) appear in no vendor's guide. The notes are
  now short, dated and sourced, with the principles kept apart, so a refresh touches only the facts.
