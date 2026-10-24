# Calling the API

How a model call behaves in production: errors, timeouts, caching, cost, tool loops, and moving to
a new model. Vendor-specific names and numbers are in the vendor notes.

## Should it be a model call

- If the call's inputs fully determine its output (routing, tallying, normalising, filtering,
  formatting), it is code. Keep a model call only where the work needs judgment.
- An agent loop is worth it only when all four hold: the task has many steps that can't be laid out
  in advance, its value justifies the cost and latency, the model can do it, and a mistake is
  recoverable (tests, review, rollback). Any "no" means one call, or a workflow that code drives.

## Errors and retries

- **Retry** 429, 5xx, overloaded errors and network failures, with exponential backoff and jitter,
  a cap on attempts, and `retry-after` honoured. Record the attempt count per call. SDKs retry these
  twice by default.
- **Don't retry** 400, 401, 403, 404 (a wrong or unavailable model id) or 413 (shrink the request).
  Don't resend the same body after a truncation at the output cap, a refusal, or a validation 400.
- Catch the SDK's typed exceptions, most specific first, with separate paths for retryable and
  non-retryable errors. Never match on message strings.
- A retry loop without delay multiplies cost and can turn one 429 into a failed batch.
- On overload: back off, queue the request, or route it to another model.
- Read the 400's message before debugging the request body. Log the request id with every failure.
- A refusal can be an HTTP 200 with empty or partial content: branch on the stop reason.
- A server-side tool can fail inside an HTTP 200: check the result's shape before reading it.
- Parse a tool call's input as JSON. Never string-match its serialised form.

## Timeouts, streaming and long calls

- Stream when the output can be long (over about 16K tokens) or the output cap is high, so the HTTP
  connection doesn't time out.
- **Timeouts come in layers:** a total wall-clock ceiling per call that holds even while a stream
  stays alive, time to first chunk, the gap between chunks, and one per tool execution. A tool
  timeout returns a tool error the model can recover from. Record a timeout as a timeout, never as
  an empty answer.
- Pass the UI's abort signal through to the call.
- Streamed tool input can arrive cut off or as invalid JSON. Guard the parse.
- Work that takes minutes runs in the background and is polled (about every 10 seconds), or holds
  the connection with a read timeout of 15–20 minutes.
- Unit tests mock the model (fixed content, stop reason and usage). A small live eval runs
  separately.
- An unsupported setting can produce a warning instead of an error. Check warnings, and keep a way
  to see the exact request body sent.

## Output limits

- The output cap (`max_tokens`, `max_output_tokens`) is a backstop the model never sees. Starting
  points: about 256 tokens for a label, about 16K for a non-streaming call, about 64K streaming or
  in an agent loop, plus room for thinking.
- A stop at the cap is a failed attempt, not a short answer. Raise the cap or change the request;
  don't retry at the same cap.
- To shorten visible output, describe its shape with an example. To shorten reasoning, lower the
  effort.

## Caching

- A cache hit needs a byte-identical prefix, in the order tools → system → messages. Sort each
  input by how often it changes (never, per session, per turn, per request) and order the prompt
  to match.
- **Silent invalidators:** a timestamp in the system prompt, request ids early, JSON serialised
  without sorted keys, iteration over a set, a user id in the system prompt, conditional system
  sections (each combination is its own prefix), and tool sets that differ per user. Sort tools
  deterministically.
- Don't change tools or the model mid-conversation. Pass a "mode" as message content. A forked call
  (a summary, a sub-task) copies the parent's system, tools and model exactly and appends.
- Put the breakpoint at the end of the shared part. When the first ~1K tokens differ per request,
  don't cache.
- A prefix below the model's minimum size doesn't cache, and nothing says so. Recheck after any
  model change.
- A cache write costs more than a plain read of the same tokens: a short-TTL cache pays off from
  the second request, a long-TTL one from the third.
- **Choose the TTL from the gaps between requests sharing a prefix**, as a distribution, not an
  average: mostly under 5 minutes, the short TTL; 5–60 minutes, the long one; over an hour, neither.
  Long-TTL entries come before short-TTL ones.
- **Check the usage fields after every change to how the prompt is assembled.** Total prompt tokens
  = uncached + cache writes + cache reads. In a healthy loop, reads cover the whole earlier prefix
  and grow; writes cover only the newest turn. Zero reads on identical prefixes means an
  invalidator: diff two consecutive request bodies to find it.
- Concurrent requests can't read each other's cache writes. Send one, wait for its first token,
  then send the rest.
- Caches are per model and per workspace or project. Splitting traffic splits the cache.
- To measure a caching change, run requests in sequence and measure from the second, or the write
  premium reads as a regression.

## Cost

- **Optimise cost per completed task, not per token.** A cheaper model that fails still bills its
  tokens, then the retry, then the downstream damage.
