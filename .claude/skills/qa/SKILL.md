---
name: qa
description: Independent QA pass on the current branch before its PR, plus the rules for fixing what it finds. Diff-driven and measured: mechanical checks first (the suites, a route sweep, breakage checks, lived-in journeys, metrics flags, a diff of every screen against the default branch), then a clean-context reviewer who writes acceptance criteria and flows from the spec, explains every flag, and an eyes pass that looks at each changed screen and tap as a person would. Never guesses causes: it measures. Every finished slice gets a full run. Fixes then go by three tiers. Small: the main session fixes and verifies itself. Scoped: the last run's reviewer is resumed on the area the fixes touched. Full: a fresh full run, only when a fix reaches the whole flow. Bugs the owner finds by hand go in qa/escapes.md and close only with a tooling change. Use when a slice is finished, before a PR, when a non-negotiable was touched, or when asked to verify, QA or review work.
---

# QA pass

Verification by someone who didn't write the code, plus a fixed rule for what happens next. This
skill sets the run up and hands off to the `qa-reviewer` subagent. Its clean context is the point.

This skill needs the project's `CLAUDE.md` to name: its non-negotiables, its spec, its slice or brief
file (what a slice is and what it owns), its commands (start the app, the QA database, the tests, the
e2e run, and the QA commands: the route sweep, the breakage checks, the lived-in journeys, the diff),
the handoff file, and the file where manual work for the owner is queued. Where one is missing, the
reviewer infers scope from the branch and its diff and says so. Starting files for the tooling are in
`templates/` (`qa/limits.ts`, `qa/mutants.ts`, `qa/escapes.md`, `scripts/mutants.mjs`, `api/`).

## When to run it

- **A slice branch is finished, before its PR is opened.** This is the main case, and it's always a
  **full run**, whatever the slice. The tiers below apply only to the fixes that follow it.
- **A `CLAUDE.md` non-negotiable was touched**, even mid-slice.
- **Someone asks** to verify, QA or independently check work.

Skip it for a docs-only change. If `git diff --stat main...HEAD` shows nothing outside docs and
`*.md` files, say so and stop. (Use the project's default branch if it isn't `main`.)

## Running it

QA is **diff-driven**. It records what every screen *is* (its accessibility tree, committed beside
the e2e tests), compares the branch's pixels with the default branch's in every look and colour mode
the project has, measures by script what a person shouldn't have to spot, and looks hard only at what
changed. Behaviour runs once, in one look.

It also **measures, and never guesses causes.** The runs already made record what each screen, tap,
route and build costs a person (time) and a phone (bytes, CPU, memory), on the branch and on the
default branch. `qa/limits.ts` judges them against human limits and against the default branch, and
flags only what breaks a limit or got worse. No check names a cause ("the function is in another
region", "file X under N KB"): a check that names a cause only catches the last bug. The reviewer
finds the cause of each flag.

**The order is mechanical first, then judgement on what the machines raised:**
1. the suites (typecheck, lint, unit, database, e2e)
2. the route sweep: every route in the route table hit with the same bad requests
3. the breakage checks: dangerous edits made in a worktree, each of which a suite must catch
4. the lived-in journeys: across a deploy, resume from the background, offline, a slow network,
   200% text, a small phone, a year of data
5. the metrics flags
6. the diff against the default branch

The reviewer then spends its judgement on the flags, the surviving breakage checks and the changed
screens, and on the criteria it writes from the spec. It does not re-derive input edge cases route by
route: a slice that did that took four runs and about $60, nearly all of it edge cases found one
route at a time.

1. Start the QA database and the app as `CLAUDE.md` § Commands describes.
2. Spawn `qa-reviewer` with the Agent tool, `subagent_type: "qa-reviewer"`. It runs on Sonnet by
   default; pass `model: "opus"` when the slice's risk calls for it. **It spawns its own helpers**
   (the sweep and the eyes pass, from the templates below), so the main session doesn't run a sweep
   and its context stays small.
3. **Keep the prompt thin:** the branch, the slice label and the slice's entry in the slice map (if
   the project has one). Nothing else. A scoped run (tier 2) adds only its area and the finding IDs,
   below.
4. **Keep the last run's record:** before a new run, rename `qa/<slice>/report.md` to
   `report-run<N>.md`, so the new run writes its own.

> **Don't tell it what you built, how it works, or why you think it's right.** Its value is that it
> derives its criteria from the spec independently. Briefing it with your reasoning turns an
> independent check into a confirmation of your own assumptions. Don't pre-empt it with known
> issues either. If it misses one, that's a finding about how clear the spec is.

Run it in the background and keep working.

## The helpers' templates

`qa-reviewer` spawns these with the Agent tool (a subagent may spawn subagents when `Agent` is in its
tools). Each template fixes the helper's agent, model and prompt; the reviewer fills in only the
angle brackets. Neither helper judges the slice for the reviewer.

**The sweep** (`subagent_type: "implementer"`, `model: "haiku"`, effort `high`), first, in the
background, while the reviewer writes its criteria. Replace each `<…>` with the project's command
from `CLAUDE.md`:

