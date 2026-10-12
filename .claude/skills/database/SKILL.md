---
name: database
description: How to design and check a project's data layer and backend security, on Postgres with row-level security (Supabase, Neon, RDS or plain Postgres). Use when designing tables, writing or changing a migration, SQL, an RLS policy, a view or function, or an API route or sync that touches data, and before calling any of them done.
---

# Database and backend security

You design and review the data layer. A wrong row, a missing policy or a float in a money column is a
real loss. This skill is knowledge, not a mode: loading it gives you what to do and what must be true.
It never asks which mode to run in, and it never produces an audit report for someone else to act on.
Do the work, hold it to the checklist, and fix what fails.

Read the project's own `CLAUDE.md` first. Where it settles an architecture, follow it. The rules
below apply either way.

## Use it when

- designing tables or relationships
- writing or changing a migration
- writing SQL, an RLS policy, a view, a function or a trigger
- writing an API route, server action or sync that reads or writes data
- reviewing any of those, before calling them done

## The principles

1. **RLS is the security boundary, from the first migration.** Every table has
   `ALTER TABLE t ENABLE ROW LEVEL SECURITY` in the migration that creates it. Add
   `FORCE ROW LEVEL SECURITY` if the table's owner could ever run queries. Never write a `true`
   policy unless the data is public.
2. **The app's database role cannot bypass RLS.** It owns no tables and has no `BYPASSRLS`. A
   separate owner role runs migrations and backups only.
3. **Identity reaches the database per request, never per connection.** See the two stacks below.
4. **Never trust client input.** Validate every request body and form with a schema (zod or
   similar) before it touches the database. RLS stops the wrong row. Validation stops the wrong
   value.
5. **Never hold a transaction across a model call or any other network call.** Open a short
   transaction per step. A long request opens a fresh one each time.
6. **Money is an integer in minor units** (`BIGINT` cents, sen, pence). Never `float`, `real` or
   `numeric` for money. User input is parsed as text into the integer. An exchange rate may be
   `NUMERIC`, for display only.
7. **Every input has a dedupe key**, enforced by a `UNIQUE` constraint. A retried sync, a
   re-posted webhook or a file shared twice is a no-op.
8. **A prediction never shares a table with a fact.** Forecasts, estimates, plans and drafts live
   apart from what happened.
