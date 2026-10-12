# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Project Overview

**DevPOS** — a single-device POS for small restaurants, cafés, and food stalls that digitises the table lifecycle (seat → order → modify → cook → pay → turn). This is a **timed-assessment MVP**: one vertical slice that runs end-to-end and screenshots well. Full spec in `spec.md` (source of truth).

The one graded AI feature: **freeform spoken orders mapped to menu SKUs + quantities, reviewed and confirmed by the cashier** before the order is created. Voice → text happens client-side; only text crosses the wire to the AI.

**Architecture:** React (Vite) PWA → REST/JSON → FastAPI → SQLAlchemy → MySQL (SQLite fallback). One external call: Anthropic API for order-text → menu-SKU mapping.

**Frontend routes:** Floor grid `/` · Order `/table/:id` · Pay `/table/:id/pay` · Kitchen `/kitchen` *(Should)*. Two layouts, one component set: floor grid @ till, list @ phone, re-flowed by breakpoint.

**Build order (per spec §16):** backend spine → frontend spine → AI voice order → status + cooking-lock → PWA shell → *(Should)* kitchen + per-item split → reserve last ~12 min for screenshots + pitch PDF.

**Stack:**

| Layer | Choice |
|---|---|
| Frontend | React (Vite) PWA + TypeScript |
| Backend | Python + FastAPI |
| ORM/DB | SQLAlchemy → MySQL (SQLite fallback) |
| AI | Anthropic API (text → structured order) |
| Voice | Web Speech API (browser, client-side) |

---

## Session Start Protocol

1. Read `tasks/context.md` to understand current implementation state
2. Read `tasks/lessons.md` to review known mistake patterns
3. Read `tasks/decisions.md` to see decisions made so far
4. If `tasks/context.md` is missing or clearly outdated, flag it before proceeding

---

## Feature Planning Workflow

> **Do not use the built-in `/plan` command and do not call the `EnterPlanMode` tool.** The workflow below replaces both entirely. Plan mode blocks file writes and prevents the plan from being saved to `tasks/plans/`.

For every new feature discussed for the first time:

1. **Create a plan file** at `tasks/plans/<feature-name>.md` — use the Write tool immediately during discussion; never output the plan inline in chat
2. **Iterate** — refine the plan file based on feedback; do not start implementing. During iteration, if the user corrects something worth remembering, add it to `tasks/lessons.md` immediately before continuing
3. **Wait for explicit approval** — never implement until the user says to proceed
4. **Implement** — work through phases in order, marking items complete as you go
5. **One plan file per feature** — completed plans are archived, never amended for a different feature
6. **Every plan must end with a final phase: "Update context"** — steps are to update `tasks/context.md` to reflect the new implementation state

If something goes sideways mid-implementation: **STOP**, update the plan file with the blocker, and re-align with the user before continuing.

### Plan File Format

Plans are broken into **numbered phases**. Each phase is self-contained and can be delegated to a Haiku session. All decisions must be resolved in the plan file before implementation — Haiku must never need to ask questions.

```md
# Plan: <Feature Name>

## Goal
<one-sentence description>

## Decisions Made
<choices and rationale — resolve ALL of these before any phase starts>

## Open Questions
<must be empty before handing to Haiku>

---

## Phase 1: <Phase Name>

**Goal:** one sentence

**Read these files before starting:**
- src/app/layout.tsx
- src/components/navbar.tsx

**Steps:**
- [ ] Exact step with file path, component name, and what to change
- [ ] ...

**Verify before marking done:**
- [ ] `npx tsc --noEmit` passes with no errors
- [ ] <specific UI behaviour to visually confirm>
- [ ] No hardcoded colours (no `bg-white`, no hex values — use semantic tokens only)

---

## Phase 2: <Phase Name>
...
```

---

## Plan Archive Workflow

```
tasks/
  context.md             ← current implementation state
  lessons.md             ← known mistake patterns
  plans/
    active-plan.md        ← only in-progress plans live here
    archive/
      completed-plan.md   ← move here when fully implemented
```

After the last checklist item of a plan is ticked:
1. Move the plan file to `tasks/plans/archive/`
2. Update `tasks/context.md` to reflect the new state

---

## After Each Phase

When a phase is fully implemented and verified:
1. Tick all checklist items in the phase
2. Update `tasks/context.md` to reflect the new state
3. If it was the final phase: move the plan file to `tasks/plans/archive/`

---

## Audit Protocol

When asked to audit a plan, produce a structured table:

| Aspect | Current | Verdict | Recommendation |

Verdicts: `✅ Correct` | `🔷 Elevate` | `⚠️ Fix` | `❌ Replace` | `❌ Critical`

Identify gaps proactively — do not just validate what was stated.

---

## Subagents

- Use subagents to keep the main context window clean
- One focused task per subagent

### Parallel skill audits

When the user requests multiple skill audits in parallel (e.g. "audit using subagents — /uiux"):

1. **Do NOT call `Skill` in the main conversation.** `Skill` loads instructions into the main context and is incompatible with parallelism.
2. **Spawn one `Task` agent per skill** using `subagent_type=general-purpose`, all in a single message. Tell each agent to invoke the relevant skill via the `Skill` tool.
3. Wait for all agents to return, then integrate their findings.

Example prompt for one agent:
```
You are auditing a plan for the ztsia-portfolio project.
1. Use the Skill tool with skill="uiux" to load the UI/UX audit instructions.
2. Read the plan file at tasks/plans/<feature-name>.md.
3. Follow the skill instructions to produce an audit table.
Return only the audit table and recommendations.
```

---

## Verification

- Never mark a phase or task complete without proving it works
- Run `npx tsc --noEmit` after every phase
- Visually confirm UI changes match the spec in `spec.md`

---

## Code Quality

- Simplicity first — minimal code impact, touch only what's necessary
- Find root causes — no temporary fixes, no band-aids
- For non-trivial changes: pause and ask "is there a more elegant solution?" before presenting
- Skip elegance checks for simple, obvious fixes

---

## Bug Fixing

- When given a bug report: just fix it
- Point at logs, errors, failing tests — resolve them

---

## Commit Messages

- Write the commit subject only — no body, no trailers
- **Never** append `Co-Authored-By`, `Co-authored-by`, or any attribution line to commit messages

---

## Decisions Log — CRITICAL, maintain throughout

Maintain `tasks/decisions.md` continuously. **Append a line whenever ANY of these happen:**

- A design / stack / architecture choice is made
- The user overrides, redirects, or corrects you
- Scope is cut or deferred

Write it to be **read aloud in a walkthrough right after building** — concise, decision-focused, NOT a changelog of every edit. Capture the *what* and the *why*, never the mechanics.

### tasks/decisions.md format

```md
# Decisions Log

## Architecture & tech decisions
- <choice> over <alternative> — <why>

## AI direction & overrides
- <what the user changed / corrected> — <why>

## Scope cuts
- Cut <X> — <reason: non-core / time / polish>

## Hardest judgment call
- <the single highest-judgment decision + the tradeoff weighed>
```

---

## After Every Significant Change

- Update `tasks/context.md` to reflect current implementation state
- Append to `tasks/decisions.md` if the change involved a decision, override, or scope cut (see Decisions Log above)
- If a mistake is corrected: **mandatory** — update `tasks/lessons.md` with the pattern and the rule

### lessons.md entry format

```md
## <Short title>

**Pattern:** what went wrong
**Rule:** what to do instead
**Why:** reason this matters in this codebase
```
