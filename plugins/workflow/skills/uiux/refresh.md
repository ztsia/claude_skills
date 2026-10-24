# Refreshing the component docs

The brief a session hands an agent after running `scripts/refresh.mjs` (`SKILL.md`, *Keep the component
docs current*). Copy everything below the line into the Agent call, filling in the `<…>` parts.
Spawn it as `general-purpose`, `model: sonnet`, `effort: medium`, in the background.

---

You are updating the component index of a UI skill after its shadcn/ui docs were re-pulled.

- **Refreshed copy:** `<absolute path to the project's docs/workflow/uiux>`. The script wrote the docs
  and `components-index.md` here.
- **Skill folder:** `<absolute path to the uiux skill's folder>`
- **The script's output:** `<paste the added, removed and changed lines>`

The docs in the refreshed copy's `docs/` folder are shadcn's own doc source and are already current. Your job is
`components-index.md`, the hand-written table a session reads to shortlist components.

**Steps:**
1. Read the refreshed copy's `components-index.md` in full: its sections, its columns (*Component*, *When to use*, *Key
   variants / features*) and its disambiguation notes.
2. For each **added** doc: read it in full, then add a row in the right section, written like the
   rows around it. Where it overlaps an existing component (a new `Toast` next to `Sonner`, a
   `NativeSelect` next to `Select`), add a disambiguation note saying when to use which.
3. For each **removed** doc: delete its row and any note that names it.
4. For each **changed** doc: see what changed with `git diff -- <file>` when the project's copy was
   already committed, else `git diff --no-index <skill folder>/docs/<file> <refreshed copy>/docs/<file>`,
   and update the
   variants and features column where they changed. Leave rows whose doc changed only in wording.
5. Keep the file's front matter as the script wrote it.

The index states current facts only: no notes on what changed, no dates in rows.

**Scope:** edit only the refreshed copy's `components-index.md`. Then read the skill folder's `SKILL.md` and list every
line that names a component, prop or variant the docs no longer have, or that a new component now
covers better. Don't edit `SKILL.md`. Don't commit.

**Report** in under 15 lines: rows added, removed and updated; and each `SKILL.md` line that needs
a decision, with what the docs now say.
