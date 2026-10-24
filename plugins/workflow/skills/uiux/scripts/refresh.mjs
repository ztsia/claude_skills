#!/usr/bin/env node
// Re-pulls the shadcn/ui docs this skill reads (docs/components, docs/instructions) from shadcn's
// own doc source, and stamps components-index.md with the date and upstream commit. It writes into
// the project's docs/workflow/uiux/ (or --out), whose files replace the plugin's, never into the
// plugin's own folder. Run from the project root:
//   node <skill folder>/scripts/refresh.mjs [--base radix|base|aria] [--framework next|vite|remix|astro|tanstack-start] [--out <dir>]
// The base and framework default to the project's components.json (via `npx shadcn info --json`)
// when it can be read, else radix and next. Prints the components added, removed and changed, so
// the session can update components-index.md. Needs Node 18+ and network access to GitHub.
import { readFile, writeFile, readdir, unlink, mkdir, copyFile } from "node:fs/promises";
import { execSync } from "node:child_process";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const SKILL = join(dirname(fileURLToPath(import.meta.url)), "..");
const OUT = resolve(process.argv.includes("--out") ? process.argv[process.argv.indexOf("--out") + 1] : "docs/workflow/uiux");
const DOCS = join(OUT, "docs");
const REPO = "shadcn-ui/ui";
const ROOT = "apps/v4/content/docs";
const api = (p) => `https://api.github.com/repos/${REPO}/${p}`;
const raw = (sha, p) => `https://raw.githubusercontent.com/${REPO}/${sha}/${ROOT}/${p}`;
const headers = { "User-Agent": "uiux-refresh", ...(process.env.GITHUB_TOKEN && { Authorization: `Bearer ${process.env.GITHUB_TOKEN}` }) };

const arg = (name) => { const i = process.argv.indexOf(`--${name}`); return i > 0 ? process.argv[i + 1] : undefined; };
// The project's base library and framework, from `shadcn info --json` or components.json's style.
const BASES = ["radix", "base", "aria"], FRAMEWORKS = ["next", "vite", "remix", "astro", "tanstack-start"];
const find = (o, ok) => { if (typeof o === "string") return ok(o); if (o && typeof o === "object") for (const v of Object.values(o)) { const r = find(v, ok); if (r) return r; } };
let info = {};
try { info = JSON.parse(execSync("npx --yes shadcn@latest info --json", { stdio: ["ignore", "pipe", "ignore"], timeout: 90000 }).toString()); } catch {}
try { info.componentsJson ??= JSON.parse(await readFile("components.json", "utf8")); } catch {}
const base = arg("base") ?? find(info, (s) => BASES.find((b) => s === b || s.startsWith(`${b}-`))) ?? "radix";
const framework = arg("framework") ?? find(info, (s) => FRAMEWORKS.find((f) => s === f || s.startsWith(`${f}-`))) ?? "next";

async function get(url, as = "json") {
  const res = await fetch(url, { headers });
  if (!res.ok) throw new Error(`${res.status} ${url}`);
  return as === "json" ? res.json() : res.text();
}

const sha = (await get(api("commits/main"))).sha;
const listing = await get(api(`contents/${ROOT}/components/${base}?ref=${sha}`));
const upstream = listing.filter((f) => f.name.endsWith(".mdx")).map((f) => f.name.replace(/\.mdx$/, ""));
const forms = (await get(api(`contents/${ROOT}/forms?ref=${sha}`))).filter((f) => f.name.endsWith(".mdx")).map((f) => f.name.replace(/\.mdx$/, ""));

// Local names drop dashes: alert-dialog.mdx -> alertdialog.md.
const local = (name) => name.replaceAll("-", "");
const files = [
  ...upstream.map((n) => [`components/${base}/${n}.mdx`, `components/${local(n)}.md`]),
  ["(root)/theming.mdx", "instructions/theming.md"],
  ["(root)/components-json.mdx", "instructions/componentsjson.md"],
  ["(root)/monorepo.mdx", "instructions/monorepo.md"],
  [`dark-mode/${framework}.mdx`, "instructions/darkmode.md"],
  ...forms.map((n) => [`forms/${n}.mdx`, `instructions/forms-${n === "index" ? "overview" : n}.md`]),
];

const added = [], changed = [];
for (const d of ["components", "instructions"]) await mkdir(join(DOCS, d), { recursive: true });
for (const [from, to] of files) {
  const text = await get(raw(sha, from), "text");
  const path = join(DOCS, to);
  // Compared with what the session reads now: the project's copy, else the plugin's.
  const before = await readFile(path, "utf8").catch(() => readFile(join(SKILL, "docs", to), "utf8")).catch(() => null);
  if (before === null) added.push(to);
  else if (before.replace(/\r\n/g, "\n") !== text) changed.push(to);
  await writeFile(path, text);
}

// docs/ holds only shadcn's own docs, so anything upstream no longer has is removed: deleted from the
// project's copy, and reported when only the plugin has it (the index then drops its row).
const keep = new Set(files.map(([, to]) => to));
const removed = new Set();
for (const d of ["components", "instructions"]) {
  for (const f of await readdir(join(SKILL, "docs", d)).catch(() => [])) if (!keep.has(`${d}/${f}`)) removed.add(`${d}/${f}`);
  for (const f of await readdir(join(DOCS, d))) {
    if (!keep.has(`${d}/${f}`)) { await unlink(join(DOCS, d, f)); removed.add(`${d}/${f}`); }
  }
}

const indexPath = join(OUT, "components-index.md");
await readFile(indexPath).catch(() => copyFile(join(SKILL, "components-index.md"), indexPath));
const index = await readFile(indexPath, "utf8");
const front = `---\nlast_checked: ${new Date().toISOString().slice(0, 10)}\nupstream: ${REPO}@${sha.slice(0, 12)}\nbase: ${base}\nframework: ${framework}\n---\n`;
await writeFile(indexPath, front + index.replace(/^---\n[\s\S]*?\n---\n/, ""));

console.log(`upstream ${REPO}@${sha.slice(0, 12)}, base ${base}, framework ${framework}`);
console.log(`added (${added.length}): ${added.join(", ") || "none"}`);
console.log(`removed (${removed.size}): ${[...removed].join(", ") || "none"}`);
console.log(`changed (${changed.length}): ${changed.join(", ") || "none"}`);
