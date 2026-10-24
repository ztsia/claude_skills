# Refreshing a vendor note

The brief a session hands a research agent when a vendor note is stale (`SKILL.md`, *Keep the
vendor notes current*). Copy everything below the line into the Agent call, filling in the `<…>`
parts. Spawn it as `general-purpose`, `model: sonnet`, `effort: medium`, in the background.

---

You are refreshing one vendor note in the `llm` skill. Today is `<YYYY-MM-DD>`.

- **Vendor:** `<Anthropic | OpenAI | Google>`
- **Note:** `<absolute path to the project's docs/workflow/llm/docs/vendors/<vendor>.md>`. It is the only
  file you edit. The other vendor notes are in `<absolute path to the skill's docs/vendors/>`.
- **Models the project calls:** `<exact ids from the code or config>`
- **Why it's stale:** `<over 90 days old | the project calls a model the note doesn't list | the API rejected a parameter the note allows: the error text>`

**Who reads the note:** a coding session writing prompts that a product sends to a model through
the API: a classifier, an extractor, free text mapped to structured data, a summariser, a small
tool-using agent inside the product. Not prompting a coding agent, chat-app usage, or frontend tips.

**Steps:**
1. Read the note in full, and one other vendor note for the shared format.
2. Re-read every URL in its `sources` with WebFetch. Then search the vendor's official sites for the
   current models page, changelog, migration guides, prompting guide, structured outputs, reasoning
   or thinking controls, caching and tool use. Official pages only; third-party trackers often
   disagree with the live docs.
3. Find the current id of each model the project calls, or what it routes to.
4. Rewrite the note.

**The note's format**, the same for every vendor:
- Front matter: `vendor`, `last_checked` (today), `models` (the current ids, cheapest first),
  `sources` (one official URL per line, with a short comment on what it covers).
- `# <Vendor's model family>`, then these sections in this order: *Models*, *Messages and
  structure*, *Structured output*, *Reasoning and effort*, *Sampling*, *Caching*, *Tools*,
  *Untrusted input and refusals*, *Pitfalls*.
- *Models* is one table, cheapest to most capable, with exactly these columns:
  `id | use it for | context (in / out) | reasoning control | price (in / out)`, prices per million
  tokens. Only the current models the vendor recommends for new work.
- 100–160 lines of plain, actionable bullets in the present tense.

**The note states current facts and nothing else.** No history (what changed, what was replaced,
release or deprecation dates), no notes about the research, no comments to the reader, no
"unverified" marks. A claim you couldn't confirm on an official page is left out.

**Scope:** edit only the note. If the vendor's docs contradict a principle in
`<absolute path to the skill's SKILL.md>`, don't edit it: say so in your report. Don't commit.

**Time budget:** about 20 minutes and 30 fetches.

**Report** in under 15 lines: models added, removed or rerouted; parameters or features that
existing calls use and the models now reject; any principle in `SKILL.md` the docs contradict; and
what you left out for lack of an official source.
