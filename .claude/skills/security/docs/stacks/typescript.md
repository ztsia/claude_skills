---
stack: TypeScript
last_checked: 2026-10-24
covers:
  - Node.js 22, 24, 26
  - Next.js 15 and 16 (App Router, server actions, route handlers, proxy.ts)
  - React 19 (including Server Components and server functions)
  - Hono 4
  - npm, pnpm, Bun
  - Supabase JS client, zod
sources:
  - https://nodejs.org/en/about/previous-releases  # supported Node.js lines and latest patch versions
  - https://nodejs.org/en/blog/vulnerability/october-2026-security-releases  # Node.js fixed versions and severities
  - https://nodejs.org/en/learn/getting-started/security-best-practices  # Node.js guidance: timeouts, prototype pollution, timing, supply chain
  - https://nodejs.org/docs/latest-v24.x/api/permissions.html  # permission model flags and limits
  - https://nextjs.org/support-policy  # supported Next.js majors
  - https://nextjs.org/blog/nextjs-security-update-october-14-2026  # Next.js patched versions
  - https://github.com/vercel/next.js/security/advisories  # Next.js advisories
  - https://nextjs.org/docs/app/guides/data-security  # DAL, server actions, taint, allowedOrigins
  - https://nextjs.org/docs/app/guides/content-security-policy  # nonce CSP through proxy.ts
  - https://nextjs.org/docs/app/guides/environment-variables  # NEXT_PUBLIC_ inlining, env files
  - https://github.com/react/react/security/advisories  # React Server Components advisories
  - https://github.com/react/react/security/advisories/GHSA-xqc2-xf4c-x3h3  # RSC remote code execution, patched versions
  - https://github.com/honojs/hono/security/advisories  # Hono advisories
  - https://hono.dev/docs/middleware/builtin/csrf  # Hono csrf middleware
  - https://hono.dev/docs/middleware/builtin/jwt  # Hono jwt middleware
  - https://hono.dev/docs/middleware/builtin/secure-headers  # Hono secureHeaders and nonce
  - https://hono.dev/docs/middleware/builtin/body-limit  # Hono bodyLimit
  - https://supabase.com/docs/guides/api/api-keys  # publishable and secret keys
  - https://pnpm.io/settings/build  # pnpm allowBuilds, strictDepBuilds
  - https://pnpm.io/supply-chain-security  # pnpm minimumReleaseAge, trustPolicy, blockExoticSubdeps
  - https://pnpm.io/cli/audit  # pnpm audit flags
  - https://docs.npmjs.com/cli/v11/using-npm/config  # npm ignore-scripts, min-release-age, audit-level, allow-git
  - https://bun.com/docs/runtime/bunfig  # Bun install settings
  - https://bun.com/docs/pm/lifecycle  # Bun trustedDependencies
  - https://bun.com/docs/pm/cli/audit  # bun audit flags and exit codes
---

# TypeScript

## Versions

| component | supported versions | below this, upgrade first |
|---|---|---|
| Node.js | 22, 24, 26 | 22.23.4, 24.22.1, 26.12.1 |
| Next.js | 16 (Active LTS), 15 (Maintenance LTS) | 16.4.1, 15.5.28 |
| React (`react`, `react-dom`) | 19.x | the RSC packages below set the floor |
| React Server Components packages (`react-server-dom-webpack`, `-turbopack`, `-parcel`) | 19.0, 19.1, 19.2, 19.3 | 19.0.9, 19.1.10, 19.2.9, 19.3.1 |
| Hono | 4.x | 4.13.11 |
| npm | 11.x and later | 11.10.0, for `min-release-age` |
| pnpm | 10.x and later | 10.0.0, for dependency scripts blocked by default |
| Bun | 1.x | the latest 1.x |

- Pin the exact patched version in the lockfile; a range that still resolves below the floor is a finding.
- Server Components and server functions run the same RSC packages wherever they are used (Next.js, Vite RSC, Parcel). Next.js bundles its own copy, so on Next.js the fix is the Next.js version; any other RSC framework needs the `react-server-dom-*` floor.