```
Goal: QA's raw results for branch <branch>, gathered in qa-artifacts/<branch>/sweep/. No judgement,
no fixes, no reading of source beyond a failure's first lines.
Run, from <absolute path of the checkout>, one at a time, each to its end, keeping each exit code:
  <typecheck>; <lint>; <unit tests>
  <database tests, including the route sweep>
  <e2e, with the env var that writes each screenshot to qa-artifacts/<branch>/sweep/screens>
  <lived-in journeys>
  <breakage checks: node scripts/mutants.mjs>
  <the diff against the default branch, into qa-artifacts/<branch>/diff>
Never two at once: they share ports and the test database.
For a run over ten minutes, start it in the background writing a log and an exit-code file, and
wait with ONE until-loop on that file; never report a run still going.
Write qa-artifacts/<branch>/sweep/index.md: each command, its exit code and duration; each failing
test's name, file and first error lines; every surviving or stale breakage check
(mutants/index.md); every metrics flag and standing item (the diff report's Metrics section),
pasted; the diff report's summary line, pasted.
Don't commit. Report: index.md's contents.
```

**The eyes pass** (`subagent_type: "qa-eyes"`, the strongest model, its default), once the diff
report exists, when it lists any changed or new entry:

```
The diff report is qa-artifacts/<branch>/diff/index.md, its screenshots beside it. Look at every
changed and new entry it lists, and the filmstrip of every journey step it links (each tap, a frame
every 50 ms for a second), as your instructions say, and write qa/<slice>/eyes.md.
```

