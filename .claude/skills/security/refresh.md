# Refreshing a stack note

The brief a session hands a research agent when a stack note is stale or missing (`SKILL.md`,
*Keep the stack notes current*). Copy everything below the line into the Agent call, filling in the
`<…>` parts. Spawn it as `general-purpose`, `model: sonnet`, `effort: medium`, in the background.

---

You are writing or refreshing one stack note in the `security` skill. Today is `<YYYY-MM-DD>`.

- **Stack:** `<TypeScript | Python | Go | …>`
- **Note:** `<absolute path to .claude/skills/security/docs/stacks/<stack>.md>`. It is the only file
  you edit. If it doesn't exist, create it.
- **What the project uses:** `<runtime and framework versions, package manager, from the manifests and lockfile>`
- **Why:** `<missing | over 90 days old | the project uses a framework or major version the note doesn't cover | an advisory the note doesn't reflect: its id>`

**Who reads the note:** a coding session writing or checking a product's own code (web apps, APIs,
background jobs, CLIs) in this stack, so that the code has no vulnerability a careful reviewer would
find. Not penetration testing, not infrastructure hardening, not compliance.

**Steps:**
1. Read `.claude/skills/security/SKILL.md`, `docs/web.md` and `docs/supply-chain.md` beside it, so
   the note adds stack facts and doesn't repeat the principles. If the note exists, read it in full,
   and read one other note in `docs/stacks/` for the shared format.
2. Re-read every URL in the note's `sources` with WebFetch. Then search the official sites: the
   runtime's and each framework's security pages, release and support schedules, security
   advisories (the project's GitHub advisories, the language's vulnerability database), and the
   package manager's docs for install scripts, lockfiles, release-age gates and audit. Official
   pages first; OWASP's cheat sheets are acceptable for a fact the vendor doesn't state.
3. Write the note in your own words. Never copy sentences from OWASP, from another vendor's skill,
   or from a blog: state the fact.

**The note's format**, the same for every stack:
- Front matter: `stack`, `last_checked` (today), `covers` (the runtime and frameworks, each with the
  supported major versions), `sources` (one official URL per line, with a short comment on what it
  covers).
- `# <Stack>`, then these sections in this order: *Versions*, *Input and validation*, *Injection*,
  *Output and XSS*, *Auth, sessions and access*, *Secrets and configuration*, *Files, paths and
  outbound requests*, *Deserialization and parsing*, *Crypto and randomness*, *Dependencies*,
  *Framework pitfalls*, *Checks to run*.
- *Versions* is one table with exactly these columns:
  `component | supported versions | below this, upgrade first`. One row per runtime and framework
  the note covers. The last column is the lowest version without a known critical or high advisory
  that affects ordinary use.
- Each other section is plain, actionable bullets in the present tense: the safe API by its exact
  name, the dangerous one, and when the dangerous one is acceptable. Where a framework escapes or
  parameterises by default, say so and name the escape hatch that turns it off.
- *Checks to run* lists the exact commands for this stack: dependency audit, a static analyser or
  linter rule set for security, and how each fails a CI run.
- 120–200 lines.

**The note states current facts and nothing else.** No history (what changed, what was replaced,
release or end-of-life dates, advisory timelines), no notes about the research, no comments to the
reader, no "unverified" marks. A claim you couldn't confirm on an official page is left out.

**For `docs/supply-chain.md`** (Stack: *supply chain and CI*): keep its front matter without
`stack` and `covers`, keep its sections and length, verify each claim against its sources and the
current GitHub, package-manager and Docker docs, and correct or remove what they don't support.

**Scope:** edit only the note. If an official source contradicts a principle in `SKILL.md`,
`docs/web.md` or `docs/supply-chain.md`, don't edit them: say so in your report. Don't commit.

**Time budget:** about 25 minutes and 40 fetches.

**Report** in under 15 lines: versions added or moved, the advisories that set a minimum version,
any principle the docs contradict, and what you left out for lack of an official source.
