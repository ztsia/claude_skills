---
stack: Go
last_checked: 2026-10-24
covers:
  - Go 1.27 and 1.26 (standard library net/http, html/template, database/sql, os/exec, os, crypto)
  - github.com/go-chi/chi v5
  - github.com/jackc/pgx v5
  - golang.org/x/net (http2) and golang.org/x/crypto (bcrypt, argon2)
sources:
  - https://go.dev/doc/devel/release  # supported versions and latest patch releases
  - https://go.dev/doc/security/best-practices  # govulncheck, vet, race detector, fuzzing
  - https://pkg.go.dev/vuln/list  # Go vulnerability database entries
  - https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck  # modes, formats, exit codes
  - https://pkg.go.dev/net/http  # Server timeouts, MaxBytesReader, ServeMux, CrossOriginProtection
  - https://pkg.go.dev/html/template  # contextual escaping and the typed strings that skip it
  - https://pkg.go.dev/os  # os.Root
  - https://pkg.go.dev/os/exec  # no shell, ErrDot, CommandContext
  - https://pkg.go.dev/crypto/rand  # Read, Text
  - https://pkg.go.dev/github.com/go-chi/chi/v5  # middleware, ClientIPFrom*
  - https://github.com/go-chi/chi/security/advisories  # chi advisories
  - https://pkg.go.dev/github.com/jackc/pgx/v5  # parameters, query exec modes
  - https://github.com/jackc/pgx/security/advisories  # pgx advisories
  - https://github.com/securego/gosec  # gosec usage and exit codes
---

# Go

## Versions

| component | supported versions | below this, upgrade first |
|---|---|---|
| Go | 1.27, 1.26 (the two newest majors) | 1.27.2 on 1.27; 1.26.9 on 1.26 |
| github.com/go-chi/chi | v5 | 5.4.0 (5.5.0 if `SupressNotFound` is used) |
| github.com/jackc/pgx | v5 | 5.9.2 |
| golang.org/x/net | current | 0.60.0 |

- Run the newest patch of the Go major in use: patch releases carry the `net/http`, `mime/multipart`
  and `html/template` security fixes, and the `crypto/x509` denylist of untrustworthy intermediates.

## Input and validation

- Decode JSON with `json.NewDecoder(http.MaxBytesReader(w, r.Body, limit))` and call
  `dec.DisallowUnknownFields()`, so a client cannot set fields the struct has but the handler did not
  intend. Decode into a dedicated request struct, never into the database model.
- In Go 1.26 and earlier, `encoding/json` matches keys case-insensitively and accepts duplicate
  names and invalid UTF-8. In 1.27 it uses the v2 implementation, which rejects all three by default.
  Validation must give the same answer on both.
- Set `Server.ReadHeaderTimeout`, `ReadTimeout`, `WriteTimeout`, `IdleTimeout` and `MaxHeaderBytes`.
  `http.ListenAndServe` and a zero `http.Server` apply no timeouts: use an explicit `&http.Server{}`.
  `Server.MaxHeaderValueCount` (1.27) caps header values.

## Injection

- SQL: pass values as arguments, never through `fmt.Sprintf` or `+`. `database/sql` takes them through
  `QueryContext(ctx, "... WHERE id = $1", id)` (placeholder style depends on the driver); pgx uses
  `$1, $2` and `pgx.NamedArgs` (`@name`).
- Identifiers (table, column, sort order) cannot be parameters: map input to a fixed allowlist of
  names, or use `pgx.Identifier{...}.Sanitize()` for a table name.
- pgx's default query mode uses protocol-level prepared statements. Avoid `QueryExecModeSimpleProtocol`
  (client-side interpolation); pgx's docs prefer `QueryExecModeExec`.
- Use the `*Context` variants (`QueryContext`, `ExecContext`, `BeginTx`) so a cancelled request stops
  the query. Set `SetMaxOpenConns`: the default is unlimited.
- Processes: `exec.CommandContext(ctx, "convert", "--", file)` with a literal program name and one
  argument per element. `os/exec` never starts a shell; `exec.Command("sh", "-c", s)` or `cmd /c` with
  input in `s` is command injection. Put `--` before user-chosen file names and reject names starting
  with `-`.
