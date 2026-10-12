# claude_skills

Shared Claude Code skills, agents and workflow, taken from the projects that proved them (Sen's
build first). A project copies what it needs and keeps its own copy, so a change here never breaks a
project mid-slice.

## What's here

| Path | What it is |
|---|---|
| `CLAUDE.md` | The workflow template: handoff rotation, one brief one branch, the owner's rules, models and subagents (with the Haiku findings), QA tiers. Fill in its `<…>` parts |
| `.claude/agents/implementer.md` | Carries out a batch already decided; Sonnet by default, Haiku for mechanical batches |
| `.claude/agents/qa-reviewer.md` | Independent QA: criteria from the spec first, mutation checks, database and RLS probes, journeys with screenshots |
| `.claude/agents/scout.md` | Cheap Haiku lookups over long logs or unfamiliar code |
| `.claude/skills/qa/` | How a slice is QA'd: the Haiku sweep, the reviewer, the three fix tiers, the published report |
| `.claude/skills/uiux/` | shadcn/ui components, one set of shared patterns, and the phone-first checklist |
| `.claude/skills/database/` | Data layer and backend security: RLS per request, on plain Postgres and on Supabase |
| `.claude/skills/dataflow/`, `.claude/skills/prompt/` | Client state; prompts a product sends to a model |
| `.claude/settings.json`, `scripts/session-start.sh` | The SessionStart hook: points a session at the handoff and the newest slice branch |
| `scripts/usage.mjs` | What a session cost, by agent and model, from the transcripts; `--log <slice>` keeps a row in `docs/usage.md` |
| `scripts/qa-report.mjs` | Renders QA's results into the report page the `qa` skill publishes |
| `examples/devpos-CLAUDE.md` | An earlier project's CLAUDE.md, for reference |

## Using it in a project

From the project's root:

```bash
git clone --depth 1 https://github.com/ztsia/claude_skills /tmp/claude_skills
mkdir -p .claude scripts
cp -r /tmp/claude_skills/.claude/agents /tmp/claude_skills/.claude/skills .claude/
cp /tmp/claude_skills/.claude/settings.json .claude/   # or merge its hook into yours
cp /tmp/claude_skills/scripts/*.mjs /tmp/claude_skills/scripts/session-start.sh scripts/
cp /tmp/claude_skills/CLAUDE.md CLAUDE.md               # then fill in the <…> parts
echo "qa-artifacts/" >> .gitignore
```

Then, in the project:
- Fill in `CLAUDE.md`: the project, its non-negotiables, stack, commands and layout.
- Create `docs/handoff.md`, `docs/decisions.md` and, when the build is sliced, `docs/modules.md` and
  `docs/briefs/`.
- Give the e2e setup an env var that writes each screenshot to a file (QA's sweep needs it).
- Tailor `uiux` and `database` to the project's stack in place, the way Sen did; keep the rules.

Cloud sessions don't load plugins, which is why everything is plain files in `.claude/`.