9. **Integrity in the schema:** foreign keys with a chosen `ON DELETE`, `NOT NULL` where it is
   true, `UUID` ids, `TIMESTAMPTZ` stored in UTC (compute day and month boundaries in the
   user's zone), `JSONB` only for genuinely loose data.
10. **Logic that must be atomic lives in the database or one transaction.** Triggers keep
    `updated_at` and counters right. A multi-row write is one function or one transaction, never
    several requests.

## RLS patterns

### On plain Postgres (Neon, RDS, self-hosted)

The API verifies the session, then each database step runs in a short transaction:

```sql
select set_config('app.user_id', $1, true);  -- true = transaction-local
```

- `true` makes the setting transaction-local. A pooled connection cannot carry one person's id into
  another request.
- Queries run as the app role. Use a driver with real interactive transactions (a WebSocket pool
  or `pg` over the pooled URL), because the setting must share a transaction with the queries.
- Policies compare against the setting with a guard:

```sql
using (user_id = nullif(current_setting('app.user_id', true), '')::uuid)
with check (user_id = nullif(current_setting('app.user_id', true), '')::uuid)
```

  The `nullif` matters. On a reused pooled connection the setting reads `''`, and the cast would
  throw. With the guard, no identity means no rows.
- Use `WITH CHECK` on insert and update, so a row cannot be moved to another user.
- A table a person may only read gets a select policy and nothing else.
- Views are `WITH (security_invoker = true)`. Without it a view reads as its owner and skips RLS.
- Functions are `SECURITY INVOKER` unless a comment documents why not.
- Admin reads across users go only through narrow `SECURITY DEFINER` functions that check the
  admin flag first, with a pinned `search_path`. A `security_invoker` view cannot do this. Never
  let an admin function reach money tables unless that is the point of the function.
- Requests with no session (a public share link, an invitation, a webhook) never set a user id.
  Each kind goes through one narrow `SECURITY DEFINER` function that checks its token and touches
  only the rows the token names.
- If an auth library keeps its own tables, give it its own role, granted only on those tables.
- Scheduled jobs list users through one narrow function, then act once per user as that user. Make
  each job idempotent per user and date.
- Previews and tests use a separate database with anonymised seed data, not a branch of
  production.

### On Supabase

- The identity is `auth.uid()`. Policies read `(select auth.uid()) = user_id`. Wrapping it in
  `select` lets Postgres evaluate it once per query.
- The browser calls Supabase directly, so RLS is the boundary there. Do not route plain
  single-table CRUD through a server action when a correct policy already covers it.
- Use a server action or edge function only when one of these is true:
  1. it needs the service role key, to bypass RLS on purpose (admin work, creating a profile on
     sign-up)
  2. it needs a server-only secret or a third-party API (payments, email)
  3. it needs an atomic multi-table write that a single client call cannot make
- Treat the service role key like radioactive material. It bypasses every policy. Use it only in a
  place where bypassing RLS is an explicit, audited need, never in code that ships to the client.
- A trigger on `auth.users` can create the profile row on sign-up.
- The same view, function and admin rules from the plain-Postgres list apply: `security_invoker`
  views, `SECURITY INVOKER` functions unless documented, `WITH CHECK` on insert and update,
  narrow `SECURITY DEFINER` functions for cross-user reads.

## Designing data

1. List every entity, relationship, mutation and input source the work implies.
2. Write the tables: column types, `NOT NULL`, defaults, foreign keys with `ON DELETE`, the owner
   column (`user_id`), and the dedupe key's `UNIQUE` constraint.
3. Write the policies for each table and operation, as above. For group access ("A is in group
   B"), use `EXISTS` or a `SECURITY DEFINER` helper with a pinned `search_path`.
4. Add indexes: the owner column first in composite indexes that match the queries, plus an index on
   every foreign key and every `WHERE` or join column that matters.
5. Decide the boundaries: which route, which transaction, what must be atomic, which calls are
   direct and which need a server.
6. Write a schema (zod or similar) for every API input.
7. Put it in the project's migration tool, with a comment on any choice that is not obvious.

## What must be true before it is done

Check every schema, migration, route and function, new or existing, by reading it and how a
request reaches it. Fix anything that fails:

- RLS is on from the table's first migration, with `WITH CHECK` on insert and update
- read-only tables have a select policy only
- the app role cannot bypass RLS and owns no tables
- the user id is set per transaction, with the `nullif` guard
- views are `security_invoker`, functions are `SECURITY INVOKER` unless documented
- cross-user and tokened access goes only through narrow `SECURITY DEFINER` functions
- no transaction is held across a model or network call
- every input has a dedupe key
- no money as a float
- no prediction in a fact table
- tombstones (`deleted_at`) where an offline client syncs deletes
- no N+1 query, no missing index on a foreign key or a filtered column
- every API input is validated by a schema
- timestamps are `timestamptz`, with boundaries computed in the user's zone

## Tests that must exist

- **RLS:** a second user reads none of the first user's rows through any table, view or function.
  An admin reads nothing they should not. A person cannot raise their own limits or switch on their
  own flags. A token function reaches nothing beyond what its token names. With no user id set,
  every table reads empty.
- **Transaction-local identity:** two concurrent requests on one pooled connection never see each
  other's user id.
- **Dedupe:** the same input twice, a retried sync and a repeated create are each a no-op.
- **Money:** shares and apportionments sum exactly to the total, in minor units.

Run them with pgTAP or a test runner on a local Postgres, never against production.

## Rules of thumb

- Do not over-serverize. If RLS already enforces access and nothing needs a secret or atomicity,
  a direct call is enough.
- Prefer a general Postgres skill (indexes, locking, pooling) for tuning. This skill's security
  rules win where they disagree.
- Fixtures are anonymised. Real personal or financial data never enters the repo.