- `exec.Command` and `LookPath` refuse a program found in the current directory (`ErrDot`); never set
  `GODEBUG=execerrdot=0`. Set `Cmd.Env` explicitly (a fresh slice) so secrets in the parent
  environment don't reach the child, and set `WaitDelay` so `Wait` can't block on orphaned pipes.

## Output and XSS

- Render HTML with `html/template`, which escapes by context (text, attribute, URL, CSS, JavaScript).
  Import `text/template` only for non-HTML output (plain text email, config files).
- The escape hatches are the typed strings `template.HTML`, `HTMLAttr`, `JS`, `JSStr`, `CSS`, `URL`
  and `Srcset`: converting input to one of them switches escaping off. Use them only on output of a
  sanitiser (for example bluemonday with an allowlist policy) or on constants.
- A user URL that fails the scheme check is rewritten to `#ZgotmplZ`. Validate `https:` or relative
  yourself before putting it in `href`; don't wrap it in `template.URL` to silence that.
- Templates are trusted, data is not. Never build template text with input, and never `template.JS`
  untrusted JSON: marshal with `json.Marshal` and pass the value to the template, which encodes it.

## Auth, sessions and access

- Use a maintained auth or session library, or an identity provider; there is no session store in the
  standard library. Cookies are built with `http.Cookie{Name: "__Host-sid", Path: "/", Secure: true,
  HttpOnly: true, SameSite: http.SameSiteLaxMode}`: a zero `Cookie` sets none of these flags.
- Passwords: `argon2.IDKey` (golang.org/x/crypto/argon2) with a random 16-byte salt and the RFC 9106
  parameters the docs list (time 1, 2 GiB, 4 threads; or time 3, 64 MiB, 4 threads), or
  `bcrypt.GenerateFromPassword` with cost at least `DefaultCost`. bcrypt rejects passwords over 72
  bytes (`ErrPasswordTooLong`): check length first. Verify with `bcrypt.CompareHashAndPassword`.
- Compare secrets, tokens and MACs with `subtle.ConstantTimeCompare` or `hmac.Equal`, never `==` or
  `bytes.Equal`. `ConstantTimeCompare` returns early on different lengths, so compare fixed-length
  hashes of the values.
- CSRF: wrap the mux with `http.NewCrossOriginProtection().Handler(mux)`. It rejects non-safe
  cross-origin browser requests using `Sec-Fetch-Site` or `Origin` versus `Host`, with 403. GET, HEAD
  and OPTIONS are exempt, so they never change state. Requests carrying neither header are treated as
  non-browser. `AddTrustedOrigin` and `AddInsecureBypassPattern` widen it; each entry is a hole.
- Authorisation lives in the handler or data layer: load by `id AND owner_id`. A chi middleware on a
  group is a first filter.
- Client IP for rate limits and allowlists: chi's `middleware.RealIP` is deprecated and spoofable.
  Use exactly one `ClientIPFromRemoteAddr` (no proxy), `ClientIPFromHeader` (a header the edge proxy
  sets), `ClientIPFromXFF` with CIDRs, or `ClientIPFromXFFTrustedProxies`, then `GetClientIP`.

## Secrets and configuration

- Read secrets with `os.Getenv` or a secret manager at start-up into a config struct; fail fast when
  one is missing. Never default a secret to a literal.

## Files, paths and outbound requests

- Confine file access with `os.OpenRoot(dir)` then `root.Open`, `root.ReadFile`, `root.Create`,
  `root.OpenFile`; a name that leaves the root, including through a symlink, returns an error.
  `root.FS()` gives an `fs.FS` that stops symlink escapes.
- `filepath.Join(base, name)` doesn't contain `..`. `filepath.IsLocal(name)` is a lexical check that
  guarantees the joined path stays inside `base` but ignores symlinks, so use it with `os.Root`, or
  alone only where the directory holds no symlinks.
- `http.Dir` follows symlinks out of the tree and serves dot-files; `http.FileServer(http.Dir(...))`
  on a directory with uploads or secrets is a leak. Serve `http.FS(root.FS())` and filter dot-files.
- Uploads: `http.MaxBytesReader` first, detect type with `http.DetectContentType` on the first 512
  bytes, store under a generated name (`uuid` or `rand.Text()`), never the client's file name.
