# Evals

How to prove a model call works, and that a change to it is an improvement. `SKILL.md` holds the
rules; this file holds the method.

## What to evaluate

- **One model call, one eval.** A product with a classifier, a mapper and a summariser has three
  evals. Start with the call you need a number for first.
- **Read real traces before writing any check.** Name failure modes you saw, not ones you imagine.
  Generic scores (helpfulness, coherence) don't measure anything specific. Similarity metrics
  (ROUGE, BERTScore, cosine) measure overlap, not correctness: they are for ranking retrieval only.
- **Evaluate only behaviour the prompt asks for.** When a failure is something the prompt never
  asked for, fix the prompt first.
- **Measure the outcome, not a proxy for it.** When a cheaper proxy is used while iterating, run
  the real measure once on the winner.
- **Run each case through the product's real entry point**, with the production prompt, tools,
  model and effort. Stub only the dependencies with unsafe side effects.
- **A case holds everything the call receives:** the text, attached files, the user's profile, the
  conversation so far.

## Error analysis

- Read the full trace for each case: the input, every step and tool call, retrieved context, and
  the output.
- Start with 15–25 traces: about two thirds picked to cover different kinds of input (length,
  turns, tool calls), one third at random. Add outliers on latency or tokens, and every trace a
  user complained about.
- **Open coding:** write a free-text note on what went wrong in each failing trace. No categories
  on the first pass.
- **Then group the notes into failure modes**, each with a name, a description, a count and
  example case ids.
- After finding a new mode, re-read the earlier traces and scan every trace for it. Favour recall:
  a false alarm costs a second, a missed instance costs a bug.
- Keep reading, toward about 100 traces, until new ones only repeat known modes.
- Labels come from someone who knows the domain, usually the owner. When two people label, they
  first label the same 20–50 traces and settle their disagreements.
- Redo error analysis after a model switch, a prompt rewrite, a new feature or a production
  incident. Failure modes move.

## The test set

- **Start with 15–100 cases.** Under 15, one flaky case swings the score; far over 100, nobody
  reads the failures.
- **Sources, best first:** production inputs, bug reports and complaints, examples the owner
  writes, then variations generated from real cases. Never generate cases from the prompt alone:
  start from 3–5 real ones and one sentence on what makes a case hard.
- **Personal data stays out of the repo.** Store ids and fetch at run time, anonymise, or rewrite
  each input into a synthetic one with the same shape and difficulty.
- **Synthetic inputs:** pick about three dimensions where failures are likely (for example how
  clear the request is: well specified, ambiguous, out of scope). Write 20 combinations by hand,
  generate more in batches of 10, then turn each into natural language in a separate step with one
  hand-written example. Drop unrealistic and near-duplicate results. Don't generate inputs where
  nobody can judge realism, in specialist domains (legal, medical) or in low-resource languages:
  sample real inputs instead.
- **Cover both directions:** inputs where the call should act and inputs where it shouldn't (an
  order and small talk; a tool call and none). Otherwise "always do X" scores perfectly.
- **Include every can't-answer case and the hostile ones** (*Hostile cases*, below).
- Difficulty comes from the problem, not from obscure wording.
- **Record where each expected output came from:** written by a person, checked by a person, or
  produced by a model (which one). Expected outputs a model produced make that model win. Never use
  model A's output as the expected answer when comparing A and B.
- **Re-derive about 10 expected outputs yourself.** A case that fails on every variant is more
  often broken than hard: run its expected output through the grader.
- **Expected outputs never appear in the prompt**, its examples, or anything the model can read.
  The prompt's examples never come from the eval set.
- **A trivial answer scores near chance.** If an empty, constant or majority-class answer scores
  well, the eval has an artifact.
- Cases built on live facts (prices, menus, dates) go stale: date each expected output. At 95% or
  more the eval can't tell variants apart: add harder cases.
- For a large set, run scripted checks over all of it (duplicates, label balance, lengths, schema
  validity) and read 20–50 cases closely. Fix a generator, not its individual outputs.
- **The owner signs off twice:** on every input (representative? missing cases? cases that don't
  matter?), and on five graded results (would you have graded any differently?). One "yes" to the
  second means the grader isn't ready. An unattended session records both in the handoff and
  carries on.
- Commit the runner, the cases and the grader. Traces and reports stay out of git.

## Graders

- **Use the cheapest grader that truly measures the property:** a code check, then a pairwise
  comparison, then a rubric judge, then a person.
- **Code first.** Structure: parse and check the fields. Forbidden text: a pattern. Ids: compare
  with the allowed or retrieved set. Tool calls: the schema, and whether the right tool was used or
  not. Values: compare with the expected value.
- Normalise before an exact match (whitespace, case, `4` vs `4.0`, thousands separators), except
  where the real consumer needs the raw form.
