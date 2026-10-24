---
vendor: OpenAI
last_checked: 2026-10-24
models: [gpt-6-luna, gpt-6.1-sol, gpt-6-astra]
sources:
  - https://developers.openai.com/api/docs/models  # model ids, prices, context, effort levels
  - https://developers.openai.com/api/docs/models/gpt-6-luna.md  # Luna: price, cache price, limits
  - https://developers.openai.com/api/docs/models/gpt-6.1-sol.md  # Sol: price, features, endpoints
  - https://developers.openai.com/api/docs/changelog.md  # endpoint requirements, caching, shutdowns
  - https://developers.openai.com/api/docs/guides/latest-model.md  # "Using GPT-6": parameters and prompting
  - https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra  # goals over recipes
  - https://developers.openai.com/api/docs/guides/prompt-engineering.md  # roles, structure, delimiters, examples
  - https://developers.openai.com/api/docs/guides/text.md  # developer and user messages, instructions
  - https://developers.openai.com/api/docs/guides/structured-outputs.md  # json_schema strict, schema limits, refusals
  - https://developers.openai.com/api/docs/guides/function-calling.md  # tools, strict mode, tool_choice
  - https://developers.openai.com/api/docs/guides/reasoning.md  # effort, reasoning tokens, headroom
  - https://developers.openai.com/api/docs/guides/prompt-caching.md  # prefix caching, sizes, TTLs, pricing
  - https://developers.openai.com/api/docs/guides/migrate-to-responses.md  # Responses and Chat Completions
  - https://developers.openai.com/api/docs/guides/safety-best-practices.md  # untrusted input, safety_identifier
  - https://developers.openai.com/api/docs/guides/evaluation-best-practices.md  # evals
---
# OpenAI

## Models

Cheapest to most capable. Prices are per million tokens. Batch and Flex calls cost half.

| id | use it for | context (in / out) | reasoning control | price (in / out) |
|---|---|---|---|---|
| `gpt-6-luna` | classifiers, extractors, summarisers; high volume, low latency | 922K / 128K | `reasoning.effort` none–max, default `medium` | $0.10 / $0.50; prompts over 272K tokens 2× in, 1.5× out |
| `gpt-6.1-sol` | complex extraction, tool-using agents | 922K / 128K | `reasoning.effort` low–max, default `medium` | $2 / $10 |
| `gpt-6-astra` | the hardest reasoning | 922K / 128K | `reasoning.effort` low–max | $10 / $50 |

Effort levels: `none`, `low`, `medium`, `high`, `xhigh`, `max`. `none` returns 400 on Sol and Astra.

## Messages and structure

- Use the Responses API. Tool calling with reasoning needs it: Chat Completions calls functions
  only at effort `none`.
- The `developer` message (or the `instructions` field) holds the application's rules and outranks
  `user` messages: developer is the function definition, user is its arguments. `instructions`
  covers only the current request; resend it on each call that uses `previous_response_id`.
- Untrusted text goes in a `user` message, inside delimiters. Never join it into the developer
  message.
- Order the developer message as identity, instructions, examples, context. Use Markdown headings
  for sections and XML tags around documents. Put long context near the end.
- Start without examples on reasoning tasks; add a few varied input/output pairs when the evals
  show they help. Examples can hurt function calling on reasoning models: test with and without.
- State the goal, the constraints and what done looks like, not a step-by-step recipe. "Ask before…"
  and "stop for review" wording makes the model stop work it could finish. In a one-shot call that
  must return data, say to act on the best interpretation, never ask a question, and put ambiguity
  in a field. Astra asks clarifying questions unless told not to.
- The model acts on everything in context, including stale or conflicting instructions. Remove
  conflicts, and say which source wins where two may disagree.
- Output is heavily formatted by default. Ask for plain paragraphs when a person reads it; use a
  schema when code reads it.
- Pin the model id. `gpt-6` and `chat-latest` are moving aliases.
- Keep prompts and evals in your own code. Reusable prompt objects (`v1/prompts`) and the Evals
  platform are shutting down; don't build on them.

