# The workflow

These rules come from the `workflow` plugin, whose files are in `${CLAUDE_PLUGIN_ROOT}`. **The
project wins:** where its `CLAUDE.md` says otherwise (its *Overrides* section), follow the project.
Each skill works the same way: `docs/workflow/<skill>.md`, when it exists, adds to or overrides that
skill, and a file at `docs/workflow/<skill>/<path>` replaces the skill's own `<path>`.

## Session rotation

**`docs/handoff.md` is the one handoff.** Read it before anything else. Rewrite it before the session
ends, whether the slice is finished or not, and whenever the owner says *hand off*. Never append:
it's the state now, not a log, and git keeps the old versions. Under about 60 lines: where things
stand (which slice, which branch), what was decided and why, what's open with the owner, what to do
first, what must not be argued over again. Anything still true next week belongs in the spec,
`docs/decisions.md`, `docs/cloud.md`, `docs/local.md` or a brief.

**One brief, one branch.** Each slice is built on one branch named after its brief's file:
`B01/design-system` for `docs/briefs/B01-design-system.md`. Ignore a cloud harness's `claude/…`
branch and work on the slice's:
1. `git fetch origin && git ls-remote --heads origin '<branch>'`.
2. **If it exists, continue it**, never a second branch for one brief:
   `git checkout -B <branch> origin/<branch>`, then read the handoff there.
3. **If it doesn't**, `git checkout -b <branch> origin/main` and `git push -u origin <branch>`.

A slice may span sessions on its branch. Its PR is titled with the slice's label (*B07 · Sync and
the outbox*).

**Handing off mid-slice**, when context runs high or the owner says *hand off*:
1. `node "${CLAUDE_PLUGIN_ROOT}/scripts/usage.mjs" --log <slice>` (upserts the session's row in
   `docs/usage.md`). Commit and push.
2. Rewrite `docs/handoff.md` on the branch: what's done and verified, what's next, what was decided.
   Push again.
3. End with one line for the owner to paste: *Continue B07 from branch `B07/sync`*.

To compact instead, write the handoff first; afterwards read it and carry on from it.

## The owner

- **Design sessions are conversations.** Batch questions, prefer multiple choice, keep messages
  short, always recommend an answer. Put what the owner must weigh inside the options: text written
  just before a question box can be hidden.
- The owner reads every trade-off and often comes back with a better idea. Recommend clearly anyway.
- **Build sessions run unattended: never stop to ask.** Record the question in the handoff and keep
  going on everything else.
- Anything the owner must do by hand goes in `docs/local.md`, with steps a phone can follow.
- Commit and push work in progress often: an idle cloud VM can be reclaimed. Exception: an agent's
  files while it's still editing them; commit once you've reviewed its report.

## Conventions

- One slice at a time, each ending in one PR to `main`.
- Design pages and their assets live in the repo. Every published page has its source there and is
  published from a committed file.
- **shadcn first, customised in place** (projects on shadcn/ui). Every building block starts from a
  shadcn component (the `uiux` skill). When its defaults don't fit, edit the shadcn file itself, with
  a `// <project>:` note on its first line. Never a parallel hand-rolled version. `className` at a
  call site is for layout only.
- Our skills are knowledge, not modes: invoking one loads what to do and what must be true. Where a
  vendor skill disagrees with ours, the project's patterns doc or a decision, ours win.

## Models and subagents

**The main session is the brain; subagents are its hands.** The main session runs on the strongest
model. It talks with the owner, makes every decision, works on the non-negotiables, writes the briefs
and reviews what comes back. Subagents carry out work that's decided but too long or repetitive to
be worth the strongest model's price. This is the owner's standing request: spawn them without being
asked. **Why:** if the strongest model hands the thinking down, the project pays for a brain and gets
a smaller one.

**Use the `brief` skill before every Agent call that does work, and whenever a report or diff falls
short.** It holds the brief's template and checks, agents running at once, waiting on long runs and
what to do on a miss. A brief that leaves thinking to the subagent is the main session's failure.

**Choose the model per task**, by what's left once the brief is written: **Haiku at `high`**
(`workflow:implementer`'s default) for anything the brief fully specifies; **Sonnet at `medium` or
`high`** when what's left can't be written down in advance; **the main session itself** for a
change under about 100 lines, a design call, or a non-negotiable's logic.

| Agent | What it's for |
|---|---|
| `workflow:implementer` | A batch already decided, owning its own files; several in parallel, in the background |
| `workflow:qa-reviewer` | Always through the `qa` skill. It spawns its sweep and `workflow:qa-eyes` |
| `workflow:scout` (Haiku) | Something too big to read, such as a long log; not what one `grep` answers |

- **Review every report and diff** before committing it. A report is a claim, not proof.
- **Measure:** `node "${CLAUDE_PLUGIN_ROOT}/scripts/usage.mjs"`, with `--log <slice>` before every
  handoff and PR. Your own context is the largest cost: read and write little, hand off early.
