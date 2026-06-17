# Deployment & Layout

The hub + routes are **vendored into the target repo's `.walkthrough/` folder and
committed**, so the document center lives with the code and CI can build it on push.

## `.walkthrough/` layout

```
.walkthrough/
  walkthrough.config.json     # site metadata + route/plan manifest (committed)
  content/
    routes/<slug>.html        # self-contained walkthroughs, built by build-walkthrough.mjs (committed)
    plans/<name>.md           # plan.md / design.md the hub renders (committed)
  hub/                        # React+Vite app, copied from the skill's assets/hub-template (committed)
  dist/                       # build output that Pages serves (gitignored)
```

`.walkthrough/.gitignore` (written by setup) ignores `dist/`, `hub/node_modules/`, and the
build-time copies under `hub/public/`.

## walkthrough.config.json

```json
{
  "title": "My Project Walkthroughs",
  "description": "Learning hub for the platform.",
  "base": "/repo-name/",
  "theme": "auto",
  "routes": [
    { "title": "Auth Onboarding", "slug": "auth-onboarding",
      "file": "content/routes/auth-onboarding.html",
      "audience": "engineers", "summary": "…", "tags": ["auth"], "source": "repo" }
  ],
  "plans": [
    { "title": "Architecture Design", "file": "content/plans/design.md", "summary": "…" }
  ]
}
```

Every built route and rendered plan must be listed here — the hub reads this at runtime.

## One-time setup (per target repo)

```bash
bash scripts/setup-deploy.sh --repo /path/to/target-repo --title "My Walkthroughs" --base /repo-name/
```

This scaffolds `.walkthrough/`, copies the hub template, writes a starter config (only if
absent — idempotent), and installs `.github/workflows/walkthrough-pages.yml`. Then enable
Pages in the repo: **Settings → Pages → Source = "GitHub Actions"**.

## Build locally (preview before pushing)

```bash
# 1. build each route from its DSL source
node scripts/build-walkthrough.mjs <source>.md --out /path/to/target/.walkthrough/content/routes/<slug>.html
# 2. build the hub for LOCAL preview with base "/" (NOT /repo-name/ — see below)
node scripts/build-hub.mjs --root /path/to/target/.walkthrough --base /
# 3. serve over HTTP, WITHOUT single-page mode (the hub uses HashRouter)
cd /path/to/target/.walkthrough/dist && npx serve -l 3000 .
# open http://localhost:3000
```

**Two preview footguns — both will waste your time if ignored:**

- **Don't open `dist/index.html` via `file://`, and don't build with `--base /repo-name/`
  for local preview.** A project base makes asset URLs absolute (`/repo-name/assets/…`),
  so a `file://` open (or serving at `/`) renders a **blank page**. Build with `--base /`
  for local preview; CI rebuilds with the real `/repo-name/` base on deploy, and the
  committed route HTML is base-independent, so this local choice is safe.
- **Do NOT use `serve -s` / `--single`.** The hub uses `HashRouter`, so it needs **no**
  SPA fallback. Single-page mode rewrites *every* path — including the route `.html`
  files — to `index.html`, so clicking a walkthrough "opens the hub home" instead of the
  route. Plain `serve` (or any static server that serves files as-is) is correct.

## CI (GitHub Pages)

The installed workflow triggers on pushes to the **default branch** (`main`/`master`)
touching `.walkthrough/**`. It stages content into the hub, runs `npm ci || npm install` +
`vite build` with `WT_BASE` derived from the repo name, and publishes `.walkthrough/dist`
via `upload-pages-artifact` + `deploy-pages`.

> **Branch note:** because it only fires on `main`/`master`, work done on a feature branch
> won't auto-deploy. Either merge to the default branch, or trigger the run manually
> (`gh run rerun <id>` / the Actions "Run workflow" button) to preview from a branch.

## Troubleshooting the first deploy

These two are the common first-time failures — both are Pages *configuration*, not build
problems (the build itself usually succeeds):

- **Build fails at "Configure Pages" with `Get Pages site failed … Not Found`.** Pages
  isn't enabled yet. Go to **Settings → Pages → Source = "GitHub Actions"**, then re-run
  the failed run (`gh run rerun <id> --failed`). No new commit needed. To make the workflow
  self-enabling on fresh repos instead, add `with: { enablement: true }` to the
  `actions/configure-pages` step (requires a commit to take effect, so it won't fix the
  *current* run).
- **The site shows your repo's `README.md` instead of the hub.** Pages source is set to
  **"Deploy from a branch"**, so GitHub is serving the repo root through Jekyll. Switch
  Source to **"GitHub Actions"** and re-run the workflow; the artifact then overwrites the
  stale Jekyll build. (A successful Actions deploy has never run yet is the usual cause —
  what you're seeing is the leftover branch build.)

**v1 model:** routes are committed as built HTML (you author + build them locally). The
workflow rebuilds only the hub. If you later store DSL sources in the repo and want CI to
recompile routes, wire the route engine into the marked TODO step in the workflow (and add
`npm install -g @mermaid-js/mermaid-cli` for light pre-rendered diagrams).

## GitLab Pages (later)

`assets/ci/gitlab-pages.yml` is a commented stub of the equivalent `pages` job (build into
`public/`). The build logic is identical — only the CI wrapper differs — so enabling GitLab
is a drop-in: copy the stub to `.gitlab-ci.yml`, uncomment, and set the base path.

## Mermaid in CI

`mermaid-cli` (Chromium) gives light pre-rendered SVG diagrams. Without it, the route build
inlines the Mermaid runtime — still fully offline, just larger files. CI runners can run
Chromium, so installing mermaid-cli there is recommended when routes use diagrams.