## Structured output

- Responses: `text.format = {type: "json_schema", strict: true, schema: {…}}`. Chat Completions:
  `response_format` with `type: "json_schema"`.
- The root is an object, not `anyOf`. Every object has `additionalProperties: false`. Every field is
  listed in `required`; an optional field is nullable (`["string", "null"]`). Keys come back in
  schema order.
- Limits: 5,000 properties, 10 levels of nesting, 1,000 enum values in total. `allOf`, `not` and
  `if`/`then`/`else` are unsupported. `pattern`, `format`, `minimum`/`maximum` and
  `minItems`/`maxItems` are supported.
- The first call with a new schema is slower; later ones aren't.
- A safety refusal comes back as a `refusal` item, not schema JSON. `status: "incomplete"` with
  reason `max_output_tokens` means truncated JSON. Check both before parsing.
- Say in the prompt what to return for input that can't fit: empty arrays, a status field,
  `null`. Otherwise the model forces a fit.

## Reasoning and effort

- `reasoning.effort` tunes depth. Tighten the prompt before raising it.
- Reasoning tokens are hidden, billed as output, and count against `max_output_tokens`. Start with
  at least 25,000 tokens of headroom; too little returns `incomplete` with no visible text.
- For a latency-sensitive classifier, use Luna at `none` or `low`.
- To change effort mid-conversation, add a `configuration_update` input item instead of changing
  `reasoning.effort`; that keeps the cached prefix.
- Control length in the prompt and with `max_output_tokens`, and use a schema where there should be
  no prose.

## Sampling

`temperature`, `top_p`, `logprobs` and `top_logprobs` are accepted only at effort `none` (Luna).
At any other effort they are rejected. Consistency comes from schemas, low effort and evals.

## Caching

- Caching is automatic and prefix-based. Minimum: 1,024 input tokens.
- Put stable content first: the developer message, reference data, tool definitions, the schema.
  Put what varies last: timestamps, the user's text. Any edit before a cached point breaks the match.
- TTL via `prompt_cache_options.ttl`: `"30m"` (default; writes 1.25× input) or `"12h"` (writes 2.5×).
  Reads cost 0.1× input, 0.05× on Sol.
- Up to four explicit breakpoints with `prompt_cache_breakpoint`. `prompt_cache_key` is optional;
  a key per customer separates their billing.
- `allowed_tools` restricts which tools a call may use without changing the tool list, so the
  cache holds.

## Tools

- A tool is `{type: "function", name, description, parameters, strict}`. Responses attempts strict
  mode by default; Chat Completions doesn't. Set `strict: true` explicitly.
- Keep it under about 20 tools per turn. Say when to use each one and when not to. Prefer enums to
  loose flags. Don't ask the model for values your code already knows. Merge tools that are always
  called in sequence.
- `tool_choice`: `auto`, `required`, a named function, or `none`.
- When you replay assistant output items yourself in a long tool flow, keep each item's `phase`
  value unchanged and never add one to user messages. With `previous_response_id`, the API keeps
  that state.

## Untrusted input and refusals

- Send `safety_identifier` (a hashed user id) for each end user.
- Limit input length, prefer validated inputs over free text where the product allows, and have a
  person review high-stakes output.
- Red-team the prompt with injection attempts before shipping.
- Handle `refusal` items and `incomplete` responses in code.

## Pitfalls

- `temperature` sent while effort isn't `none`: the request is rejected.
- `reasoning.effort: "none"` on Sol or Astra: 400.
- A `max_output_tokens` too small for reasoning: `incomplete`, no JSON.
- Optional fields that aren't nullable, or a missing `additionalProperties: false`: the strict
  schema is rejected.
- A top-level `anyOf`, such as a Zod discriminated union at the root: invalid.
- Chat Completions with tools and reasoning: unsupported.
- Per-request text placed before the static content: no cache hits.