## Input and validation

- Parse every external value with zod at the boundary: `Schema.parse(raw)` throws, `Schema.safeParse(raw)` returns `{ success, error }`. Use `z.strictObject({...})` (or `.strict()`) so unknown keys are rejected rather than stripped silently into a model.
- Server actions take `unknown` and parse it, even when typed: the signature is a TypeScript annotation, and the wire carries whatever the caller sends. `FormData` is read with `Object.fromEntries(formData)` only into a schema.
- Route params, `searchParams`, headers and cookies are strings controlled by the caller. Validate dynamic segments (`[id]`) in the handler, not in the folder name.
- Cap sizes in the schema: `z.string().max(n)`, `z.array(...).max(n)`. In Hono add `bodyLimit({ maxSize })` from `hono/body-limit` before parsing; it checks `Content-Length` and counts streamed bytes when the header is absent. Under Bun, `Bun.serve` has its own default request limit (`maxRequestBodySize`) that applies before Hono.
- Hono's `c.req.parseBody()` is for forms; its dot-notation option accepts deeply nested keys, so keep `bodyLimit` in front and validate the result with zod.
- Hono validates with `zValidator('json', Schema)` (from `@hono/zod-validator`): the handler reads `c.req.valid('json')`, never `c.req.json()` again.

## Injection

- SQL: use the driver's parameters or a tagged template that binds values (the Next.js docs show `` sql`... ${slug}` ``). Never build SQL with `+` or an untagged template literal. Identifiers (table, column, `ORDER BY`) come from a fixed allowlist.
- Supabase JS: `.eq()`, `.in()`, `.match()` bind values. `.or('a.eq.' + input)` and `.filter()` with a built string parse the string as filter syntax, so untrusted text can add conditions; build those from validated values only.
- Processes: `child_process.execFile(cmd, args)` or `spawn(cmd, args)` with `shell: false` (the default). `exec()` and `shell: true` run a shell: acceptable only for a constant string with no input in it.
- `eval`, `new Function`, `vm.runInNewContext` on input, and dynamic `import(userInput)` are never acceptable; `vm` is not a security boundary.
- Prototype pollution: never recursive-merge or `Object.assign` parsed JSON into a shared object. Use `Object.create(null)` or a `Map` for caller-keyed data, check keys with `Object.hasOwn(obj, key)`, and reject `__proto__`, `constructor` and `prototype` keys. A zod strict schema removes them at the boundary.
- Regular expressions run on input need bounded input length; avoid nested quantifiers. A long-running regex blocks the single event loop for every request.
- Template and header values: reject `\r` and `\n` in anything placed in a response header or an email header.

## Output and XSS

- JSX and React escape text and attribute values. The escape hatches are `dangerouslySetInnerHTML`, `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write` and `href`/`src`/`action` set to an unchecked string.
- When HTML must be rendered, sanitise on the server with an allowlist sanitiser (DOMPurify with jsdom, or `sanitize-html`) immediately before `dangerouslySetInnerHTML`, and render Markdown to HTML before sanitising.
- Check a user-supplied URL with `new URL(value)` and accept only `protocol === 'https:'` (or a relative path); `javascript:` and `data:` URLs execute.
- JSON placed in a `<script>` tag: serialise with `JSON.stringify(x).replace(/</g, '\\u003c')`. Next.js and React do this for their own payloads.
- `hono/jsx` escapes by default; `raw()` and `html` helpers bypass it. Never `memo()` a component whose output depends on the caller: it is reused across requests.
- CSP in Next.js: generate the nonce in `proxy.ts` (`crypto.randomUUID()`, base64), set it in `Content-Security-Policy` with `'strict-dynamic'`, `object-src 'none'`, `base-uri 'self'`, `frame-ancestors 'none'`, and pass it on in a request header (`x-nonce`) for `next/script`. A nonce needs dynamic rendering (`await connection()`); static pages and Partial Prerendering cannot carry it. For static pages use `experimental.sri` hashes plus a header CSP from `next.config.js`.
- CSP in Hono: `secureHeaders({ contentSecurityPolicy: { scriptSrc: [NONCE] } })`, read the value with `c.get('secureHeadersNonce')`.