**Every metrics flag gets an answer in the ledger.** The reviewer finds why (a request it can see in
the run's network log, a query count in `Server-Timing`, a chunk in the build metrics), then it's
fixed, or accepted with a reason the owner would accept. A flag never fails CI, because timings vary;
an unexplained one is a finding. A *standing* item (a human limit the default branch breaks too) is
explained once, in the slice that first lists it, with a follow-up named.

**Waiting costs.** Every time an agent wakes, it re-reads its whole conversation, and a wait of more
than a few minutes lets the prompt cache expire. One until-loop per long run; never a check every
minute; never a repeat of a long run whose point an earlier run already proved.

The reviewer turns each `wrong` verdict into a finding (Minor at least; Major when a person would be
misled or can't finish a journey) and weighs each `look again` itself.

## Escapes

When the owner finds a bug by hand that QA passed, the main session adds it to `qa/escapes.md`
(template: `templates/qa/escapes.md`) before fixing it:
- what the owner saw
- why QA missed it
- the pin that now catches it: a test that fails on the code before the fix
- the question (**Ask**) the eyes pass will put to every changed screen from then on
- **which run could have caught it**, naming a run that exists or should have
- **what changed in the tooling** so the kind is caught next time

An escape is closed only when a tool, skill or agent changed, not by a pin alone: a pin catches that
bug, a tool catches its kind. A row that can't name a tooling change stays open.

## The retro, and claude_skills

Each slice ends with a retro at the bottom of `qa/<slice>/ledger.md`, before its PR:
- what QA found late, or round after round, and why it wasn't found in the first run
- what cost the most (`node scripts/usage.mjs`, `docs/usage.md`)
- which skill, agent, script or check changed because of it (a change, not an intention)

The lessons that hold beyond the project (how to brief, how to run QA, what to measure) go to the
`claude_skills` repository as a PR at the slice's end: change the general skill there, and link the
PR in the retro. If the session can't reach that repository, queue it in the manual-work file.

## Reading the result

The owner never sees the subagent's report, so relay these yourself:
- the verdict and the counts
- every Blocker and Major, in full

**First, commit and push the reviewer's record at once:** `qa/<slice>/report.md`,
`qa/<slice>/results.json`, its `acceptance.md`, `flows.md`, `eyes.md` and specs, and any accessibility
tree the diff run rewrote (the branch should have committed them; if it hadn't, that's a finding).
That's the durable record: `qa-artifacts/` is gitignored and goes when the VM is
reclaimed. If the reviewer didn't write `report.md`, write it yourself from its final message before doing anything else.

Then **publish the HTML report with the Artifact tool** and give the owner the link:
1. If the reviewer didn't render it, run `node scripts/qa-report.mjs qa-artifacts/<branch>`. Never
   hand-write the HTML. The page links its screenshots as `screens/<name>.png` and writes
   `qa-artifacts/<branch>/publish-files.json`, which maps each one to its file.
2. Look at every screenshot before publishing (montage them into contact sheets), as the Artifact
   tool requires. Real personal or financial data must never be in one.
3. Publish `qa-artifacts/<branch>/report.html` with `files` set to the map in `publish-files.json`.
   The screenshots are uploaded with the page and hosted with it, so the published report keeps
   working after the local files go. When a later run replaces it, publish to the same artifact URL.
4. Add the link to the top of `qa/<slice>/report.md`, and commit and push it.
5. **Discard `qa-artifacts/<branch>/`** once the publish has succeeded: `rm -rf qa-artifacts/<branch>`.
   It's gitignored and too big for git, and the artifact now holds it.

**To rebuild a discarded report** (to republish it, say), everything needed is committed: run QA's
specs as `qa/e2e/playwright.config.ts`'s header says to retake the screenshots into
`qa-artifacts/<branch>/screens/`, copy `qa/<slice>/results.json` to `qa-artifacts/<branch>/`, and
run `node scripts/qa-report.mjs qa-artifacts/<branch>`. Pass `--inline` to embed the screenshots
in one large self-contained file instead.

| Severity | Meaning | Rule |
|---|---|---|
| **Blocker** | A `CLAUDE.md` non-negotiable is violated | Fix it before the PR. Never downgrade it |
| **Major** | An acceptance criterion fails, or a test on a critical path catches nothing | Fix it, or record in the handoff why it's deliberate. Never silently |
| **Minor** | Real, but survivable | Your judgement. Say what you're leaving and why |
| **Note** | An observation | No action claimed |

If you disagree with a finding, argue it from the spec, not from what you meant. If the spec is
genuinely ambiguous, that's a spec bug: fix the spec, because the next slice will misread it the
same way.

## Fixing the findings: three tiers

Sort each **fix**, not each finding, by how far it reaches. Check the tiers from 3 down to 1; the
first one that matches is the tier. **When unsure, go up a tier.** A batch of fixes takes the highest
tier among them. Record every tier decision, and why, in `qa/<slice>/ledger.md`.

### Tier 3, full: a fresh full run

Only when a fix **reaches the whole flow**, not one area of it:
- It adds a migration, or changes the schema, row-level security, or a SQL view or function that
  other code reads.
- It changes shared code that every journey passes through:
  - navigation
  - the shared UI components
  - a shared UI pattern
  - a shared store
  - a core module the non-negotiables name (money, auth, dedupe)
  - the theme
- It changes how the slice works as a whole, rather than fixing a defect in one part of it.

Spawn a **new** `qa-reviewer` with the thin prompt above and run every phase again.

### Tier 2, scoped: the last run's reviewer, resumed on the area the fixes touched

Any fix that changes behaviour and isn't tier 3, including a **Blocker** fix and a fix that touches
a `CLAUDE.md` non-negotiable, as long as it stays inside one area of the slice.

1. Fix, commit and push.
2. **Resume the reviewer of the last run** (SendMessage to its agent ID) with:
   - **the area**, named the way the spec names it: *the import path, from an incoming item to what's
     stored (spec §6.2)*
   - the IDs of the findings fixed in it, and the commit range

   Nothing about how you fixed them. It already holds the slice's criteria, flows and probes, so a
   re-check costs a fraction of a fresh run. Keep each run's agent ID in the handoff for this.
3. It runs in **scoped mode** (`.claude/agents/qa-reviewer.md`): it re-checks the fixed findings,
   re-runs its probes, and attacks the area again, adding criteria the fixes call for.

**Only when that reviewer is gone** (the session rotated, or it was never in this session), spawn a
fresh one in scoped mode with the same message; it reads the committed `acceptance.md`, `flows.md` and
`results.json` first.

**When an area keeps failing, question its design** before patching it again. Repeated misses
usually mean the approach is wrong, not that it needs another rule; take the design question to the
owner. If the area turns out to be the whole flow, the next round is tier 3.

### Tier 1, small: the main session verifies itself

The fix is tier 1 only if **all** of these are true:
- It's a small change: one source file plus its test, or a test, a word or a style.
- It changes no behaviour beyond the finding itself, and nothing from tiers 2 or 3 applies.
- The finding isn't a Blocker.

1. **Red first.** Write or adjust a test that fails on the current code. Run it and keep the output.
2. Fix the code. Run that test (now green), the slice's suite, the typecheck and the lint.
3. If the finding was visual, take a screenshot in the web app at the project's viewport.
4. Record it in `qa/<slice>/ledger.md`:
   - the finding ID
   - the tier, and why
   - the red and green test output
   - the screenshot path, if there is one

No QA re-run for tier 1. The ledger is how the owner audits self-verification: every tier-1 claim
carries its own evidence.

## What is committed, and what isn't

| Path | Committed? | Why |
|---|---|---|
| `qa/<slice>/acceptance.md`, `qa/<slice>/flows.md` | Yes | Each run adds its section; a scoped run reads the earlier ones after writing its own |
| `qa/<slice>/ledger.md` | Yes | Tier-1 evidence, and every tier decision |
| `qa/e2e/*.spec.ts` | Yes | They're the regression suite |
| `qa/<slice>/eyes.md` | Yes | The eyes pass's answers, screen by screen |
| `qa/escapes.md` | Yes | Every bug QA missed, the question it added and the tooling change that closed it |
| the screens' accessibility trees | Yes | CI fails when a screen changes and its tree wasn't updated, so a PR's diff shows which screens changed |
| `qa/<slice>/report.md`, `qa/<slice>/results.json` | Yes | The findings, verdict and evidence, in the repo, so they outlive the VM |
| `qa-artifacts/<branch>/` | No | The sweep, the diff report with its base, head and diff images, screenshots, traces and the rendered `report.html`. Published with the Artifact tool, then deleted. Too big to commit, and rebuilt from the rows above when needed. Add it to `.gitignore` |
