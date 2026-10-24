# CLAUDE.md

> **This is a template** (the `workflow` plugin's `templates/CLAUDE.md`). Fill in the `<…>` parts and
> delete this note. The workflow's rules (session rotation, models and subagents, the owner's rules)
> come from the plugin at the start of every session; this file holds what's true of this project
> only, and its *Overrides* section wins over the plugin.

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
| `docs/workflow/` | This project's additions to the plugin's skills: `<skill>.md` per skill, and refreshed notes under `<skill>/` | Wins over the plugin's skill where they differ |

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

## Commands

From the repo root:

| Command | What it does |
|---|---|
| `<install>` | Install everything |
| `<dev>` | The app locally, with its dev tools |
| `<test>`, `<typecheck>`, `<lint>`, `<format>` | The fast checks a contributor runs before a push |
| `<security checks>` | The dependency audit, a secret scan and the stack's security lint rules (the `security` skill's stack note), failing on a high or critical result. Runs in CI and in QA's sweep |
| `<e2e>` | End-to-end tests. Offer an env var that keeps each screenshot as a file (QA's sweep needs it) and one that narrows a long matrix for PR pushes, with the full matrix nightly |
| `<route sweep>` | Every route in the route table hit with the same bad requests (usually part of `<test:db>`) |
| `node scripts/mutants.mjs` | The breakage checks: each dangerous edit in `qa/mutants.ts`, made in a worktree, must turn a suite red |
| `<lived-in journeys>` | The journeys a fresh browser never runs: across a deploy, resume, offline, slow network, large text, a small phone, a year of data |
| `<diff against main>` | QA's diff: each screen's tree and pixels against the default branch, the scripted visual checks and the metrics flags, into `qa-artifacts/<branch>/diff/index.md` |

## Layout

<A table: path → what it holds.>

## Overrides

<Where this project departs from the workflow plugin's rules, one line each, with the decision that
chose it. Empty is fine. A departure from one skill goes in `docs/workflow/<skill>.md` instead.>