## Auth, sessions and access

- Use a maintained auth library or provider (Supabase Auth, Auth.js, Clerk, a provider SDK). Sessions are read on the server: `cookies()` from `next/headers` (async, `await` it) in Next.js; `hono/cookie` in Hono.
- Set cookies with `httpOnly: true, secure: true, sameSite: 'lax', path: '/'` and the `__Host-` prefix. Never put a session token in `localStorage` or a URL.
- A server action is a public POST endpoint reachable without the page that renders it. Check the session and the caller's right to the specific object inside every action; a check in the page, layout or `proxy.ts` does not cover it. Put the check in a `server-only` data access layer and keep the action thin.
- `proxy.ts` is a first filter. It does not run for a server action called from another page's route; re-check in the handler.
- Return only the fields the caller may see. Server action return values and props passed to Client Components are serialised to the browser, so pass a DTO, never a database row.
- Hono: `jwt({ secret, alg: 'HS256', verification: { iss, aud } })` requires `alg`; set `iss` and `aud` so they are checked, and leave `exp`, `nbf`, `iat` checks on. `c.get('jwtPayload')` holds verified claims only after this middleware ran on that route; routes outside its path pattern are unauthenticated.
- CSRF: Next.js server actions accept POST only and compare `Origin` to `Host`/`X-Forwarded-Host`; behind a proxy with a different host set `experimental.serverActions.allowedOrigins`. Route handlers (`route.ts`) get no such check: a cookie-authenticated `POST`, `PUT`, `PATCH` or `DELETE` handler checks `Origin` itself. Hono: `app.use(csrf({ origin: [...] }))` from `hono/csrf`; it only inspects form-type content types (`application/x-www-form-urlencoded`, `multipart/form-data`, `text/plain`), so a JSON endpoint authenticated by cookie needs `Content-Type` enforcement or a token.
- CORS: `hono/cors` with an exact `origin` array; a function that reflects the request origin is a finding.
- Compare secrets and tokens with `crypto.timingSafeEqual` on equal-length `Buffer`s (compare hashes to equalise length). Hash passwords with `crypto.scrypt` or a maintained Argon2id/bcrypt library, not a fast hash.

## Secrets and configuration

- Only `NEXT_PUBLIC_`-prefixed variables reach the browser, and they are inlined into the bundle at `next build`: never prefix a key, a database URL or a Supabase secret key. Dynamic lookups (`process.env[name]`) are not inlined and so are not exposed that way, but do not rely on that.
- Read `process.env` in one server-only module (`import 'server-only'`), so a client import fails the build. For values that must not cross to the client, `experimental.taint` enables `experimental_taintObjectReference` and `experimental_taintUniqueValue`; they are an extra layer, not a replacement for returning DTOs.
- Keep `.env*.local` and every file with real values in `.gitignore`; commit only `.env.example` with placeholders. Validate required variables at startup with zod and fail the process if one is missing.
- Supabase: the publishable key (`sb_publishable_...`, legacy `anon`) can ship in client code and relies on RLS. The secret key (`sb_secret_...`, legacy `service_role`) bypasses RLS and is used only in server code that has already authorised the caller, with a variable name that has no framework public prefix. Do not create the secret client at module top level in a file a Client Component can import.
- Closures captured by an inline `'use server'` function are encrypted for transport; do not rely on that to hide secrets. With several self-hosted instances set `NEXT_SERVER_ACTIONS_ENCRYPTION_KEY` (base64 of 16, 24 or 32 bytes) so all instances share one key.
- Error responses carry a generic message. Next.js production builds hide server error detail from the client; do not return `error.message` from an action.

## Files, paths and outbound requests

