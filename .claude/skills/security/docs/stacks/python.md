---
stack: Python
last_checked: 2026-10-24
covers:
  - CPython 3.11, 3.12, 3.13, 3.14, 3.15
  - FastAPI 0.x (0.162 current) with Starlette 1.x and Pydantic 2.x
  - Django 5.2 LTS, 6.0, 6.1, with Django REST Framework 3.18
  - Flask 3.1 with Werkzeug 3.1 and Jinja2 3.1
  - SQLAlchemy 2.x
  - pip, uv, Poetry
sources:
  - https://www.python.org/downloads/  # supported CPython series and latest patches
  - https://docs.python.org/3/library/tarfile.html  # extraction filters
  - https://docs.python.org/3/library/pickle.html  # unpickling warning, find_class, hmac
  - https://www.djangoproject.com/download/  # supported Django series
  - https://docs.djangoproject.com/en/dev/releases/security/  # Django security releases
  - https://docs.djangoproject.com/en/dev/howto/deployment/checklist/  # deployment checklist, check --deploy
  - https://www.django-rest-framework.org/community/release-notes/  # DRF releases and security fixes
  - https://flask.palletsprojects.com/en/stable/web-security/  # Flask security considerations
  - https://github.com/Kludex/starlette/security/advisories  # Starlette advisories
  - https://github.com/pallets/werkzeug/security/advisories  # Werkzeug advisories
  - https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/  # FastAPI JWT and password hashing
  - https://docs.astral.sh/uv/reference/settings/  # uv exclude-newer, index-strategy
  - https://pip.pypa.io/en/stable/topics/secure-installs/  # pip hash-checking mode
  - https://github.com/pypa/pip-audit  # pip-audit usage and exit codes
  - https://docs.astral.sh/ruff/rules/  # Ruff flake8-bandit (S) rules
---

# Python

## Versions

| component | supported versions | below this, upgrade first |
|---|---|---|
| CPython | 3.15, 3.14 (bugfix); 3.13, 3.12, 3.11 (security only) | latest patch of the series: 3.15.1, 3.14.9, 3.13.17, 3.12.15, 3.11.17 |
| FastAPI | 0.x line (0.162 current), Python 3.10+ | any release that resolves Starlette 1.3.1 or later |
| Starlette | 1.x | 1.3.1 (1.1.0 for `StaticFiles` on Windows) |
| Pydantic | 2.x (FastAPI needs 2.9+) | 2.9 |
| Django | 6.1, 6.0, 5.2 LTS | 6.1.2, 6.0.9, 5.2.18 |
| Django REST Framework | 3.18 (Django 6.1 support) | 3.18.2 |
| Flask | 3.1 | 3.1.3 |
| Werkzeug / Jinja2 | 3.1 / 3.1 | 3.1.0 / 3.1.2 |
| SQLAlchemy | 2.0, 2.1 | 2.0 |
| pip, uv, Poetry | the current release of each | the current release |

- Django 4.2, 5.0 and 5.1 receive no fixes; use 5.2 LTS or later. Take every patch release of the series.

## Input and validation

- FastAPI: bodies are Pydantic models; query, path, header and cookie values use `Query`, `Path`,
  `Header`, `Cookie` with constraints (`max_length`, `ge`, `pattern`).
- Pydantic ignores unknown fields: set `model_config = ConfigDict(extra="forbid")` on input models. Use separate
  output models; `response_model=` filters the response. `model_construct()` skips validation: never on request data.
- Django: validate with `Form`, `ModelForm` or a DRF `Serializer` and list fields (`fields = [...]`).
  `fields = "__all__"` or `exclude` exposes new columns, including `is_staff` and `owner`.
- Django: `DATA_UPLOAD_MAX_NUMBER_FIELDS` and `DATA_UPLOAD_MAX_MEMORY_SIZE` do not limit uploads or the whole body: cap it at the proxy.
- Flask has no validation layer: use Pydantic or a schema library, and set `MAX_CONTENT_LENGTH`
  (unset by default), `MAX_FORM_MEMORY_SIZE` and `MAX_FORM_PARTS`.

## Injection

- SQL: pass values as parameters. DB-API `cursor.execute("... WHERE id = %s", [id])` (placeholder
  style varies by driver). Never format, concatenate or f-string values into SQL.
- SQLAlchemy: expressions (`select(User).where(User.id == uid)`); raw SQL as
  `text("... WHERE id = :id")` with bound parameters. Table, column and `order_by` names come from an
  allowlist mapping.
- Django ORM parameterises values. Dangerous: `raw()`, `cursor.execute()`, `extra()` and `RawSQL` with
  formatted strings (pass a `params` list; never quote the placeholder), and input used as a field name
  in `order_by()`, `values()`, `annotate()`, `alias()` or `filter(**{key: v})`. Map names from an allowlist.
- Processes: `subprocess.run([prog, arg], check=True, timeout=...)` with an argument list. The shell
  is invoked only by `shell=True`; if unavoidable, `shlex.quote()` every value. `.bat`/`.cmd` files are
  shell-parsed even with a list on Windows. Put `--` before user-supplied filenames.