- `archive/zip` entries: reject names that fail `filepath.IsLocal`, and cap entry count and the sum of
  `UncompressedSize64` while copying with `io.LimitReader`. `zip.NewReader` returns `ErrInsecurePath`
  for unsafe names only when `GODEBUG=zipinsecurepath=0` is set.
- Outbound requests: build an `http.Client{Timeout: ...}`; `http.DefaultClient` and `http.Get` have
  no timeout. Cap the response with `io.LimitReader`.
- SSRF: set `net.Dialer.Control` (or `ControlContext`) on the transport's dialer to parse the resolved
  address with `netip.ParseAddrPort` and refuse `IsLoopback`, `IsPrivate`, `IsLinkLocalUnicast`,
  `IsUnspecified` and multicast. Because it runs on the address actually dialled, DNS rebinding can't
  bypass it. Set `CheckRedirect` to refuse or re-validate redirects. `http.Transport` honours
  `HTTP_PROXY`; set `Proxy: nil` for fetches of user URLs unless a proxy is intended.

## Deserialization and parsing

- `encoding/json`, `encoding/xml`, `encoding/gob` and `encoding/asn1` decode into typed values and
  run no code, but unbounded input is a memory risk: cap the reader. Decode into concrete structs,
  not `map[string]any`, wherever the shape is known.

## Crypto and randomness

- Tokens, session ids, reset codes, salts and nonces come from `crypto/rand`: `rand.Text()` for a
  ready string with at least 128 bits, or `rand.Read(b)` (never returns an error). `math/rand` and
  `math/rand/v2` are for non-secret uses only.
- Encryption: `crypto/aes` with `cipher.NewGCM` and a fresh random nonce per message, or
  `golang.org/x/crypto/chacha20poly1305` / `XChaCha20-Poly1305`; never ECB, never a reused nonce,
  never `crypto/des` or `crypto/rc4`.
- TLS: keep `tls.Config` defaults. `InsecureSkipVerify: true` is a vulnerability outside a test. Set
  `MinVersion: tls.VersionTLS12` only when raising an older default; never lower it.

## Dependencies

- `go.mod` and `go.sum` are committed. CI builds with `-mod=readonly` (`go build -mod=readonly ./...`)
  so nothing resolves anew, and runs `go mod verify`.
- `replace` directives are not authenticated. Keep them out of released `go.mod` files.
- `go list -m -u all` lists updates; review each in a pull request, grouped, after a cooldown
  (`docs/supply-chain.md`). `go mod tidy` runs and its diff is reviewed.

## Framework pitfalls

- `net/http` `ServeMux`: patterns carry a method and host (`"POST /notes/{id}"`); a method-less
  pattern serves every method, so state-changing routes name theirs. Request paths are cleaned and
  redirected before matching; trailing-slash behaviour is explicit.
- Always `return` after `http.Error` or `http.Redirect`; execution continues otherwise and a write
  after an auth failure still runs.
- Goroutines started from a handler outlive the request: copy the values needed (chi's routing context
  needs `Context.Clone()`), use a context not tied to `r.Context()` for work meant to continue, and
  re-check authorisation inside background jobs.
- chi: `{name}` matches up to the next `/`, `*` matches the rest of the path including `/`, and
  `{name:regex}` uses RE2. Trailing slashes are handled explicitly. `middleware.RedirectSlashes` and
  `StripSlashes` run before auth middleware only when placed there; order middleware as recover,
  headers, client IP, rate limit, auth.

## Checks to run

```sh
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...                      # source mode; exit 1 when a reachable vulnerability is found
govulncheck -mode binary ./bin/app     # the built artifact
govulncheck -format sarif ./... > govulncheck.sarif   # exits 0 whatever it finds: fail the job on the file's results instead

go vet ./...                           # nonzero exit on any finding
go test -race ./...                    # nonzero exit on a failing test or detected race
go mod verify                          # nonzero exit when a cached module differs from go.sum

go install github.com/securego/gosec/v2/cmd/gosec@latest
gosec -severity medium -confidence medium ./...   # exit 1 on any unsuppressed finding at or above those levels
gosec -fmt sarif -out gosec.sarif ./...           # for code scanning upload
```

- CI runs each command as its own step; a nonzero exit fails the job. Don't pass `-no-fail` to gosec
  or add `|| true`.