- Paths from input: `path.resolve(root, name)`, then check `resolved.startsWith(root + path.sep)`; for existing files resolve with `fs.realpath` first so symlinks are followed before the check. Never `path.join(root, input)` alone: `..` segments walk out of it.
- Next.js `next/image`: restrict `images.remotePatterns` to exact hosts and paths. `dangerouslyAllowSVG` lets the optimizer process SVG; leave it off unless required, and pair it with the image CSP option. Image optimization is part of the server's attack surface: keep `sharp` on its latest release.
- Fetching a URL from input: parse with `new URL()`, require `https:`, resolve with `dns.promises.lookup(host, { all: true })`, refuse loopback, private, link-local and metadata addresses, connect to the address checked, and set `redirect: 'manual'` on `fetch` so each hop is re-checked. Set `signal: AbortSignal.timeout(ms)` and cap the bytes read.
- Next.js `rewrites()` take their destination host from config, never from a request value.
- Uploads: `request.formData()` reads the whole body into memory; cap `Content-Length` first (`bodyLimit` in Hono; in Next.js check the header in the route handler and set `experimental.serverActions.bodySizeLimit` for actions). Check type from content with a magic-byte library (`file-type`), store under a generated name, serve with `Content-Disposition: attachment`.
- Node's permission model (`node --permission --allow-fs-read=... --allow-fs-write=...`) narrows what trusted code can do. It is a guard against mistakes, not a sandbox for hostile code.
- HTTP servers created with `node:http`: set `headersTimeout`, `requestTimeout` and `keepAliveTimeout`, attach an `'error'` handler to sockets, and never enable `insecureHTTPParser`.

## Deserialization and parsing

- `JSON.parse` returns data only; follow it with a zod parse. Never use `eval`, `new Function` or `vm` to read data. Do not use `node-serialize`, `serialize-javascript` in reverse, or `js-yaml` `load` with unsafe schemas on input; YAML goes through the safe default loader.
- RSC and server functions deserialise request payloads inside the framework, so the *Versions* floors for React and Next.js are a security control, not routine upkeep, and apply whether or not the code looks affected.
- XML: use a parser with external entities and DTDs disabled. Zip and tar extraction caps entry count and unpacked bytes and checks each resolved path against the target root.
- Large `Content-Length` or deep JSON nesting is a denial-of-service input; cap before parsing.

## Crypto and randomness

- Tokens, session ids, reset codes and nonces: `crypto.randomBytes(32)`, `crypto.randomUUID()` or `crypto.getRandomValues()`. `Math.random()` is never acceptable for these. `crypto.randomInt(max)` for bounded integers.
- Encrypt with `crypto.createCipheriv('aes-256-gcm', key, iv)` with a fresh 12-byte random IV per message and verify the auth tag; or use a vetted library (`jose`, libsodium). No ECB, no static IV, no custom schemes.
- JWTs: `jose` `jwtVerify(token, key, { algorithms: ['...'], issuer, audience })` with the algorithm pinned.
- Webhooks: verify the signature over the raw body (`await request.text()` before any JSON parse) with the provider's library, or HMAC SHA-256 plus `crypto.timingSafeEqual`.

## Dependencies

- Install from the lockfile and fail on drift: `npm ci`, `pnpm install --frozen-lockfile`, `bun install --frozen-lockfile`.
- Block dependency lifecycle scripts, then allow by name:
  - npm: `ignore-scripts=true` in `.npmrc`; run needed builds explicitly.
  - pnpm (`pnpm-workspace.yaml`): `allowBuilds:` mapping package to `true`/`false`; `strictDepBuilds` (default `true`) fails the install on a dependency with an unreviewed build script. Never set `dangerouslyAllowAllBuilds`.
  - Bun: runs scripts only for `trustedDependencies` in `package.json` plus its built-in list of popular packages; set `"trustedDependencies": []` to run none, or `install.ignoreScripts = true` in `bunfig.toml`.