- `eval()`, `exec()`, `importlib.import_module()` and `getattr` on input are code execution; `ast.literal_eval()` parses literals.
- Template injection: `render_template_string(user_text)`, `jinja2.Template(user_text)` and Django `Template(user_text)`
  run the text; user-authored templates need `jinja2.sandbox.SandboxedEnvironment` (a mitigation, not isolation).

## Output and XSS

- Django templates, Flask's Jinja2 and `render_template_string` escape variables. A plain
  `jinja2.Environment(...)` does not: pass `autoescape=select_autoescape()` (Ruff S701 flags `False`).
- Escape hatches: `|safe`, `{% autoescape off %}`, Jinja2 `Markup()`, Django `mark_safe()`, `is_safe`
  on filters, `format_html(f"...")` (an f-string defeats it; `format_html("<b>{}</b>", v)` escapes).
  Use them only on server-built content or after an allowlist sanitiser (`nh3`).
- Quote every attribute holding a template expression. A user `href` is checked to be `http`, `https` or
  a relative path; escaping does not stop `javascript:`.
- JSON into a page: `{{ data|json_script:"id" }}` (Django) or `{{ data|tojson }}` (Flask); `HTMLResponse(text)` skips escaping.
- CSP: Django 6 `django.middleware.csp.ContentSecurityPolicyMiddleware` with `SECURE_CSP` or
  `SECURE_CSP_REPORT_ONLY`, `CSP.NONCE` and `{{ csp_nonce }}` (needs the
  `django.template.context_processors.csp` context processor); never cache a response holding a nonce.
  Flask and FastAPI set the header by hand or with Flask-Talisman.

## Auth, sessions and access

- Django: `django.contrib.auth`, `login()` (rotates the session key), `@login_required`,
  `PermissionRequiredMixin`. Scope querysets to the caller and fetch with `get_object_or_404` on that
  queryset; a permission check followed by `get_object_or_404(Note, pk=pk)` is an IDOR.
- Django passwords: `Argon2PasswordHasher` first in `PASSWORD_HASHERS`; sign-in is not throttled, so add a limiter.
  `csrf_exempt` only on header-token or signed-webhook views.
- DRF: `DEFAULT_PERMISSION_CLASSES = IsAuthenticated` globally; `AllowAny` only per view, with a comment.
  Object access through `get_queryset()` scoped to the caller. `SessionAuthentication` enforces CSRF;
  token authentication sends no cookie and needs none.
- Flask: `session` is a signed, client-readable cookie: no secrets in it. `session.clear()` before
  setting the user. Set `SESSION_COOKIE_SECURE=True`, `SESSION_COOKIE_HTTPONLY=True`,
  `SESSION_COOKIE_SAMESITE="Lax"`, `PERMANENT_SESSION_LIFETIME`. Flask has no CSRF protection: add
  Flask-WTF `CSRFProtect` or an `Origin` check.
- FastAPI: authentication is a dependency on the router,
  `APIRouter(dependencies=[Depends(require_user)])`, so a new route starts closed. `OAuth2PasswordBearer`
  only extracts the token; the dependency verifies it. Object checks go in the query.
- JWT with PyJWT: `jwt.decode(token, key, algorithms=["HS256"], audience=..., issuer=...,
  options={"require": ["exp", "sub"]})`, pinned algorithms, never `verify_signature=False`. JWTs are signed,
  not encrypted.
- Hashing outside Django: `pwdlib` (`PasswordHash.recommended()`, Argon2id) or `argon2-cffi`; verify against a dummy hash
  for unknown users so timing is equal.

## Secrets and configuration

- Secrets come from the environment or a secret manager and fail fast when absent:
  `os.environ["SECRET_KEY"]`, not `.get("SECRET_KEY", "dev")`.
- Django production: `DEBUG = False`; `ALLOWED_HOSTS` real hosts; `SESSION_COOKIE_SECURE`,
  `CSRF_COOKIE_SECURE`, `SECURE_SSL_REDIRECT` all `True`; `SECURE_HSTS_SECONDS` (subdomains and preload only
  when every subdomain is HTTPS); `SECURE_PROXY_SSL_HEADER` only when the proxy strips that header from
  clients; rotate with `SECRET_KEY_FALLBACKS` and remove old keys. `request.get_host()` validates
  against `ALLOWED_HOSTS`; `request.META["HTTP_HOST"]` does not.
- Flask: `SECRET_KEY` from the environment; no `app.run(debug=True)` or `FLASK_DEBUG=1` outside a
  developer machine (the debugger executes code); `TRUSTED_HOSTS` set to the real hostnames.
- FastAPI: `pydantic-settings` `BaseSettings` from the environment; `docs_url=None`, `redoc_url=None`,
  `openapi_url=None` where the schema is private; `TrustedHostMiddleware`; `CORSMiddleware` only if another
  origin must call, with exact `allow_origins` (never `["*"]` with `allow_credentials=True`).

## Files, paths and outbound requests

