#!/usr/bin/env bash
# setup-deploy.sh — scaffold the .walkthrough/ layer into a target repo and
# install the GitHub Pages workflow. Idempotent: safe to re-run; never
# clobbers an existing walkthrough.config.json.
#
# Usage:
#   setup-deploy.sh --repo <target-repo-root> [--title "..."] [--base /repo/]

set -euo pipefail

# --- locate the skill assets relative to this script ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HUB_TEMPLATE="${SKILL_ROOT}/assets/hub-template"
CI_TEMPLATE="${SKILL_ROOT}/assets/ci/github-pages.yml"

# --- parse args ---
REPO=""
TITLE=""
BASE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)  REPO="${2:-}"; shift 2 ;;
    --title) TITLE="${2:-}"; shift 2 ;;
    --base)  BASE="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: setup-deploy.sh --repo <target-repo-root> [--title \"...\"] [--base /repo/]"
      exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "${REPO}" ]]; then
  echo "ERROR: --repo <target-repo-root> is required" >&2
  exit 2
fi
if [[ ! -d "${REPO}" ]]; then
  echo "ERROR: target repo not found: ${REPO}" >&2
  exit 2
fi
if [[ ! -d "${HUB_TEMPLATE}" ]]; then
  echo "ERROR: hub template missing at ${HUB_TEMPLATE}" >&2
  exit 1
fi

REPO="$(cd "${REPO}" && pwd)"
WT="${REPO}/.walkthrough"

# Default title/base derived from the repo directory name.
REPO_NAME="$(basename "${REPO}")"
TITLE="${TITLE:-${REPO_NAME} Walkthroughs}"
BASE="${BASE:-/${REPO_NAME}/}"

log() { echo "[setup-deploy] $*"; }

# --- 1. directory skeleton ---
log "Creating .walkthrough/ skeleton in ${REPO}"
mkdir -p "${WT}/content/routes" "${WT}/content/plans"

# --- 2. copy hub template (preserve any existing node_modules/dist) ---
log "Copying hub template -> .walkthrough/hub/"
mkdir -p "${WT}/hub"
# Copy everything except node_modules/dist to avoid clobbering installed deps.
( cd "${HUB_TEMPLATE}" && \
  find . \( -name node_modules -o -name dist \) -prune -o -type f -print | \
  while IFS= read -r f; do
    dest="${WT}/hub/${f#./}"
    mkdir -p "$(dirname "${dest}")"
    cp "${f}" "${dest}"
  done )

# --- 3. starter config (idempotent: never clobber) ---
CONFIG="${WT}/walkthrough.config.json"
if [[ -f "${CONFIG}" ]]; then
  log "walkthrough.config.json already exists — leaving it untouched"
else
  log "Writing starter walkthrough.config.json"
  cat > "${CONFIG}" <<JSON
{
  "title": "${TITLE}",
  "description": "Learning hub for ${REPO_NAME}.",
  "base": "${BASE}",
  "theme": "auto",
  "routes": [],
  "plans": []
}
JSON
fi

# --- 4. .gitignore ---
GITIGNORE="${WT}/.gitignore"
log "Writing .walkthrough/.gitignore"
cat > "${GITIGNORE}" <<'IGNORE'
dist/
hub/node_modules/
hub/public/content/
hub/public/walkthrough.config.json
IGNORE

# --- 5. GitHub Actions workflow ---
WORKFLOW_DIR="${REPO}/.github/workflows"
WORKFLOW_DEST="${WORKFLOW_DIR}/walkthrough-pages.yml"
if [[ -f "${CI_TEMPLATE}" ]]; then
  log "Installing GitHub Actions workflow -> .github/workflows/walkthrough-pages.yml"
  mkdir -p "${WORKFLOW_DIR}"
  cp "${CI_TEMPLATE}" "${WORKFLOW_DEST}"
else
  log "WARNING: CI template not found at ${CI_TEMPLATE} (skipping workflow install)"
fi

# --- next steps ---
cat <<EOF

[setup-deploy] Done. Scaffold ready at ${WT}

Next steps:
  1. Add walkthroughs:  put built route HTML in .walkthrough/content/routes/
                        and plan/design markdown in .walkthrough/content/plans/,
                        then list them in .walkthrough/walkthrough.config.json
  2. Build locally:     node ${SKILL_ROOT}/scripts/build-hub.mjs --root ${WT} --base ${BASE}
                        (open .walkthrough/dist/index.html to preview)
  3. Commit:            git add .walkthrough .github/workflows/walkthrough-pages.yml
                        (the user runs the commit)
  4. Enable Pages:      GitHub repo → Settings → Pages → Build and deployment
                        → Source = "GitHub Actions"
  5. Push to the default branch; the workflow builds and publishes to:
                        https://<owner>.github.io${BASE}

EOF
