# Web applications and APIs

What must hold in any web product, whatever the stack. The stack notes name the APIs.

## Access control

- **Check on the server, per object, per request.** Load the object scoped to the caller
  (`where id = $1 and owner_id = $2`, or a tenant id), or let RLS scope it. Checking the role and then
  loading by id alone lets any signed-in person read any row (IDOR).
- **Every way in gets the same check:** the page, its API route, the server action, the export, the
  search, the GraphQL field, the realtime channel, the signed URL generator. The one forgotten path
  is the vulnerability.
- **Middleware is a first filter, not the check.** A route reached another way (an internal rewrite,
  a server action, a direct API call) skips it. The handler or the data layer checks again.
- **Writes check the target and every reference in the body.** Moving a note into a folder checks
  that the caller owns both.
- **Mass assignment:** build the update from named fields. Never spread the request body into a
  model; a client adds `role`, `isAdmin`, `ownerId`, `price` or `tenantId`.
- **Multi-tenant data:** the tenant comes from the session, never from the request. Caches, search
  indexes, file paths and queues are keyed by tenant too.
- **Enumeration:** "not found" and "forbidden" return the same status and body. Public ids are random
  (UUIDs), so counts and neighbours can't be read off them; that is hygiene, not access control.

## Authentication and sessions

- Use the auth provider's or framework's flows: sign-in, sign-up, magic links, OAuth, MFA, password
  reset. A hand-built flow misses token binding, expiry and rotation.
- **Passwords:** hashed with Argon2id, scrypt or bcrypt through a maintained library; never a fast
  hash, never encrypted. A minimum length of 8, a maximum of at least 64, checked against breached
  lists where the provider offers it; no composition rules.
- **Session cookies:** `HttpOnly`, `Secure`, `SameSite=Lax` (or `Strict`), `Path=/`, a `__Host-`
  prefix where the framework allows. A session id is opaque and random; a JWT in a cookie is signed
  and checked for `exp`, `aud` and `iss`, with the algorithm pinned.
- **Rotate the session id at sign-in and privilege change; revoke sessions at sign-out, password
  change and account deletion.** A token stored in `localStorage` is readable by any script on the
  page; prefer the cookie.
- **Tokens in links** (reset, invite, verify, magic link): random, single-use, short-lived, stored
  hashed, compared in constant time, and invalidated when used or when a newer one is issued.
- **OAuth:** `state` checked, PKCE used, redirect URIs registered exactly, the `id_token` verified,
  accounts linked only by a verified email.
- **Same response, same timing** for "no such account" and "wrong password", and for reset requests.
- **Rate limits** on sign-in, codes, reset and invitations, per account and per IP; lock or slow down
  after repeated failures, and alert on bursts.

## CSRF

- A cookie-authenticated request that changes state needs a defence: `SameSite=Lax` or `Strict`
  cookies plus a check of `Origin` (or a CSRF token from the framework). Next.js server actions
  compare `Origin` with the host; frameworks with CSRF middleware keep it on.
- Never change state on `GET`. A bearer token in a header isn't sent by the browser on its own, so
  it doesn't need CSRF protection; a cookie does.

## CORS

- No CORS headers unless another origin must call the API. Then an exact allowlist of origins, never
  a reflected `Origin`, never `*` with credentials, never a pattern a lookalike domain can match.
- CORS doesn't protect a server: it only tells browsers what to share. The API still authenticates.

## Headers and the browser

- `Content-Security-Policy` with nonces or hashes for scripts (`script-src 'nonce-…' 'strict-dynamic'`),
  `object-src 'none'`, `base-uri 'none'`, `frame-ancestors` set. Start in report-only when adding it
  to an existing app.
