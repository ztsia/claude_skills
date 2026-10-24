# CLAUDE.md

This repository is the `workflow` plugin and its marketplace (`ztsia`). `README.md` says what's in it
and how a project uses it. A project's own CLAUDE.md starts from `plugins/workflow/templates/CLAUDE.md`,
not this file.

## Layout

| Path | What it holds |
|---|---|
| `.claude-plugin/marketplace.json` | The marketplace, listing the one plugin |
| `plugins/workflow/` | The plugin: `rules.md`, `hooks/`, `agents/`, `skills/`, `scripts/`, `templates/` |
| `examples/` | Earlier projects' files, for reference |

## Rules for changing it

- **The plugin is shared by every project.** A change here reaches each one at its next update, so a
  rule changes only for a lesson that holds beyond one project. What's true of one project stays in
  that project (`CLAUDE.md`, `docs/workflow/<skill>.md`).
- **`rules.md` stays under 8,000 characters.** The hook's output is cut to a 2,000-character preview
  above 10,000, and the hook adds a few lines of its own.
- **Skills, agents and rules state current facts and rules only:** no history, changelogs, notes to
  the reader or unverified marks. Tables keep one shape.
- **A path inside the plugin is written `${CLAUDE_PLUGIN_ROOT}/…`** in skills and agents (and in
  `rules.md`, which the hook fills in), or `${CLAUDE_SKILL_DIR}` for a skill's own folder. A command
  quotes it: the path can contain spaces. Agents and skills are named `workflow:<name>` wherever one
  is spawned or invoked.
- **Bump `version`** in `plugins/workflow/.claude-plugin/plugin.json` with every change merged to
  `main`: an installed copy updates only when it changes.

## Checks

From the repo root, before a push:

| Command | What it does |
|---|---|
| `claude plugin validate .` and `claude plugin validate plugins/workflow` | The manifests, and every agent's and skill's frontmatter (an agent whose YAML fails to parse silently loses its model and tools) |
| `claude --plugin-dir plugins/workflow`, from a test project | A session with this checkout of the plugin: the rules arrive, `/agents` lists `workflow:*` |
| `bash -n plugins/workflow/scripts/*.sh`, `node --check` on each `.mjs` | The scripts parse |
| `{ git ls-files plugins/workflow ':!plugins/workflow/files.txt' \| sed 's\|^plugins/workflow/\|\|'; echo files.txt; } \| sort > plugins/workflow/files.txt` | Regenerates the plugin's file list after adding, moving or deleting a file. `cloud-setup.sh` fetches the files it lists when a clone fails, since the cloud proxy refuses GitHub's API for a repository the session doesn't have attached |

CI (`.github/workflows/check.yml`) runs the file list, script and `rules.md` checks on every push.
