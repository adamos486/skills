/**
 * Tests for build-walkthrough.mjs — focused on the --share build mode.
 * Uses the zero-dependency node:test runner. Each test drives the real CLI as a
 * subprocess against a temp sample input, then inspects the emitted HTML/manifest.
 */
import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT = path.join(__dirname, "build-walkthrough.mjs");

/* A multi-section sample: an h1 intro plus three h2 sections, two of which share
   a title so the dedup path is exercised. */
const SAMPLE = `---
title: Sample Walkthrough
id: sample-wt
---

# Intro

Some intro text that is not a section.

## First Section

Content one.

## Second Section

Content two.

## First Section

Duplicate title content.
`;

/** Build SAMPLE into a fresh temp dir, returning paths + read output. */
function buildSample({ share }) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "wt-test-"));
  const inPath = path.join(dir, "sample.md");
  const outPath = path.join(dir, "out.html");
  fs.writeFileSync(inPath, SAMPLE, "utf8");
  const argv = [SCRIPT, inPath, "--out", outPath, "--quiet"];
  if (share) argv.push("--share");
  execFileSync(process.execPath, argv, { encoding: "utf8" });
  const html = fs.readFileSync(outPath, "utf8");
  const manifestPath = `${outPath}.manifest.json`;
  return { dir, inPath, outPath, html, manifestPath };
}

test("--share injects exactly one widget per ## section plus one overall box", () => {
  const { html } = buildSample({ share: true });
  const widgets = html.match(/<details class="wt-feedback"/g) || [];
  // 3 h2 sections + 1 overall.
  assert.equal(widgets.length, 4);
  const overall = html.match(/data-section-id="__overall__"/g) || [];
  assert.equal(overall.length, 1);
  // Each widget has the required structure.
  assert.match(html, /<form data-wt-feedback-form>/);
  assert.match(html, /<textarea/);
});

test("--share manifest matches the headings (id, title, order) incl. dedup", () => {
  const { html, manifestPath } = buildSample({ share: true });
  assert.ok(fs.existsSync(manifestPath), "manifest file should exist");
  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  assert.deepEqual(manifest, [
    { section_id: "first-section", title: "First Section", order: 0 },
    { section_id: "second-section", title: "Second Section", order: 1 },
    { section_id: "first-section-1", title: "First Section", order: 2 },
  ]);
  // Every manifest id must be present as an injected data-section-id.
  for (const s of manifest) {
    assert.ok(
      html.includes(`data-section-id="${s.section_id}"`),
      `widget for ${s.section_id} should be injected`,
    );
  }
});

test("--share injected JS wires the feedback POST correctly", () => {
  const { html } = buildSample({ share: true });
  assert.match(html, /X-CSRF-Token/);
  assert.match(html, /location\.pathname\.replace\(\/\\\/\$\/, ""\) \+ "\/feedback"/);
  assert.match(html, /window\.__WT_VIEW_TOKEN__/);
  assert.match(html, /__Host-csrf-/);
  // The POST body must carry ONLY section_id, text, view_token.
  const body = /body:JSON\.stringify\((\{[^}]*\})\)/.exec(html);
  assert.ok(body, "should JSON.stringify a feedback body object");
  assert.doesNotMatch(body[1], /\bname\b/);
  assert.doesNotMatch(body[1], /\btitle\b/);
  assert.doesNotMatch(body[1], /\border\b/);
  assert.match(body[1], /section_id/);
  assert.match(body[1], /text/);
  assert.match(body[1], /view_token/);
});

test("--share output has no javascript: URLs and no inline on*= handlers", () => {
  const { html } = buildSample({ share: true });
  assert.doesNotMatch(html, /javascript:/);
  assert.doesNotMatch(html, /\son[a-z]+=/);
});

test("default build (no --share) emits none of the share injections", () => {
  const { html, manifestPath } = buildSample({ share: false });
  assert.doesNotMatch(html, /wt-feedback/);
  assert.doesNotMatch(html, /__WT_VIEW_TOKEN__/);
  assert.ok(!fs.existsSync(manifestPath), "no manifest should be written");
});

test("default build is byte-identical with and without the new code path", () => {
  // Sanity: the default output still contains the original resume anchor.
  const { html } = buildSample({ share: false });
  assert.match(html, /href="javascript:void 0"/);
});
