# CLAUDE.md

> **This is a template.** Copy it into a project's root and fill in the `<…>` parts. Inside
> `claude_skills` itself, `README.md` says what's here and how a project takes it.
> `examples/devpos-CLAUDE.md` is an earlier project's, kept for reference.

<One paragraph: what the project is, who it's for, and what it must never become.>

## Read these first

| File | What it is | Treat it as |
|---|---|---|
| `<spec.md>` | The system | The contract. If code disagrees with it, the code is wrong |
| `docs/decisions.md` | Decisions made with the owner, numbered (D1, D2, …) | Settled. Don't reopen one unless the owner does |
| `<docs/flows.md, docs/screens.md, docs/ui/patterns.md>` | Journeys, screen map, shared UI patterns | The UX contract |
| `docs/modules.md`, `docs/briefs/` | The slice map, and one brief per slice | Your branch's boundary. A build session starts from its brief |
| `docs/cloud.md` | What a cloud session has, can reach, and must never hold | Measured facts. Update it when you measure something new |
| `docs/local.md` | What only the owner, or a machine with a device, can do | A queue. Add to it instead of attempting these |
| `docs/handoff.md` | The one handoff, from the last session to you | Read it first. Rewrite it before you end |

### Session rotation

**`docs/handoff.md` is the one handoff.** Read it before anything else. **Every session rewrites it
before it ends**, whether its slice is finished or not, and whenever the owner says *hand off*. Never
append to it: it's the state now, not a log, and git keeps the old versions. Keep it under about 60
lines:
- where things stand: which slice is next or in progress, and on which branch
- what was decided, and why
- what's open with the owner
- what to do first
- what must not be argued over again

Anything still true next week belongs in the spec, `docs/decisions.md`, `docs/cloud.md`,
`docs/local.md` or a brief instead.

**One brief, one branch.** Each slice is built on exactly one branch, named after its brief's file:
`B01/design-system` for `docs/briefs/B01-design-system.md`. A cloud harness may assign its own
`claude/…` branch; ignore it, and work on the slice's branch instead:
1. Look for it: `git fetch origin && git ls-remote --heads origin '<branch>'`.
2. **If it exists, continue it.** Never create a second branch for the same brief:
   `git checkout -B <branch> origin/<branch>`, then read the handoff there.
3. **If it doesn't, create it from `main`:** `git checkout -b <branch> origin/main`, and push with
   `git push -u origin <branch>`.

A slice may span sessions, all on that one branch. Its PR is opened from it when the slice is done,
with the slice's label as its title (*B07 · Sync and the outbox*).

**When context runs high, or the owner says *hand off*, mid-slice:**
1. Log the session's usage: `node scripts/usage.mjs --log <slice>` (it upserts the session's row in
   `docs/usage.md`). Commit and push.
2. Rewrite `docs/handoff.md` on the branch: what's done and verified, what's next, and anything
   decided. Push again.
3. End with one line for the owner to paste into the next session: *Continue B07 from branch
   `B07/sync`*.

`scripts/session-start.sh` also names the newest unmerged branch that changed the handoff, as a
safety net.

**Compacting instead of handing off.** When the owner prefers to stay in one session, write the
handoff first, then let them compact; afterwards read the handoff you wrote and carry on from it.

## Where the build is

<Which slices are merged, which is next, and anything deliberately not built yet.>

## Non-negotiables

<The rules no slice may break, each one line and testable. The kinds that belong here:>
- <Data rules: e.g. money as integer minor units, never a float; row-level security on every table
  from its first migration; every input has a dedupe key.>
- <Secrets and data: e.g. secrets never ship in the client; no cloud session holds production
  credentials; real personal data never enters the repo (fixtures are anonymised copies in a
  gitignored `private/`).>
- <AI rules, if the project has a model in it: e.g. models draft, the owner confirms, code computes;
  no number a model produces is stored or shown as fact.>
- **One navigation and one set of UI patterns** (`<docs/ui/patterns.md>`). No screen invents its own
  list row, form, sheet, or empty, loading or error state.

## Stack

<A table: layer → choice, with the decision number that chose it.>

## The owner

<How the owner works: from a phone through cloud sessions, or at a desk.>

- **Design sessions are conversations.** Ask, but batch questions, prefer multiple choice, keep
  messages short, and always recommend an answer.
- **Put what the owner must weigh inside the question's options.** Text written just before a
  question box can be hidden.
- The owner reads every trade-off and often comes back with a better idea. Recommend clearly anyway.
- **Build sessions run unattended: never stop to ask.** Record the question in the handoff and keep
  going on everything else.
