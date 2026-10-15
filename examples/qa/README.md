# QA tooling, from Sen

Sen's working set for the `qa` skill's diff-driven run, to adapt rather than copy blind. Sen is a
Vite + React web app tested with Playwright at a phone viewport, in six looks (themes) × light and
dark. Paths below are Sen's.

| File | What it does | What to change |
|---|---|---|
| `catalogue.spec.ts` | Opens every catalogue entry (a screen, or a screen in a state) at a frozen clock in each theme and mode; records its accessibility tree (`toMatchAriaSnapshot`, one theme only), shoots the whole screen when `E2E_SHOTS` is set, and runs the scripted checks. A test fails when a screen in the app's registry has no entry or reason | Your screen registry, your catalogue (Sen's `catalogue.ts` lists entries as `{ id, screen, path, open? }`), how your app scrolls (Sen's scrolls inside a column, so the viewport is grown to the scroll height), how to wait for your app to settle |
| `checks.ts` | The scripted checks: axe (contrast), 48 px targets, clipped text, overlaps, a target under something fixed that scrolling can't free, the keyboard hiding a field or main button, an invisible focus ring | The target size, the keyboard height, what your dev tools add to the page |
| `checks.spec.ts` | Proves each check fires on a page built to break it and stays quiet on the same page fixed. Runs without a server | Nothing, unless you change a check |
| `diff.config.ts` | Playwright config for the diff: two projects, `base` and `head`, each served from its own build | Ports, build folders |
| `qa-diff.mjs` | Builds the default branch in a worktree and the branch, runs the catalogue against both, compares trees (`git show <base>:path`) and pixels (`pixelmatch`), and writes `qa-artifacts/<branch>/diff/index.md` and `index.json` | Build commands, paths, the looks list |
| `escapes.md` | A starting `qa/escapes.md` | Your own first entry |

**Make it deterministic before trusting it:** run the diff with the branch against itself (`--base HEAD`)
and expect nothing changed. Sen's causes of flicker, all fixed in the spec: data that arrived after
the first settle, a virtual list redrawing after a resize, a canvas drawn before its font loaded, and
a view transition. Never raise the pixel threshold to hide one.

Commit the trees, and set Playwright's `updateSnapshots` to `none` on CI, so a changed screen fails
until its tree is re-recorded. Keep behaviour (the journeys) in one theme; the catalogue covers the
rest.