- Prove each check with a known pass, a known fail, and one wrong but plausible answer. A check that
  always passes or always fails is not evidence.
- Check the objective part of a failure in code and judge only the rest.
- **One check per failure mode, one metric per property** (correct, formatted, concise), not one
  blended score.
- **Grade outcomes, not paths.** Require a tool-call order only when the order is the requirement.
  For a flow that writes, run each case in a disposable workspace and check the end state: the rows
  written, nothing off-limits touched, the step budget kept, and no "claimed success, nothing
  changed". A reply's text proves nothing about a write.
- The grader matches the prompt: if the prompt says "at least X", the grader doesn't require more.
- **Aggregate to fit the question:** the mean for typical quality; fail on any for rare,
  high-stakes behaviour (charging, deleting, sending). Doing nothing must never score best.
- For classification, report precision, recall, specificity and the false-positive rate, next to
  the majority-class baseline. Accuracy alone hides a trade between them.
- Record per case: output length, tool-call count, refusal, truncation, cost, latency. Name the
  hard ceilings (for example, under 2 seconds for a till).
- **Pairwise:** randomise which candidate is A per case, allow *tie* and *both bad*, and treat both
  as data. When iterating, save the baseline's outputs once and compare every later variant with
  those files.

## Judges

- **Only for what code can't check.** One failure mode per judge, binary pass/fail. Several
  severities are several binary judges, not a scale: scales can't be calibrated.
- **A judge prompt has four parts:** the single criterion; pass and fail definitions taken from the
  error-analysis notes; 2–4 examples (a clear pass, a clear fail, a borderline case) from the
  training labels; and structured output with a short critique before the verdict.
- Give the judge only what it needs: the rules and the response, or the context and the answer.
- Start with the strongest model as judge, and move to a cheaper one once it agrees with people.
  Never the model under test. Pin its id, and use structured output for its verdict.
- Randomise answer order, tell it not to reward length, never label a response "baseline" or
  "reference", and treat the text it judges as data.