- Anything the owner must do by hand goes in `docs/local.md`, with steps a phone can follow.
- Commit and push work in progress often. An idle cloud VM can be reclaimed, and uncommitted work
  goes with it. Exception: an agent's files while it is still editing them; commit once you've
  reviewed its report.

## Conventions

- One slice at a time, each ending in one PR to `main` titled with its label. A slice may span
  sessions (*Session rotation*).
- **Design pages and their assets live in the repo**, so nothing depends on a published page or a
  font CDN staying up. Every published page has its source in the repo, and publishing goes from a
  committed file.
- **shadcn first, customised in place** (when the project uses shadcn/ui). Every building block
  starts from a shadcn/ui component (the `uiux` skill). When its defaults don't fit, edit the shadcn
  file itself, with a `// <project>:` note on its first line saying what changed, so an upgrade
  (`shadcn add <x> --dry-run`) can keep it. Never write a parallel, hand-rolled version of something
  shadcn has. `className` at a call site is for layout only.
- **Commands**, from the repo root:

  | Command | What it does |
  |---|---|
  | `<install>` | Install everything |
  | `<dev>` | The app locally, with its dev tools |
  | `<test>`, `<typecheck>`, `<lint>`, `<format>` | The fast checks a contributor runs before a push |
  | `<e2e>` | End-to-end tests. Offer an env var that keeps each screenshot as a file (QA's sweep needs it) and one that narrows a long matrix for PR pushes, with the full matrix nightly |
  | `node scripts/usage.mjs` | What this session cost, by agent and model; `--log <slice>` keeps its row in `docs/usage.md` |
  | `node scripts/qa-report.mjs qa-artifacts/<branch>` | Renders QA's report for publishing (the `qa` skill) |

- **Layout:** <a table: path → what it holds.>

### Models and subagents

**The main session is the brain; subagents are its hands.** The main session runs on the strongest
model (Opus). It talks with the owner, makes every decision, works on the non-negotiables, writes
the briefs, and reviews what comes back. Subagents carry out work that is decided but too long or
too repetitive to be worth the strongest model's price. This is the owner's standing request, so a
session spawns them without being asked. **Why:** the strongest model costs most and is there to
think. If it hands the thinking down, the project pays for a brain and gets a smaller one, and a
cheap model running the session would do as well.

**A brief that leaves thinking to the subagent is the main session's failure, not the model's.** The
`brief` skill holds how: choosing the model (Haiku at `high` for whatever a brief can fully specify,
Sonnet for what can't be written down in advance, the main session itself for small changes, design
calls and the non-negotiables' logic), the brief's template and checks, and what to do when work
comes back wrong.

| Agent | What it's for |
|---|---|
| `implementer` | A batch already decided, owning its own files; several run in parallel, in the background |
| `qa-reviewer` (Sonnet; the strongest model when the risk calls for it) | Always, through the `qa` skill |
| `scout` (Haiku) | Something too big to read, such as a long log; not what one `grep` answers |

- **Two end-to-end runs never overlap** when they share ports or build folders.
- **Measure:** `node scripts/usage.mjs` (from the session's starting directory); `--log <slice>`
  keeps a row in `docs/usage.md` before every handoff and PR. The main session's own context is the
  largest cost, so keep its reading and writing small and hand off early. Measurements go in
  `docs/usage.md`, never here: this file holds principles, not history.

## Skills

| Skill | Use it when |
|---|---|
| `qa` | A slice is finished and before its PR, or a non-negotiable was touched. It runs the Haiku sweep, spawns the `qa-reviewer` subagent, and **sets the three tiers for fixing what QA finds**: small fixes self-verified, scoped ones re-checked by resuming the last run's reviewer, and a fresh full run only when a fix reaches the whole flow |
| `brief` | Before every Agent call that does work, and when a subagent's work comes back short: the model, the brief, and what to do about a miss |
| `uiux` | Choosing components for a screen, building one, or checking one before it's done |
| `database` | Designing or checking tables, migrations, SQL, RLS policies, views, functions, or an API route or sync that touches data |
| `dataflow` | Client state, optimistic updates, realtime |
| `prompt` | Writing or reviewing a prompt the product sends to a model |

Skills are model-invoked from their descriptions, so no session needs to be told to use one.
**Our own skills are knowledge, not modes** (`dataflow` and `prompt` still run as audits, to be
converted the same way). Invoking one loads what to do and what must be true; it
never asks which mode to run in or produces an audit report for someone else to act on. Build
sessions run unattended and call skills themselves. Where a vendor skill disagrees with ours, the
patterns doc or a decision, ours win; a build session never stops to ask the questions a skill says
to ask.
