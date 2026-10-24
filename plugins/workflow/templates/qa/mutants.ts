/**
 * TEMPLATE. Copy to qa/mutants.ts. Keep the shape (`Mutant`, `SUITES`, `MUTANTS`) because
 * scripts/mutants.mjs imports it (Node strips the types). Adapt:
 *   - SUITES: the commands, run from the worktree's root, that judge a mutant. Each must pass on
 *     unmutated code, or the script reports "not judged".
 *   - MUTANTS: replace the two illustrative entries below with the project's own, with `<…>` paths
 *     filled in. Start from the non-negotiables, then add one for every bug QA or the owner found
 *     that a test should have held.
 *
 * Breakage checks: dangerous edits a later change could make by accident, each with the suite that
 * must turn red when it's made. `node scripts/mutants.mjs` applies each in a temporary git worktree
 * (never the working checkout) and reports any that survive: a survivor is a finding, a guard no test
 * holds.
 *
 * Each slice adds its own, for what it guards: an edit is `find` (which must occur exactly once in
 * `file`, or the check is stale and fails) replaced by `replace`. QA's reviewer proposes each probe
 * worth keeping as a new entry.
 */

export interface Mutant {
  id: string;
  /** What breaks, as a person or the data would suffer it. */
  breaks: string;
  file: string;
  find: string;
  replace: string;
  suite: SuiteId;
}

/** The suites a mutant can be judged by, as commands run in the worktree's root. */
export const SUITES = {
  // the database's tests (policies, constraints) then the API's tests and the route sweep, on a fresh QA database
  db: ['<package-manager>', '<run>', '<test:db>'],
  // a browser suite, for behaviour only a deployed or running app shows
  // e2e: ['<package-manager>', 'exec', 'playwright', 'test', '-c', '<config>', '-g', '<name>'],
} as const;
export type SuiteId = keyof typeof SUITES;

export const MUTANTS: Mutant[] = [
  {
    id: 'with-check-weakened',
    breaks: 'a person can move their own row to someone else (an RLS policy without its WITH CHECK)',
    file: '<path/to/the/migration-that-creates-the-policy.sql>',
    find: `USING (<table>.user_id = <current-user-expression>) WITH CHECK (<table>.user_id = <current-user-expression>)`,
    replace: `USING (<table>.user_id = <current-user-expression>) WITH CHECK (true)`,
    suite: 'db',
  },
  {
    id: 'row-lock-dropped',
    breaks: 'two identical writes sent at once both pass the check and log two changes',
    file: '<path/to/the/route-or-module-that-locks-the-row.ts>',
    find: `.where(eq(t.id, id)).for('update');`,
    replace: `.where(eq(t.id, id));`,
    suite: 'db',
  },
];
