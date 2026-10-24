---
last_checked: 2026-10-24
sources:
  - https://docs.github.com/en/actions/reference/security/secure-use  # GitHub Actions hardening: tokens, untrusted input, pinning
  - https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows  # pull_request_target and workflow_run behaviour
  - https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference  # Dependabot options, including cooldown and groups
  - https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning  # secret scanning and push protection
  - https://docs.github.com/en/actions/concepts/security/openid-connect  # OIDC instead of long-lived cloud keys
  - https://docs.npmjs.com/trusted-publishers  # npm trusted publishing and provenance
  - https://docs.docker.com/build/building/best-practices/  # Dockerfile practices
  - https://github.com/gitleaks/gitleaks  # secret scanner for the repo and history
  - https://google.github.io/osv-scanner/  # one dependency scanner across ecosystems
---

# Dependencies, secrets in the repo, CI and containers

Each stack note names its package manager's settings and audit command. This file is what holds for
all of them.

## Choosing a dependency

- **Write it, or use the platform, when it's small.** A dozen lines don't justify a package and its
  tree.
- **Before adding one, check:** it's maintained (releases and issue replies this year), widely used,
  published by the project it claims to be (the repository link matches, the name isn't a near-miss of
  a popular one), and has no install script it doesn't need. Look at its own dependency count.
- **Prefer the official SDK** of a service to a community wrapper.
- A package that asks for a token, network access or an install script it doesn't explain is not added.

## Lockfiles and installs

- The lockfile is committed, and CI and deploys install from it without resolving anew (the frozen or
  locked install in the stack note). A lockfile change in a pull request is reviewed like code: a new
  registry URL, a tarball from a git host, or a package outside the change's purpose is a question.
- **Lifecycle scripts off by default.** Dependencies' `preinstall`/`install`/`postinstall` scripts are
  the usual way a hijacked package runs. Turn them off in the package manager and allow by name only
  the packages that must build native code.
- **Hold back brand-new releases.** Set the package manager's minimum release age (a few days to a
  week). Most hijacked versions are found and pulled within that window.
- Only one registry per scope. A private package name is claimed on the public registry as well, or
  scoped, so a public package can't shadow it.

## Audits and updates

- The dependency audit runs in CI on every pull request and on a schedule, failing on high and
  critical advisories that affect the installed versions. One scanner across ecosystems (`osv-scanner`)
  or the stack's own (in the stack note).
- An advisory with no fixed version is accepted in writing with its reason and a review date, or the
  package is replaced.
- **Update on a cadence, in groups, after a cooldown:** Dependabot or Renovate with grouped minor and
  patch updates and a `cooldown` of several days before a new version is proposed. Dependabot's
  `cooldown` applies to version updates only; security updates skip it.
- After a major upgrade of a framework, re-read its security notes in the stack note.

## Secrets in the repository

- `.env` and every file holding real credentials are in `.gitignore` from the first commit. Example
  files (`.env.example`) hold names and placeholders only.
- **A secret scanner runs before code leaves the machine and again in CI:** gitleaks as a pre-commit
  hook and a CI step over the commits in the push. GitHub's push protection blocks known secret
  formats on push once a repository administrator turns it on (it requires GitHub Secret Protection);
  secret scanning alerts are free on public repositories only.
- **A committed secret is compromised.** Rotate it at its provider first, then remove it from the
  code. Rewriting history doesn't help once it was pushed: clones, forks and caches keep it.
- Real personal data never enters the repository; fixtures are synthetic or anonymised.

## CI

- **Least-privilege token:** set `permissions:` at the top of every workflow, starting from
  `contents: read`, and grant more per job only where that job needs it.
- **Pin third-party actions to a full commit SHA** (with the version as a comment), not a tag or
  branch: a tag can be moved or deleted. Take the SHA from the action's own repository, not a fork.
- **Untrusted text never enters a shell.** Issue and PR titles, bodies, branch names, commit messages
  and comments go into `env:` variables and are referenced as `"$VAR"`, never interpolated as
  `${{ github.event... }}` inside `run:`.
- **`pull_request_target` runs the base branch's workflow, and `workflow_run` can reach secrets and a
  write token even when the workflow that triggered it could not.** Never check out or run the pull
  request's code in them, and treat artifacts from the triggering run as untrusted (download them
  outside the workspace and validate them). Use `pull_request` for building and testing contributions:
  from a fork it gets no secrets and a read-only token.
- `actions/checkout` with `persist-credentials: false` unless the job pushes: the default (`true`)
  leaves the token available to every later step in the job.
- **Cloud credentials through OIDC**, scoped to the repository and the branch or environment in the cloud role's trust
  condition, instead of long-lived keys in secrets. The job needs `id-token: write` and nothing more
  for that. Publish packages through npm trusted publishing (GitHub-hosted runners), which needs no
  stored token to publish.
- Secrets are available only to the jobs and environments that need them; deploys to production run
  from a protected environment with required reviewers or branch rules.
- **AI agents in CI** that read issues, PRs or comments are reading untrusted text: give them no
  secrets and no write permission on events an outsider can trigger, and gate their actions on a
  maintainer's approval.
- Self-hosted runners are not used for public repositories, and in a private one anyone who can fork
  and open a pull request may reach the runner, its secrets and the token: restrict who can trigger
  runs, and prefer ephemeral runners. Environments and required reviews don't isolate a runner.

## Containers

- Base images pinned by digest (Dependabot's `docker` ecosystem keeps the digests current), from a
  Docker Official, Verified Publisher or Sponsored Open Source publisher, as small as the app allows
  (slim or minimal variants where they work).
- A multi-stage build: build tools stay in the build stage; the final image holds the app and its
  runtime only.
- The app runs as a non-root user, created in the Dockerfile with a fixed UID.
- No secrets in the image: not in `ENV`, `ARG` or a copied file. `ARG` and `ENV` persist in the image's layers. Build-time
  secrets use secret mounts (`RUN --mount=type=secret`); runtime secrets come from the platform.
- `.dockerignore` excludes `.git`, `.env*`, local credentials and `node_modules`.
- The image is scanned for known vulnerabilities in CI.