- Paths from input: `base = Path(root).resolve(); p = (base / name).resolve()`, then
  `p.is_relative_to(base)` or refuse. Better: generated storage names, looked up by id.
  `os.path.join(base, name)` drops `base` when `name` is absolute.
- Flask `send_from_directory(dir, name)` refuses paths outside `dir`; `send_file(user_path)` does not. Archives: `tarfile` `extractall(path, filter="data")` (the default from 3.14; pass it on 3.11 to 3.13
  where available); `"fully_trusted"` only for archives you made. No filter stops decompression bombs:
  extract into a new temp directory and count entries and bytes. `zipfile.extract*()` sanitises names,
  `zipfile.Path` does not; check members with `os.path.commonpath()` and count bytes while reading,
  since declared sizes can be forged.
- Outbound: `httpx`/`requests` with an explicit `timeout=` (S113), never `verify=False` (S501). For a URL
  from input follow `docs/web.md`, *SSRF*: resolve, require `ipaddress.ip_address(ip).is_global`, connect
  to that address, and disable redirects (`follow_redirects=False`, `allow_redirects=False`) or re-check each
  hop; stream and cap the body.

## Deserialization and parsing

- `pickle`, `shelve`, `marshal` and `dill` run code on load: never on data from a client, network, cache
  or queue another party can write. Use `json.loads` plus a Pydantic model. If pickle is unavoidable
  between your own processes, verify an `hmac` tag with `hmac.compare_digest` first and restrict
  `Unpickler.find_class`. Ruff S301 flags it.
- YAML: `yaml.safe_load()` only (S506). XML from outside: `defusedxml.ElementTree.parse`/`fromstring`. The standard-library parsers are exposed to
  entity-expansion and decompression attacks. Ruff S314 and Bandit flag them.

## Crypto and randomness

- Tokens, reset links, API keys, session ids: `secrets.token_urlsafe(32)` (or `token_bytes`, `token_hex`).
  `random` is for simulation (S311). Compare secrets with `hmac.compare_digest`, never `==`.
- Webhook signatures: `hmac.new(key, raw_body, hashlib.sha256)` over the raw bytes, then `compare_digest`;
  Flask `request.get_data()`, FastAPI `await request.body()` before any JSON parsing.

## Dependencies

- uv: commit `uv.lock`; CI runs `uv sync --locked` (errors when the lock is stale; `--frozen` skips the
  check).
- uv release age: `exclude-newer = "7 days"` under `[tool.uv]` (an RFC 3339 timestamp, a friendly duration
  or ISO 8601; compared with each file's upload time); `exclude-newer-package = { pkg = false }` exempts one.
  Keep `index-strategy` at its default, `first-index` (dependency confusion).
- pip: `pip install --require-hashes --only-binary :all: -r requirements.txt`; every dependency is pinned
  with `==` and a hash (`uv pip compile --generate-hashes`).
- Poetry: commit `poetry.lock`; CI runs `poetry check --lock` and `poetry sync`. It documents no release-age or hash
  option: export a hashed requirements file for pip, or use uv.

## Framework pitfalls

- Django: `DEBUG = True` in production leaks settings and source; `ALLOWED_HOSTS = ["*"]` needs your own host
  validation; `mark_safe` on input is XSS. Admin features (`ModelAdmin.list_editable`, generic inlines,
  model formsets with editable primary keys) are for trusted staff only, on the newest patch.
- FastAPI: a path operation without a security dependency is public. Blocking calls (`requests`, sync DB
  drivers) in `async def` stall the loop: use `def` handlers or async clients. Background tasks run after the
  response: pass ids and recheck access. Omitted `Annotated[bool, Form()]` fields use their declared default
  (or fail) on 0.162 and later: declare the default you intend.
- Starlette `request.url` derives from the `Host` header: use a configured base URL for links.
- Flask: `render_template_string` with input, `Markup(user)`, `|safe` and `send_file(user_path)` are the usual
  holes. A response that reads `session` carries `Cache-Control: private`. Behind a proxy use
  `werkzeug.middleware.proxy_fix.ProxyFix` with exact hop counts.

## Checks to run

- Dependency audit, failing CI on any finding (pip-audit exits 1 on a vulnerability):
  - uv: `uv export --locked --no-emit-project --format requirements-txt -o requirements.txt`, then
    `pip-audit -r requirements.txt --strict`
  - a project with `pyproject.toml` or `pylock.*.toml`: `pip-audit --locked .`
- Static analysis, failing CI on any finding (Ruff and Bandit exit 1 on a finding):
  - `ruff check --select S,B,ASYNC .` (flake8-bandit: pickle, eval, exec, `shell=True`, SQL strings, weak hashes,
    unverified TLS, requests without timeout, unsafe tar and YAML, Jinja2 autoescape off; `S101` ignored only in tests)
  - `bandit -r src -c pyproject.toml --severity-level medium`
- Secrets: `gitleaks git --redact` in CI and pre-commit. Django: `python manage.py check --deploy --fail-level WARNING` with the production settings.
- Tests: another user's id returns 404 and changes nothing; unknown body fields are rejected; every route
  answers 401 or 403 without a session; `../../etc/passwd` and an absolute path are refused.