- **Labels to validate it:** about 100, roughly half pass and half fail even when real traffic is
  skewed, at least 20 of each. Split them once: train 10–20% (the examples' source), dev 40–45%
  (iterate against it), test 40–45% (look once, at the end).
- **Measure TPR and TNR**, the share of human passes it passes and of human fails it fails. Not
  accuracy: a judge that always says *pass* scores 90% when 90% pass. Aim above 90% on each; below
  80% is not usable.
- Iterate on dev. A false pass means the fail definition is too loose; a false fail means the pass
  definition is unclear. Both low: use a stronger judge model. Both stuck: split the criterion.
- Run the test split once. Iterating after seeing it needs fresh labels.
- **Correct the measured pass rate for judge error:**
  `true = (observed + TNR − 1) / (TPR + TNR − 1)`, clipped to 0–1, meaningless when
  `TPR + TNR − 1` is near 0. With TPR 0.92, TNR 0.88 and 0.80 observed, the true rate is about
  0.85. Report it with a bootstrap 95% interval (about 2,000 resamples of the labels).
- **Probe every judge:** an empty string, "I don't know", and a confident answer to the wrong
  question must all fail. Run it twice on the same output to see its own variance.
- Re-validate when the judge's prompt or model, or the task's prompt, changes.
- A judged gain bigger than the change could explain is suspect: read outputs for a surface
  pattern the judge rewards.

## The runner

- **Save per case and repeat:** the full trace, the grade, the judge's critique, the served model,
  tokens (input, output, cache reads, cache writes), latency, tool calls, the stop reason and the
  attempt count. The score and the trace come from the same call.
- Read one result row before a full run. A `$0.00` cost, zero latency, empty usage or a constant
  column is a runner bug. Fail loudly on a missing field.
- **Infrastructure failures are not model failures.** Timeouts, API errors after retries, parse
  failures and grader crashes go to an errors list with their class, never scored as 0. Truncated
  output gets its own status and is left out of means. Refusals are their own metric. No answer is
  not a negative answer.
- Write each row as its case finishes, and resume per case and repeat. Back off with jitter on 429
  and 5xx, cap the retries and record them, and give each case a wall-clock ceiling. A case that
  passed only on retry is a fail, and every attempt counts in cost.
- **Assert that the served model is the requested one.** A silent fallback invalidates the run.
- Fresh state per case, fixed seeds and order, and limits large enough that nothing is clipped.
- **Latency** is the final successful request only: no retries, backoff or queueing. **Cost** comes
  from the recorded tokens, the row's model and its cache rates, with the judge's cost separate and
  the cache equally warm across variants.
- **Estimate before a full run** from a small pilot: tokens per case × price × cases × repeats, and
  the wall-clock time.
- For a conversation, grade its outcome by default; a turn can look fine and follow a wrong one.

## Noise

- **Repeat runs and report an interval.** A pass rate's 95% half-width is about
  `1 / √(cases × repeats)`: 25 × 2 is ±14 points, 50 × 2 is ±10, 100 × 2 is ±7. A difference
  inside that is not a difference.
- Before iterating, put three numbers side by side: the noise, the headroom, and the smallest gain
  worth shipping. When the noise is larger than either, add repeats, add cases, or use a pairwise or
  continuous metric.
- **Run an oracle and a null first:** the expected outputs score about 100%, an empty output about
  0%. Turn off the thing you're tuning: the score should move.
- Recompute the headline from the raw rows. A result that looks too good is a bug until checked.
- Read a sample of failures. When more than about 1 in 10 are the grader's mistake, fix the grader
  before anything else.
- When days separate two runs, run an unchanged control beside the candidate.

## Changing a prompt against the eval

- **Split once, at random, stratified by the main label:** train (cases you read while diagnosing)
  and test (never read; it picks the winner). Never split by baseline score. Under about 50 cases,
  don't split: score everything, and call results directional. Over about 150, hold out a third
  validation slice.
- **The number to report is the held-out change against the baseline, with intervals.** Within
  noise means don't ship it.
- Train up and test flat is overfitting: revert. Train down and test up is noise.
- **One hypothesis per round.** Say which cases you expect to regress, not only which to recover.
  Make each change large enough to clear the noise.
- Describe the failing behaviour in the prompt; never paste words from the cases you read.
- Cut filler from every change: "be careful", "think step by step", restated defaults.
- Prompt gains come in the first one or two rounds. Stop after three flat rounds, or when a
  guardrail metric regresses beyond noise. When stuck, sort the remaining failures into prompt gap,
  grader disagreement, harness error, never reached, and variance.
- **Prompt gains don't transfer between models.** Fix the model before tuning, and re-test the
  winner on every model that will serve it.
- Instructions that trigger actions ("verify twice", "be thorough") cost the most: extra tool
  rounds. Text the model ignores costs little once cached.

## Retrieval and tools

- Decide from traces whether a failure is retrieval, generation or both. Fix retrieval first, and
  evaluate the two separately.
- **Retrieval:** queries paired with the exact chunks that answer them. Recall@k for first-pass
  retrieval (a model can ignore noise but can't use what's missing); MRR or NDCG@k for ranking.
  Treat chunk size and overlap as settings to sweep, and put the document's title and headings on
  each chunk.
- **Generation:** faithfulness (nothing beyond the retrieved context, even if true) and relevance,
  as separate binary checks. A cited id not in the retrieved set is a code-checkable failure.
- **Tools:** arguments match the schema, the expected tool is used or not used, and the step count
  stays within budget.

## Hostile cases

- Write the product's purpose concretely: what the call does, who the user is, what they may see,
  and the outcomes that must never happen.
- The minimum set: instructions inside the input, "ignore previous instructions", a request for the
  system prompt, an output-format hijack, and an attempt to reach another user's data. Grade each
  in code on the forbidden outcome.
- Access tests need synthetic objects the user owns and doesn't own, plus a control where allowed
  access succeeds. A "not found" on a made-up id proves nothing.
- Vary only what an attacker controls. The signed-in identity comes from the harness.
- Include probes in other languages; safeguards are often weaker outside English.
- Keep every concrete attack that worked as a fixed regression case.
- Attack success rate counts validly graded results only, with errors reported apart. A failure in
  a critical category matters even when the overall rate is low.

## CI

- Run the eval on every change to a prompt, schema, model or effort setting, path-filtered so other
  changes skip it. A scheduled run (nightly or weekly) catches the provider changing under you.
- **Gate on the result file, not the exit code:** every case graded, zero infrastructure errors,
  then the threshold. Critical categories fail on any failure. Cost and latency are per-case
  maximums.
- Pin the model and settings, so a red run means your change.
- Strip personal data from stored results.
- Re-run the full suite before calling a fix done; a filtered re-run has a different denominator.

## Checklist for an existing eval

- failure modes come from read traces, not a brainstorm
- binary checks, one failure mode each, code wherever code can check, no similarity metric as the
  main score
- every judge validated by TPR and TNR on a held-out split, with examples from outside dev and test
- cases: clear success criteria, expected outputs pass the grader, provenance recorded, no leakage
  into the prompt, both directions covered, headroom left
- runner: infrastructure errors apart from failures, the served model asserted, production config,
  full traces saved, repeats with intervals, oracle and null runs done
- metrics: tokens from the API's usage, cost from the real model and cache rates, latency of the
  final request only, quality reported next to cost and latency
- noise below both the headroom and the smallest gain worth shipping
