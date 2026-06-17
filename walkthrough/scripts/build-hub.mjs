#!/usr/bin/env node
// build-hub.mjs — build the walkthrough hub (React + Vite) for a target repo.
//
// Usage:
//   node build-hub.mjs --root <path-to-.walkthrough> [--base /repo/]
//
// Steps:
//   1. Validate <root>/walkthrough.config.json exists.
//   2. Copy walkthrough.config.json + content/ into <root>/hub/public/.
//   3. Run `npm ci || npm install` then `npm run build` inside <root>/hub/
//      with WT_BASE set to --base (default '/').
//   4. Copy <root>/hub/dist/* into <root>/dist/.
//
// Pure Node built-ins only. Exits nonzero on any failure.

import { existsSync, rmSync, mkdirSync, cpSync, copyFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { resolve, join } from 'node:path';

function parseArgs(argv) {
  const args = { base: '/' };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--root') args.root = argv[++i];
    else if (a === '--base') args.base = argv[++i];
    else if (a === '-h' || a === '--help') args.help = true;
    else {
      console.error(`Unknown argument: ${a}`);
      args.help = true;
    }
  }
  return args;
}

function log(step, msg) {
  console.log(`\x1b[36m[build-hub]\x1b[0m ${step ? `${step} ` : ''}${msg}`);
}

function fail(msg) {
  console.error(`\x1b[31m[build-hub] ERROR:\x1b[0m ${msg}`);
  process.exit(1);
}

function run(cmd, cmdArgs, cwd) {
  log('•', `${cmd} ${cmdArgs.join(' ')}  (in ${cwd})`);
  const res = spawnSync(cmd, cmdArgs, { cwd, stdio: 'inherit', shell: false });
  return res.status === 0;
}

const args = parseArgs(process.argv.slice(2));

if (args.help || !args.root) {
  console.log(
    'Usage: node build-hub.mjs --root <path-to-.walkthrough> [--base /repo/]'
  );
  process.exit(args.root ? 0 : 1);
}

const root = resolve(args.root);
const base = args.base || '/';

log('1/4', `Validating config at ${root}`);
const configPath = join(root, 'walkthrough.config.json');
if (!existsSync(root)) fail(`root not found: ${root}`);
if (!existsSync(configPath)) fail(`walkthrough.config.json not found at ${configPath}`);

const hubDir = join(root, 'hub');
if (!existsSync(hubDir)) fail(`hub/ not found at ${hubDir} (run setup-deploy.sh first)`);
if (!existsSync(join(hubDir, 'package.json')))
  fail(`hub/package.json not found at ${hubDir}`);

// --- Step 2: copy config + content into hub/public/ ---
log('2/4', 'Copying config and content into hub/public/');
const publicDir = join(hubDir, 'public');
mkdirSync(publicDir, { recursive: true });

copyFileSync(configPath, join(publicDir, 'walkthrough.config.json'));

const contentSrc = join(root, 'content');
const contentDest = join(publicDir, 'content');
if (existsSync(contentSrc)) {
  rmSync(contentDest, { recursive: true, force: true });
  cpSync(contentSrc, contentDest, { recursive: true });
  log('  ', `copied content/ -> ${contentDest}`);
} else {
  log('  ', 'no content/ directory found (skipping)');
}

// --- Step 3: install deps + build ---
log('3/4', `Building hub with WT_BASE=${base}`);
process.env.WT_BASE = base;

const npm = process.platform === 'win32' ? 'npm.cmd' : 'npm';
const installed = run(npm, ['ci'], hubDir) || run(npm, ['install'], hubDir);
if (!installed) fail('npm ci/install failed');

if (!run(npm, ['run', 'build'], hubDir)) fail('npm run build failed');

// --- Step 4: copy hub/dist/* into <root>/dist/ ---
log('4/4', 'Publishing build output to dist/');
const hubDist = join(hubDir, 'dist');
if (!existsSync(hubDist)) fail(`expected build output at ${hubDist}`);

const outDist = join(root, 'dist');
rmSync(outDist, { recursive: true, force: true });
mkdirSync(outDist, { recursive: true });
cpSync(hubDist, outDist, { recursive: true });

log('✓', `Done. Site is in ${outDist}`);
