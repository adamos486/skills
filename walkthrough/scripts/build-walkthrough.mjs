#!/usr/bin/env node
/**
 * build-walkthrough.mjs — render a walkthrough DSL (.md) into ONE self-contained,
 * offline-capable walkthrough.html.
 *
 * Pipeline: frontmatter (gray-matter) → extract ::: container blocks → marked (GFM)
 *   - code fences  → Shiki, pre-highlighted with inline styles (no runtime, no CDN)
 *   - ```mermaid   → pre-rendered SVG via mermaid-cli if available (light),
 *                    else inlined mermaid runtime (offline, heavier), else styled <pre>
 *   - :::quiz / :::reveal / :::callout / :::html  → DSL widgets
 * CSS + JS are inlined from ../assets. Output is a single file you can email / open offline.
 *
 * Usage:
 *   node build-walkthrough.mjs <input.md> [--out path.html]
 *     [--light-theme github-light] [--dark-theme night-owl] [--quiet]
 *
 * Theme: the output ships BOTH a light and a dark palette. Code is highlighted
 * with Shiki dual themes (CSS-variable mode, no runtime), and the page defaults
 * to light with a persisted toggle (localStorage "wt-theme"). --theme is kept as
 * an alias for --dark-theme for backward compatibility.
 */

import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";
import matter from "gray-matter";
import { marked } from "marked";
import { getHighlighter } from "shiki";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
const ASSETS = path.resolve(__dirname, "..", "assets");

/* ------------------------------------------------------------------ args --- */
function parseArgs(argv) {
  const a = { _: [], lightTheme: "github-light", darkTheme: "night-owl", quiet: false };
  for (let i = 0; i < argv.length; i++) {
    const t = argv[i];
    if (t === "--out") a.out = argv[++i];
    else if (t === "--theme" || t === "--dark-theme") a.darkTheme = argv[++i];
    else if (t === "--light-theme") a.lightTheme = argv[++i];
    else if (t === "--quiet") a.quiet = true;
    else if (t === "--strict") a.strict = true;
    else if (t === "--share") a.share = true;
    else if (t === "--help" || t === "-h") a.help = true;
    else a._.push(t);
  }
  return a;
}
const args = parseArgs(process.argv.slice(2));
const log = (...m) => { if (!args.quiet) console.error("[walkthrough]", ...m); };

if (args.help || args._.length === 0) {
  console.log("Usage: build-walkthrough.mjs <input.md> [--out file.html] [--light-theme github-light] [--dark-theme night-owl] [--quiet] [--strict] [--share]");
  process.exit(args.help ? 0 : 1);
}

