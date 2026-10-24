---
vendor: Google
last_checked: 2026-10-24
models: [gemini-3.5-flash-lite, gemini-3.8-flash, gemini-4-argon]
sources:
  - https://ai.google.dev/gemini-api/docs/models  # model ids and status
  - https://ai.google.dev/gemini-api/docs/changelog  # parameter status, model routing
  - https://ai.google.dev/gemini-api/docs/latest-model  # Gemini 4 Argon: thinking, output cap, caching
  - https://ai.google.dev/gemini-api/docs/models/gemini-4-argon  # Argon context and features
  - https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite  # Flash-Lite context and use
  - https://ai.google.dev/gemini-api/docs/whats-new-gemini-3.8  # 3.8 Flash thinking levels
  - https://ai.google.dev/gemini-api/docs/prompting-strategies  # prompt design
  - https://ai.google.dev/gemini-api/docs/thinking  # thinking levels, cost, thought signatures
  - https://ai.google.dev/gemini-api/docs/structured-output  # response_format, schema keywords, limits
  - https://ai.google.dev/gemini-api/docs/function-calling  # tool_choice, thought signatures
  - https://ai.google.dev/gemini-api/docs/system-instructions  # system_instruction
  - https://ai.google.dev/gemini-api/docs/caching  # implicit caching, minimum sizes
  - https://ai.google.dev/gemini-api/docs/pricing  # prices
  - https://ai.google.dev/gemini-api/docs/safety-settings  # safety categories and thresholds
---
# Gemini

## Models

Cheapest to most capable. Prices are per million tokens, thinking included. Batch calls cost half.

| id | use it for | context (in / out) | reasoning control | price (in / out) |
|---|---|---|---|---|
| `gemini-3.5-flash-lite` | high-volume extraction, routing, classification, parsing | 1M / 65K | `thinking_level` minimal–high, default `minimal` | $0.30 / $2.50 |
| `gemini-3.8-flash` | most product prompts and agents | 1M / 64K | `thinking_level` low–high, default `medium` | $0.75 / $3.75 |
| `gemini-4-argon` | hard reasoning, complex agents | 1M / 65K | `thinking_level` low–high, default `medium` | $2 / $10 |

Thinking levels: `minimal`, `low`, `medium`, `high`. `minimal` returns an error on 3.8 Flash and
Argon. `gemini-3.7-flash` and `gemini-3.5-flash` are routed to other models; don't pin them.

## Messages and structure

- Use the Interactions API (`client.interactions.create`, `POST /v1beta/interactions`). Parameter
  names below are its names.
- Put the role, hard constraints and output rules in `system_instruction`.
- Write short, direct instructions; persuasive wording doesn't help. Replies are terse by default:
  ask for detail when the product needs it.
- Use one delimiter style per prompt, XML tags or Markdown headings, not both. Define any term the
  model could read two ways.
- Include few-shot examples with identical formatting and varied content. Too many overfit.
- Long data goes first and the question last, joined by a phrase such as "Based on the information
  above".
- For a closed-domain task, tell the model to answer only from the supplied context and to say the
  answer is unavailable when it isn't there.
- Turn open choices into closed ones (an enum) for classifiers.
- The models think internally: chain-of-thought wording adds thinking tokens and nothing else.
- A request ending in a `model` turn returns 400, and so does `candidate_count`.
- Put rules for consistent output in `system_instruction`.

## Structured output

- `response_format = {type: "text", mime_type: "application/json", schema: <JSON Schema>}`. Read
  `interaction.output_text`. Pydantic and Zod helpers exist.
- Supported: `string`, `number`, `integer`, `boolean`, `object`, `array`, `null` (via a type
  array), `enum`, `format` (date-time, date, time), `minimum`/`maximum`, `minItems`/`maxItems`,
  `prefixItems`, `required`, `additionalProperties`, `anyOf`, `$ref: "#"`.
- Accepted but not enforced: `minLength`, `maxLength`, `minProperties`, `maxProperties`,
  `uniqueItems`, `contains`. Check them in code.
- `title` and `description` guide the model: write them.
- A schema that is too complex returns `400 INVALID_ARGUMENT`. Shorten names, cut enum values,
  drop bounds, narrow `anyOf`.
- Structured output combined with function calling or built-in tools in one call is in preview.

## Reasoning and effort

- `thinking_level` in `generation_config` is the main dial for quality and cost. Run the evals at
  each level and keep the lowest that passes.
- Thinking tokens are billed as output and count against `max_output_tokens`. A small cap returns
  truncated or empty output: lower the level instead of the cap. Thinking can't be turned off.
- Use `thinking_level`; a `thinking_budget` is mapped to the nearest level with a warning.
- On Argon, set `max_output_tokens` to at least 32,768 if you set it at all. Hard prompts can take
  minutes: use an HTTP timeout of 15 minutes or more, or `background: true`.
- On Flash-Lite, use `medium` or `high` for tool use or multi-step work; at `minimal` it ends tool
  use early.
- Enable code execution when exact arithmetic or counting matters.

## Sampling

`temperature`, `top_p` and `top_k` are ignored on these models. Remove them.

## Caching

- Caching is implicit and on by default. Minimum prefix: 4,096 tokens. Explicit caching returns an
  error on Argon and isn't in the Interactions API.
- Put the large shared prefix first (rules, reference data, examples) and the variable input last.
  Send similar requests close together in time.
- `usage.total_cached_tokens` shows the hits. On Argon a cache hit costs about 5% of input.
- In a multi-turn call on Argon, the previous request is cached only when the new turn adds at
  least 2,050 tokens.

## Tools

- A tool is `{type: "function", name, description, parameters}`. `tool_choice` in
  `generation_config`: `auto` (default), `any`, `none` or `validated`. Calls can run in parallel.
- Interactions are stored by default (55 days on paid tiers, 1 day on free). `store=false` opts
  out, which also turns off resuming and `background: true`.
- In multi-turn calls, use `previous_interaction_id`. With `store=false`, resend the thought and
  function-call steps exactly as received; they carry thought signatures.
- Separate any instruction inside a tool result from the data with `\n\n`.
- Grounding with Google Search, Maps and URL context, and code execution, are available on Argon.

## Untrusted input and refusals

- Keep untrusted text in the user turn, inside its own tag, and validate the output in code.
- `safety_settings` is a list of `{type, threshold}`. Categories: `harassment`, `hate_speech`,
  `sexually_explicit`, `dangerous_content`, `jailbreak`. Thresholds: `off`, `block_only_high`,
  `block_medium_and_above`, `block_low_and_above`. The default is off.
- Blocked input returns HTTP 400 with no content. Handle it in code.

## Pitfalls

- Setting `temperature` and expecting an effect.
- A low `max_output_tokens` with thinking on: empty or truncated JSON, still billed.
- Relying on `maxLength` or `uniqueItems` in the schema.
- Mixing XML tags and Markdown headings in one prompt, or putting the question before a long
  document.
- Not handling safety-block 400s and thought-signature errors in stateless calls.