- **Pull the levers in this order, one per change:** caching, then input (check the prompt, trim
  what every call carries), then loop depth, then output limits, then batch; only then effort,
  model, and multi-model designs.
- Measure each kind of traffic separately: an interactive call and a nightly job are different
  workloads.
- Take prices from the vendor's pricing page in the same session, never from memory.
- **Profile a call** by its uncached input, cache writes, cache reads and output (thinking
  included), from logged usage. An estimate that disagrees with the bill usually missed history
  growing across turns.
- **Input:** move large reference data behind a lookup tool when most calls use little of it;
  load rarely used tools only when needed; downscale images to what the task needs (cost grows
  with pixel area; about 1280×720 is a safe default); let code compute over large tables and pass
  only the answer; give tools narrow accessors (`get_item(id)`, not `get_all_items()`).
- **Never silently truncate user input to fit.** Count tokens as it arrives, then summarise, split
  or route it, and say so.
- **Batch** costs half, cache tokens included, and returns within 24 hours. It suits evals,
  backfills and scheduled jobs, single-shot calls only, never what a user waits for.
- **Effort sweeps:** identical requests except for effort, one effort per run, a known hard case
  included, and repeats, since one or two tasks of difference is noise. High-volume classification
  and chat are often fine at low effort.
- When a cheap pass/fail check exists (a validator, a test), run everything at low effort and re-run
  only the failures higher.
- **Choose the model last.** Try a newer model in the same tier first. Try the strongest model at
  lower effort before building a router or cascade. Compare on the hardest tenth of the traffic, not
  the median. Step down one tier at a time, resetting effort to that tier's default.
- **Keep or revert on evidence:** about 50 cases and at least 5 runs per configuration before a
  production switch; 20–30 cases with repeats for each lever. Plot quality against cost per task
  and keep the configurations nobody beats on both. Confirm the saving on the bill afterwards.

## Tool loops

- Loop on the stop reason: continue while the model asks for tools, stop at the end of its turn.
  Cap the iterations.
- Append the assistant's full content to the history (tool calls, thinking blocks), never only its
  text.
- Return every tool result for one turn in a single message, one per call id. A failed tool still
  returns a result, with an error flag and a useful message.
- Where a model rejects forced tool choice, use `auto`, name the tool in the prompt, use a strict
  schema, check that a call was made, and retry once if not. For extraction, use structured output.
- Prefer the SDK's tool runner over a hand-written loop.
- **Gate side effects:** validate the inputs, and require a person's approval for what is hard to
  undo (send, delete, charge). Give such an action its own typed tool so the code can intercept it.
- Tell the model what changed mid-conversation as context, not as an override ("ignore what the user
  said"). Leave a per-turn reminder in the transcript; never insert one and delete it later.

## Conversations, documents and images

- Server-held conversation state (a previous-response or previous-interaction id) saves resending
  history but follows the vendor's retention rules, and per-call settings may need resending each
  turn. When you replay history yourself, keep vendor-specific fields exactly as received.
- On models that keep reasoning between turns, keep the history append-only: editing the system
  prompt, tools or earlier messages invalidates the cache and the stored reasoning. Declare every
  tool the conversation may need on its first request.
- Documents and images go before the question. Downscale images first. Reference large files by an
  uploaded file id.
- Use a dedicated speech-to-text model for transcription, not a general model.
- Some APIs can't combine citations and structured output in one call: choose one.

## Moving to a new model

- **Sort every file that names the old model id:**
  - it calls the API: swap the id and run the vendor note's checks
  - it defines or routes models (a registry, a policy list): add the new entry beside the old one
  - it gates on the id (`if "model-x" in id`) or asserts it in a test: add the new id beside it;
    regenerate snapshots, don't hand-edit them
  - a suffixed or dated variant id: confirm an equivalent exists before changing it
- Grep for sync markers (`KEEP IN SYNC`) before the broad grep.
- Tag each change **BLOCKS** (a 400, a loop, a silent timeout, the wrong tool) or **TUNE** (quality
  or cost). BLOCKS are code changes; TUNE changes wait for the eval.
- Send one request to the new model first. Check the served model in the response, its stop reason
  and its usage.
- A new model id starts with an empty cache.
- Recount tokens and re-size output caps; set effort and thinking explicitly; re-sweep effort from
  the new model's own default.
- Handle the new model's stop reasons, such as a refusal, or context exceeded as distinct from the
  output cap.
- Remove retry paths that existed only for parameters the new model rejects, and beta headers for
  features that are now standard.
- Keep the change narrow: the model id, then only the prompts tied to that call. Leave test
  baselines, comparison code and fallback paths on their pinned ids.
- Compare with the old model's baseline on task success, retries, tool calls, tokens, latency and
  output shape. A spot check shows the model answers, not that behaviour held. A regression someone
  reports becomes an eval case before it is fixed.