- Hold back new releases: npm `min-release-age=<days>` (`.npmrc`, npm 11.10.0+); pnpm `minimumReleaseAge: <minutes>` (e.g. `10080` is one week) in `pnpm-workspace.yaml`; Bun `[install] minimumReleaseAge = <seconds>` in `bunfig.toml` (e.g. `604800`). Exclusions are `min-release-age-exclude`, `minimumReleaseAgeExclude`, `minimumReleaseAgeExcludes`.
- pnpm `blockExoticSubdeps: true` refuses transitive dependencies from git or tarball URLs; `trustPolicy: no-downgrade` refuses a version whose publishing trust is lower than earlier ones. npm `allow-git=none` (or `root`) blocks git dependencies.
- Audit levels: npm `audit-level` sets the lowest severity that exits non-zero; pnpm `--audit-level`; Bun `--audit-level` (exit `1` when findings remain or the registry response is unreadable).
- Add `server-only` to server modules, and keep server SDKs (database drivers, Supabase secret client) out of any file a `'use client'` module imports.

## Framework pitfalls

- A page-level redirect for non-admins does not protect an action defined in that page: the action re-authorises.
- `revalidatePath`, `revalidateTag` and `redirect()` do not authorise anything. `redirect(target)` takes only a relative path starting with a single `/` or an allowlisted origin.
- `use cache` and other server-side caches are keyed by their arguments and the build; pass the user or tenant id as an argument for per-user data, and never cache a response built from `cookies()` or `headers()` across callers.
- Self-hosted ISR and SSG: the CDN never keys a personalised page on the URL alone.
- Fetch in Server Components forwards no cookies on its own; when it calls your own API with a user's cookie, the API still authorises (zero-trust).
- Route handlers (`route.ts`) are public endpoints: no implicit auth, no CSRF check, no body limit.
- Server action arguments can be any serialisable value, including large payloads: validate and cap them like a request body.
- Hono: HEAD is routed to the GET handler, so auth and rate limits on GET apply to HEAD and a separate `app.head()` never runs. Put authentication on the route itself, not only on a path-prefix middleware.
- Hono on Node, Bun or serverless: the adapter decides client IP and header handling (`getConnInfo`); trust `X-Forwarded-For` only behind a proxy you control.
- `NODE_ENV` and `next dev` expose dev-only behaviour (including a Model Context Protocol endpoint in the dev server); never expose a dev server to a network.

## Checks to run

```bash
# dependency audit: non-zero exit fails the CI step
npm audit --audit-level=high               # npm
pnpm audit --audit-level high               # pnpm
bun audit --audit-level=high                # Bun
npm audit signatures                        # registry signatures and provenance (npm)
osv-scanner scan source --lockfile=package-lock.json   # one scanner across lockfiles (pnpm-lock.yaml, bun.lock also accepted)

# frozen installs
npm ci
pnpm install --frozen-lockfile
bun install --frozen-lockfile

# static analysis for security
npx eslint . --max-warnings=0               # with eslint-plugin-security and eslint-plugin-no-unsanitized, and Next's eslint-config-next
semgrep scan --config p/typescript --config p/nextjs --config p/react --error --metrics=off   # semgrep installs with pipx or pip

# secrets
gitleaks git --redact --exit-code 1
```

- `eslint-plugin-security` rule set `plugin:security/recommended-legacy` (or the flat-config `recommended`) flags `detect-child-process`, `detect-eval-with-expression`, `detect-non-literal-fs-filename`, `detect-non-literal-regexp`, `detect-unsafe-regex`, `detect-object-injection`; `eslint-plugin-no-unsanitized` flags `innerHTML`, `insertAdjacentHTML`; `react/no-danger` flags `dangerouslySetInnerHTML`. Set them to `error`; ESLint exits non-zero on any error, and `--max-warnings=0` makes warnings fail too.
- `semgrep --error` exits non-zero on any finding; `--metrics=off` stops telemetry.
- Run `tsc --noEmit` with `strict: true` in the same job; `any` at a boundary hides the missing parse.
- Add a test that calls each server action and route handler with no session, with another user's id, and with an extra field, and expects no data and no change.
- `next build` fails on a client import of a `server-only` module; keep that build in CI.