/* --------------------------------------------------------------- helpers --- */
const ESC = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" };
const escapeHtml = (s) => String(s).replace(/[&<>"']/g, (c) => ESC[c]);

function makeSlugger() {
  const seen = Object.create(null);
  return (text) => {
    let base = String(text)
      .toLowerCase()
      .replace(/<[^>]+>/g, "")
      .replace(/[^\w\s-]/g, "")
      .trim()
      .replace(/\s+/g, "-") || "section";
    if (seen[base] == null) { seen[base] = 0; return base; }
    seen[base] += 1;
    return `${base}-${seen[base]}`;
  };
}

/* ------------------------------------------------ audience guardrail (lint) -- */
/* The learner is the ONLY reader. Nothing rendered may address the author, an
   agent, or a reviewer, or narrate how the content was produced. These are
   high-precision tells for that meta-commentary — a hit is a defect to rewrite,
   not noise. See references/pedagogy.md → "The learner is the only reader". */
const AUDIENCE_RULES = [
  [/\bmyth[\s-]*correction\b/i, "authoring meta — state the fact plainly, don't narrate a correction"],
  [/\bdo(?:n['’]?t|\s+not)\s+(teach|write|say|tell)\b/i, "instruction to the author/agent"],
  [/\b(older|earlier|previous|prior)\s+(ai\s+)?model\s+(described|said|claimed|wrote|taught|listed|framed|gave)\b/i, "refers to a prior authoring pass the learner can't see"],
  [/\b(an?|the|our|my|one|some|its)\s+(earlier|previous|prior|older|original|first)\s+drafts?\b/i, "refers to a prior draft of this artifact"],
  [/\bearlier drafts?\b/i, "refers to a prior draft of this artifact"],
  [/\bverified against (the )?(source|code)\b/i, "authoring process exhaust"],
  [/\bfact[\s-]?check(ed|ing)?\b/i, "authoring process exhaust"],
  [/\bnote to (the )?(author|self|editor|reviewer)\b/i, "addressed to the author, not the learner"],
  [/\bauthor[\s-]?facing\b/i, "explicitly author-facing"],
  [/\bas (an?|the) (author|agent|assistant|llm)\b/i, "addresses the author/agent, not the learner"],
  [/\b(we|i) (got|had) (this|it|that) (wrong|backwards)\b/i, "narrates an authoring mistake"],
  [/\b(this|the)\s+(walkthrough|guide|lesson|page|route|article)\s+(was|is|were)\s+(written|authored|generated|produced|corrected|created)(?!\s+(for|to|with|using|in|as|so|because|by you|by the reader))/i, "talks about the artifact's own creation"],
  [/(?:^|[\s(])(TODO|FIXME|XXX|HACK)\b/, "leftover developer marker"],
];

/** Blank out fenced code + :::html blocks (preserving line numbers) so the
 *  linter inspects rendered prose only, not code or raw-HTML escape hatches. */
function stripNonProse(content) {
  let inFence = false, inHtml = false;
  return content.split("\n").map((ln) => {
    const t = ln.trim();
    if (inFence) { if (/^(```+|~~~+)\s*$/.test(t)) inFence = false; return ""; }
    if (inHtml) { if (t === ":::") inHtml = false; return ""; }
    if (/^(```+|~~~+)/.test(t)) { inFence = true; return ""; }
    if (/^:::html\b/.test(t)) { inHtml = true; return ""; }
    return ln;
  });
}

/** Return author/agent-facing phrases that must never render. */
function auditAudience({ title, summary, content }) {
  const hits = [];
  const check = (text, loc) => {
    if (!text) return;
    for (const [re, why] of AUDIENCE_RULES) {
      const m = re.exec(text);
      if (m) hits.push({ loc, match: m[0].trim(), why });
    }
  };
  check(title, "frontmatter:title");
  check(summary, "frontmatter:summary");
  stripNonProse(content).forEach((ln, i) => check(ln, `L${i + 1}`));
  return hits;
}

/* -------------------------------------------------- mermaid tool detection -- */
function resolveMermaidCli() {
  // Prefer a locally-installed @mermaid-js/mermaid-cli (run cli.js via node), else mmdc on PATH.
  const candidates = [];
  try { candidates.push(require.resolve("@mermaid-js/mermaid-cli/src/cli.js")); } catch (_) {}
  candidates.push(
    path.join(__dirname, "node_modules", "@mermaid-js", "mermaid-cli", "src", "cli.js"),
    path.join(__dirname, "..", "node_modules", "@mermaid-js", "mermaid-cli", "src", "cli.js"),
  );
  for (const cli of candidates) {
    if (cli && fs.existsSync(cli)) return { cmd: process.execPath, pre: [cli] };
  }
  // .bin shim
  const binShim = path.join(__dirname, "node_modules", ".bin", process.platform === "win32" ? "mmdc.cmd" : "mmdc");
  if (fs.existsSync(binShim)) return { cmd: binShim, pre: [] };
  // PATH lookup
  const which = process.platform === "win32" ? "where" : "which";
  try {
    const p = execFileSync(which, ["mmdc"], { encoding: "utf8" }).trim().split(/\r?\n/)[0];
    if (p) return { cmd: p, pre: [] };
  } catch (_) { /* not on PATH */ }
  return null;
}

function mkTmpDir(prefix) {
  // os.tmpdir() can point to a non-existent path in some sandboxes; fall back to cwd.
  for (const base of [os.tmpdir(), process.cwd()]) {
    try {
      fs.mkdirSync(base, { recursive: true });
      return fs.mkdtempSync(path.join(base, prefix));
    } catch (_) { /* try next */ }
  }
  const dir = path.join(process.cwd(), `${prefix}${Date.now()}`);
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function readMermaidRuntime() {
  try {
    const p = require.resolve("mermaid/dist/mermaid.min.js");
    return fs.readFileSync(p, "utf8");
  } catch (_) { return null; }
}

/* --------------------------------------------------------- code rendering -- */
let highlighter = null;
async function highlightCode(code, lang) {
  if (!highlighter) {
    highlighter = await getHighlighter({
      themes: [args.lightTheme, args.darkTheme],
      langs: ["js", "ts", "jsx", "tsx", "json", "bash", "shell", "python", "go", "rust",
              "java", "c", "cpp", "html", "css", "yaml", "sql", "diff", "md", "tsx"],
    });
  }
  const loaded = highlighter.getLoadedLanguages();
  const useLang = loaded.includes(lang) ? lang : "text";
  // Dual-theme, CSS-variable mode: each token carries --shiki-light / --shiki-dark
  // (and the <pre> carries the -bg variants). No default color is applied, so the
  // route CSS selects which set to honor per the active [data-theme]. Fully offline.
  return highlighter.codeToHtml(code, {
    lang: useLang,
    themes: { light: args.lightTheme, dark: args.darkTheme },
    defaultColor: false,
  });
}

/* state collected during the build */
const diagram = { mode: "none", count: 0 }; // none | svg | runtime | fallback
const codeCache = new Map(); // key -> html
const mmdc = resolveMermaidCli();

const codeKey = (code, lang) => `${lang} ${code}`;

async function renderMermaid(src) {
  diagram.count += 1;
  if (mmdc) {
    try {
      const tmp = mkTmpDir("wt-mmd-");
      const inFile = path.join(tmp, "d.mmd");
      const outFile = path.join(tmp, "d.svg");
      fs.writeFileSync(inFile, src, "utf8");
      execFileSync(mmdc.cmd, [...mmdc.pre, "-i", inFile, "-o", outFile, "-b", "transparent"],
        { stdio: "ignore" });
      let svg = fs.readFileSync(outFile, "utf8").replace(/<\?xml[^>]*\?>/, "").trim();
      fs.rmSync(tmp, { recursive: true, force: true });
      diagram.mode = diagram.mode === "runtime" ? "runtime" : "svg";
      return `<figure class="wt-diagram">${svg}</figure>`;
    } catch (e) {
      log("mermaid-cli render failed, falling back:", e.message);
    }
  }
  // Fallback: defer to the inlined mermaid runtime (added once at assembly time).
  if (readMermaidRuntime()) {
    diagram.mode = "runtime";
    return `<figure class="wt-diagram"><pre class="mermaid">${escapeHtml(src)}</pre></figure>`;
  }
  diagram.mode = "fallback";
  return `<figure class="wt-diagram fallback"><pre>${escapeHtml(src)}</pre>` +
    `<div class="wt-diagram-note">Diagram source (install @mermaid-js/mermaid-cli for rendered output).</div></figure>`;
}

/* --------------------------------------------- ::: container block parsing -- */
/** Extract top-level ":::name args ... :::" blocks; replace with placeholders. */
function extractBlocks(md) {
  const lines = md.split("\n");
  const out = [];
  const blocks = [];
  for (let i = 0; i < lines.length; i++) {
    const open = /^:::(\w+)(?:\s+(.*))?\s*$/.exec(lines[i]);
    if (open) {
      const name = open[1];
      const arg = (open[2] || "").trim();
      const body = [];
      i++;
      while (i < lines.length && !/^:::\s*$/.test(lines[i])) { body.push(lines[i]); i++; }
      const id = blocks.length;
      blocks.push({ name, arg, body: body.join("\n") });
      out.push(`\n<!--WTBLOCK:${id}-->\n`);
    } else {
      out.push(lines[i]);
    }
  }
  return { md: out.join("\n"), blocks };
}

async function renderInner(md) {
  return (await marked.parse(md)).trim();
}

async function renderBlock(b) {
  switch (b.name) {
    case "html":
      return b.body; // raw passthrough escape hatch
    case "callout": {
      const type = (b.arg || "note").toLowerCase();
      const icon = { note: "📝", tip: "💡", warning: "⚠️", info: "ℹ️" }[type] || "📝";
      return `<div class="wt-callout ${escapeHtml(type)}"><div class="ic">${icon}</div>` +
        `<div class="body">${await renderInner(b.body)}</div></div>`;
    }
    case "reveal": {
      const prompt = b.arg || "Reveal answer";
      return `<details class="wt-reveal"><summary>${escapeHtml(prompt)}` +
        `<span class="hint">— try it yourself first</span></summary>` +
        `<div class="reveal-body">${await renderInner(b.body)}</div></details>`;
    }
    case "quiz":
      return await renderQuiz(b.body);
    default:
      log(`unknown ::: block "${b.name}", rendering as callout`);
      return `<div class="wt-callout note"><div class="ic">📝</div>` +
        `<div class="body">${await renderInner(b.body)}</div></div>`;
  }
}

async function renderQuiz(body) {
  const lines = body.split("\n");
  const qLines = [];
  const opts = [];
  const explainLines = [];
  let phase = "q";
  for (const line of lines) {
    const opt = /^- \(([ xX])\)\s+(.*)$/.exec(line);
    if (opt) { phase = "opt"; opts.push({ correct: opt[1].toLowerCase() === "x", text: opt[2] }); continue; }
    if (/^>\s?/.test(line)) { phase = "explain"; explainLines.push(line.replace(/^>\s?/, "")); continue; }
    if (phase === "q") qLines.push(line);
    else if (phase === "explain" && line.trim()) explainLines.push(line);
  }
  const q = await renderInner(qLines.join("\n").trim());
  const optHtml = opts.map((o) =>
    `<button class="opt" data-correct="${o.correct ? 1 : 0}">` +
    `<span class="mark">${o.correct ? "✓" : "✕"}</span><span>${escapeHtml(o.text)}</span></button>`
  ).join("");
  const explain = explainLines.length
    ? `<div class="explain">${await renderInner(explainLines.join("\n").trim())}</div>` : "";
  return `<div class="wt-quiz"><div class="q">${q}</div><div class="opts">${optHtml}</div>${explain}</div>`;
}

/* ------------------------------------------------------- share-mode chrome -- */
/* Everything below is gated behind --share and is injected chrome (not authored
   content), so it never reaches the audience linter (which scans the source md).
   A widget is a collapsible <details> per h2 section + one overall box; a single
   inline runtime wires them with addEventListener — NO inline on* handlers, NO
   javascript: URLs — so the page stays CSP-clean (script-src 'nonce-…'). */

/** Collapsible feedback widget for a section id (use "__overall__" for the box). */
function feedbackWidget(sectionId, label) {
  return `<details class="wt-feedback" data-section-id="${escapeHtml(sectionId)}">` +
    `<summary>${escapeHtml(label)}</summary>` +
    `<form data-wt-feedback-form>` +
    `<textarea class="wt-feedback-text" rows="3" placeholder="Share feedback on this section…"></textarea>` +
    `<button class="wt-feedback-send" type="submit">Send feedback</button>` +
    `</form></details>`;
}

/* Shared inline runtime (injected once). Reads view_token from the global the
   Worker injects at serve time, and the CSRF token from the __Host-csrf- cookie.
   The POST body carries ONLY {section_id, text, view_token} — no name/title/order. */
const SHARE_RUNTIME = `(function(){
  function csrf(){var m=document.cookie.match(/(?:^|;\\s*)__Host-csrf-[^=]*=([^;]*)/);return m?decodeURIComponent(m[1]):"";}
  document.querySelectorAll("form[data-wt-feedback-form]").forEach(function(form){
    form.addEventListener("submit",function(event){
      event.preventDefault();
      var box=form.closest(".wt-feedback");
      var section_id=box?box.getAttribute("data-section-id"):"";
      var ta=form.querySelector("textarea");
      var text=ta?ta.value:"";
      var view_token=window.__WT_VIEW_TOKEN__||"";
      fetch(location.pathname.replace(/\\/$/, "") + "/feedback",{
        method:"POST",
        headers:{"Content-Type":"application/json","X-CSRF-Token":csrf()},
        body:JSON.stringify({section_id:section_id,text:text,view_token:view_token})
      }).then(function(){if(box)box.classList.add("wt-feedback-sent");if(ta)ta.value="";});
    });
  });
})();`;

/* ----------------------------------------------------------------- build --- */
async function build() {
  const inputPath = path.resolve(args._[0]);
  const raw = fs.readFileSync(inputPath, "utf8");
  const { data: fm, content } = matter(raw);

  const title = fm.title || path.basename(inputPath, path.extname(inputPath));
  const audience = fm.audience || "";
  const summary = fm.summary || "";
  const tags = Array.isArray(fm.tags) ? fm.tags : (fm.tags ? [fm.tags] : []);
  const source = fm.source || "";
  const wtId = fm.id || title.toLowerCase().replace(/[^\w]+/g, "-").replace(/^-|-$/g, "");

  // Audience guardrail: the learner is the only reader. Always reported (even
  // with --quiet); --strict makes any hit fail the build.
  const auditHits = auditAudience({ title, summary, content });
  if (auditHits.length) {
    const where = path.basename(inputPath);
    console.error(`[walkthrough] ⚠ audience check: ${auditHits.length} author/agent-facing phrase(s) in ${where} — the learner is the only reader:`);
    for (const h of auditHits) console.error(`    ${h.loc}: “${h.match}” — ${h.why}`);
    console.error(`    → rewrite as a plain, positive learner-facing fact (see references/pedagogy.md).`);
    if (args.strict) {
      console.error(`[walkthrough] BUILD FAILED: --strict audience guardrail tripped.`);
      process.exit(1);
    }
  }

  const { md, blocks } = extractBlocks(content);

  // Pre-render container blocks.
  const blockHtml = [];
  for (const b of blocks) blockHtml.push(await renderBlock(b));

  // TOC pass (deterministic slugger #1).
  const slugToc = makeSlugger();
  const toc = [];
  marked.lexer(md).forEach((tok) => {
    if (tok.type === "heading" && tok.depth >= 1 && tok.depth <= 3) {
      toc.push({ level: tok.depth, text: tok.text, id: slugToc(tok.text) });
    }
  });

  // Render pass: async highlight + custom renderers (deterministic slugger #2).
  const slugRender = makeSlugger();
  // Share mode: collect h2 sections (manifest) and close the previous section
  // with its feedback widget when the next h2 opens. ids come from slugRender so
  // they match the manifest exactly.
  const shareSections = [];
  let openSectionId = null;
  marked.setOptions({ gfm: true, breaks: false });
  marked.use({
    async: true,
    walkTokens: async (tok) => {
      if (tok.type === "code") {
        const lang = (tok.lang || "").trim().split(/\s+/)[0];
        const key = codeKey(tok.text, lang);
        if (codeCache.has(key)) return;
        if (lang === "mermaid") codeCache.set(key, await renderMermaid(tok.text));
        else codeCache.set(key, await highlightCode(tok.text, lang || "text"));
      }
    },
    renderer: {
      code(code, infostring) {
        const lang = (infostring || "").trim().split(/\s+/)[0];
        const html = codeCache.get(codeKey(code, lang));
        return html || `<pre><code>${escapeHtml(code)}</code></pre>`;
      },
      heading(text, level) {
        const id = level >= 1 && level <= 3 ? slugRender(text) : "";
        const tag = `<h${level}${id ? ` id="${id}"` : ""}>${text}</h${level}>\n`;
        if (!args.share || level !== 2) return tag;
        // Close the previous h2 section with its widget, then open this one.
        const prefix = openSectionId ? feedbackWidget(openSectionId, "Feedback on this section") : "";
        openSectionId = id;
        shareSections.push({ section_id: id, title: text.replace(/<[^>]+>/g, "").trim(), order: shareSections.length });
        return prefix + tag;
      },
    },
  });

  let bodyHtml = await marked.parse(md);
  // Swap placeholders for rendered blocks (handle marked wrapping the comment in <p>).
  bodyHtml = bodyHtml.replace(/(?:<p>\s*)?<!--WTBLOCK:(\d+)-->(?:\s*<\/p>)?/g, (_, n) => blockHtml[+n]);

  // Share mode: close the final section, then add the overall feedback box.
  if (args.share) {
    if (openSectionId) bodyHtml += feedbackWidget(openSectionId, "Feedback on this section");
    bodyHtml += feedbackWidget("__overall__", "Overall feedback on this walkthrough");
  }

  // Assemble.
  const css = fs.readFileSync(path.join(ASSETS, "route-styles.css"), "utf8");
  const js = fs.readFileSync(path.join(ASSETS, "route-runtime.js"), "utf8");
  const tocHtml = toc.map((h) =>
    `<li class="lvl-${h.level}"><a href="#${h.id}">${escapeHtml(h.text)}</a></li>`).join("\n");
  const badges = [
    audience ? `<span class="wt-badge audience">${escapeHtml(audience)}</span>` : "",
    ...tags.map((t) => `<span class="wt-badge">${escapeHtml(t)}</span>`),
  ].join("");

  let mermaidRuntime = "";
  if (diagram.mode === "runtime") {
    const rt = readMermaidRuntime();
    mermaidRuntime = `<script>${rt}</script>` +
      `<script>mermaid.initialize({startOnLoad:true,theme:"default",securityLevel:"loose"});</script>`;
    log(`mermaid: inlined runtime fallback for ${diagram.count} diagram(s) (install @mermaid-js/mermaid-cli for lighter pre-rendered SVG)`);
  } else if (diagram.mode === "svg") {
    log(`mermaid: pre-rendered ${diagram.count} diagram(s) to inline SVG via mermaid-cli`);
  }

  // Share mode keeps the page CSP-clean: no javascript: URLs. The resume control's
  // click is wired in route-runtime.js via addEventListener, so a <button> works
  // identically to the anchor (which only used href="javascript:void 0" cosmetically).
  const resumeEl = args.share
    ? `<button class="wt-resume" type="button" style="display:none;font-size:12px;color:var(--wt-accent-2);background:none;border:0;padding:0;cursor:pointer;text-align:left"></button>`
    : `<a class="wt-resume" href="javascript:void 0" style="display:none;font-size:12px;color:var(--wt-accent-2)"></a>`;
  const shareScript = args.share ? `<script>${SHARE_RUNTIME}</script>` : "";

  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>${escapeHtml(title)}</title>
${summary ? `<meta name="description" content="${escapeHtml(summary)}">` : ""}
<script>!function(){try{var t=localStorage.getItem("wt-theme");document.documentElement.setAttribute("data-theme",t==="dark"?"dark":"light")}catch(e){document.documentElement.setAttribute("data-theme","light")}}();</script>
<style>${css}</style>
</head>
<body data-wt-id="${escapeHtml(wtId)}">
<div id="wt-progress"></div>
<button class="wt-theme-toggle" type="button" aria-label="Toggle light or dark theme" title="Toggle light/dark"><span class="ic-sun" aria-hidden="true">☀</span><span class="ic-moon" aria-hidden="true">☾</span></button>
<button class="wt-nav-open" type="button" aria-label="Open contents" title="Contents">☰</button>
<div class="wt-nav-scrim" aria-hidden="true"></div>
<div class="wt-shell">
  <aside class="wt-sidebar">
    <div class="wt-sidebar-top"><button class="wt-nav-collapse" type="button" aria-label="Collapse contents" title="Collapse">«</button></div>
    ${source ? `<p class="wt-eyebrow">${escapeHtml(source)} walkthrough</p>` : `<p class="wt-eyebrow">walkthrough</p>`}
    <h1>${escapeHtml(title)}</h1>
    ${summary ? `<p style="color:var(--wt-muted);font-size:13px;margin:.2em 0 0">${escapeHtml(summary)}</p>` : ""}
    <div class="wt-meta-badges">${badges}</div>
    ${resumeEl}
    <ul class="wt-toc">${tocHtml}</ul>
  </aside>
  <main class="wt-main">
    <article class="wt-content">
      ${bodyHtml}
    </article>
    <footer class="wt-footer">
      <span>Generated by the <strong>walkthrough</strong> skill · self-contained &amp; offline</span>
      <button class="wt-reset" title="Clear saved progress">Reset progress</button>
    </footer>
  </main>
</div>
${mermaidRuntime}
<script>${js}</script>${shareScript}
</body>
</html>`;

  const outPath = args.out
    ? path.resolve(args.out)
    : path.join(path.dirname(inputPath), `${wtId || "walkthrough"}.html`);
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, html, "utf8");
  const kb = (Buffer.byteLength(html) / 1024).toFixed(1);
  log(`wrote ${outPath} (${kb} KB, ${toc.length} headings, ${diagram.count} diagram(s), mode=${diagram.mode})`);

  // Share mode: emit the section manifest next to the output for the CLI to read.
  // ids come from the same render slugger, so they match the injected widgets.
  if (args.share) {
    const manifestPath = `${outPath}.manifest.json`;
    fs.writeFileSync(manifestPath, JSON.stringify(shareSections, null, 2), "utf8");
    log(`wrote section manifest ${manifestPath} (${shareSections.length} section(s))`);
  }

  // Emit a manifest line for the hub to consume.
  return { title, slug: wtId, file: outPath, audience, summary, tags, source, bytes: Buffer.byteLength(html) };
}

build().catch((e) => { console.error("[walkthrough] BUILD FAILED:", e); process.exit(1); });