- `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, a
  `Permissions-Policy` that turns off what the app doesn't use, `frame-ancestors 'none'` (or
  `X-Frame-Options: DENY`) unless the app is meant to be framed.
- HSTS only once every subdomain serves HTTPS; it can't be withdrawn quickly.
- `Secure` cookies and HSTS are set for production; local development over plain HTTP keeps them
  behind an environment check, never removed.

## Cross-site scripting

- The framework's escaping covers text in templates and JSX. The escape hatches are the risk:
  `dangerouslySetInnerHTML`, `v-html`, `|safe`, `mark_safe`, `template.HTML`, `innerHTML`,
  `insertAdjacentHTML`, `document.write`.
- **URLs are a separate context:** a user-supplied `href` or `src` is checked to be `https:` (or a
  relative path); `javascript:` and `data:` URLs run script.
- Markdown rendered to HTML is sanitised after rendering. A sanitiser runs with an allowlist of tags
  and attributes, on the final HTML.
- JSON embedded in a page is serialised with the framework's safe serialiser, so `</script>` in data
  can't close the tag.
- `postMessage` handlers check `event.origin` against an exact value and validate the message.

## SSRF and outbound requests

- When a URL comes from input (an avatar URL, a webhook target, an import, a link preview), prefer a
  fixed allowlist of hosts.
- Otherwise: allow only `https`, resolve the host, refuse loopback, private (RFC 1918, `fc00::/7`),
  link-local (`169.254.0.0/16`, which includes cloud metadata), and unspecified addresses, connect to
  the address you checked, and re-check on every redirect (or follow none).
- Timeouts on connect and read, a cap on the response size, and no response body echoed back to the
  caller verbatim.
- Outbound requests never carry the server's own credentials to a host chosen by input.

## Redirects

- Redirect targets from input (`?next=`, `returnTo`) are relative paths starting with a single `/`
  (not `//`, not `/\`), or an exact allowlisted origin.

## Uploads and files

- Cap size before reading the body, cap count, and reject what the feature doesn't need.
- Decide the type from the content (magic bytes), not the extension or `Content-Type`. Store under a
  generated name; keep the original name only as metadata, sanitised for display.
- Serve uploads from private storage through signed, expiring URLs, or from a separate origin, with
  `Content-Disposition: attachment` for anything not meant to render. SVG and HTML uploads render
  script when served inline from the app's origin.
- Re-encode images shown to other people; it drops metadata (location) and payloads.
- Archives: cap the entry count and total unpacked size, and reject entries whose resolved path
  leaves the target directory.
- File paths from input resolve under a fixed root, and the resolved path is checked to still be
  inside it.

## Webhooks and callbacks

- **Incoming:** verify the provider's signature over the raw body with its library, before parsing;
  reject old timestamps; store the event id under a unique constraint so a replay is a no-op; respond
  fast and do the work in a job. For money or access, re-fetch the object from the provider.
- **Outgoing:** sign each payload with a per-customer secret, include a timestamp, send only to
  validated URLs (*SSRF*), and time out.

## Rate limits and abuse

- Limit by account and by IP, with a stricter limit on anonymous traffic: sign-in, sign-up, codes,
  reset, invites, search, exports, uploads, email and SMS sending, and model calls.
- Anything that spends money per request (SMS, model calls, third-party APIs) has a per-account
  budget and an alert.
- Cap pagination (`limit` ≤ a fixed maximum), query complexity (GraphQL depth and cost), and request
  body size.
- Regular expressions run on input are linear-time or bounded in input length.

## Errors, logging and personal data

- Clients get a status and a short message. Stack traces, SQL, internal ids and library versions stay
  in logs; production error pages don't show them.
- Logs record security events (sign-in, failure, role change, denied access, export) with who, what
  and when, and never record passwords, tokens, keys, full card numbers or full personal records.
- Personal data collected is what the feature needs; it is deleted when the account is, including from
  backups' retention, exports and search indexes.

## Caching

- A response that depends on who is asking is `Cache-Control: private` or `no-store`, never cached by
  a CDN or a shared server cache keyed only by URL.
- Server-side caches (framework data caches, memoisation, `fetch` caches) are keyed by everything the
  result depends on, including the user or tenant.
- Pages with personal data aren't statically generated or cached at the edge.
