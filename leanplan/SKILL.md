---
name: leanplan
description: Use when a plan, spec, design doc, brainstorm, or walkthrough needs review before anyone implements it — especially when it may be over-engineered, over-abstracted, or scoped past a lean MVP. Triggers include "review this plan", "is this over-engineered", "is this too much for an MVP", "sanity check this design", "trim this spec", and handoff moments before writing-plans, superplan, or superbuild.
---

# Leanplan

## Overview

Challenge whether a plan can achieve its **stated outcome** with the least justified complexity —
then record what the user decided, without silently rewriting their document.

**Core principle: prove the plan works before you cut it.** A critic that only subtracts will
eventually cut something the goal required. Outcome coverage comes first; complexity comes second.

## When to Use

- A plan/spec/design exists and implementation hasn't started
- Someone suspects scope creep, speculative abstraction, or AI-slop scaffolding
- Before handing a plan to `superbuild`, `writing-plans`, or an implementing agent

**Not for:** reviewing a code diff (use `/code-review`), or creating a plan (use `superplan`).

## Workflow

### 1. Ingest and build the outcome model

Resolve the plan in this order: explicit path argument → a plan in the current conversation →
auto-discovery candidates in `docs/plans/`, `docs/superpowers/specs/`, or `*plan*.md` → ask.
**Auto-discovery proposes candidates and asks; it never silently picks the newest file.**

Do not flatten the source into a task list. Build the smallest model it supports:

```
goal → required behaviors and hard constraints → proposed work items and dependencies → acceptance evidence
```

Also retain assumptions, non-goals, rejected alternatives, and **source spans** (file + line range)
when the format preserves them. Mark every extracted claim:

| State | Meaning |
|---|---|
| `established` | Explicit in the source, or asserted directly by the plan's author (including in a transcript) |
| `supported` | Not stated, but backed by two independent repository signals |
| `unknown` | Cannot be determined from plan or repo |

**Transcripts:** the author's statements are `established`. Work items that appear only in an
assistant's or a third party's summary turn are `proposed` until the author ratifies them —
and a cut that removes never-ratified work carries a lower bar than one removing work the author
asked for. Say which turns you treated as plan content.

**Review-only mode.** Enter it when source spans are not **patchable** — not merely when they
exist. Rendered HTML spans point at generated output; transcript lines point at conversational
turns, not plan elements. Both are citable and neither is editable. Say you are in review-only
mode, do not claim the conversion was lossless, and do not offer mutation.

**Review-only changes nothing else.** Stages 2–6 run unchanged: detector, coverage table, research
section, triage gate, artifact. It suppresses mutation, not rigor.


### 2. Detect the stack

```bash
scripts/detect-stack.sh --repo <the plan's repo> --plan <path>
scripts/detect-stack.sh --no-repo --plan <path>      # standalone plan, no repository
```

**Pass one or the other, always.** The script refuses to scan an implicit working directory,
because reviewing a standalone plan from an unrelated checkout would otherwise produce a
confident, fully-formed, completely wrong stack. If `--no-repo` applies, nothing can reach
`used`, so the research floor is structurally `UNRUN` — say so rather than implying coverage.

Emits one evidence-bearing claim per component. `status` distinguishes `established` (language
manifest), `used` (structural usage found), `declared` (in a manifest, never imported), `proposed`
(named by the plan only), and `unknown` (ecosystem outside the tested five).

**A plan naming a technology is evidence of intent, never of adoption.**

**Divergence is triageable.** When the plan proposes a technology the repo already solves another
way — a second frontend framework, a second ORM, a second queue — file it as `stack-divergence` so
it reaches the gate. Divergence that is the plan's stated purpose ("migrate off X") is not a
finding. A prose mention is not enough: an untriaged observation never becomes a decision.

### 3. Analyze — Pass A before Pass B

**Pass A — outcome, consistency, safeguards.** Run before proposing any cut.

**REQUIRED — emit this coverage table before any other Pass A output.** One row per required
behavior and hard constraint. Never summarize it in prose; never skip it because the plan looks
thorough. A row whose work item is `NONE` is an `outcome-gap` finding.

| Required behavior / constraint | Delivered by | Exercised by |
|---|---|---|
| *(from the goal)* | *(work item, or `NONE`)* | *(acceptance criterion, or `NONE`)* |

Then check: no material contradictions; dependencies and ordering feasible; assumptions and
unknowns visible.

Then run the evidence-triggered safeguard checks — see `references/analysis.md`. These fire on what
the plan *contains* (PII, auth, payments, schema change, destructive operation, public API change),
not on a confidence estimate. **Silence from these checks is not proof of safety; never report it
as such.**

**State the stakes in one line** — audience, blast radius, longevity — drawn from the plan and repo.
Example: *"Personal tool, single user, data never leaves the machine, throwaway."* Mark it
`established` or `supported`.

**Stakes govern `safeguard-gap` and nothing else.** They decide what counts as *answering* a fired
trigger. They never decide whether a trigger fires, and they have **no bearing** on coverage,
acceptance, contradiction, or any Pass B finding. A missing work item is missing at every stakes
level.

**Pass B — unnecessary complexity.** Three tags: **MVP/YAGNI** (speculative generality, premature
abstraction, future-only phases, unused config, requirement inflation), **design quality** (DRY,
modularity, dependency inversion, testability), and **applicable operational concerns** (12-factor
for deployed services only; researched stack guidance).

These are **tags, not finding generators. One defect is one issue**, however many explain it. Cite
the mechanism, never the authority — "this has four reasons to change, here they are" is a finding;
"this violates SRP" is an appeal.

Every proposed cut must survive the refutation question:

> What concrete current requirement, repository constraint, or credible failure mode would make
> this work necessary?

**Never re-propose a rejected alternative.** If the source records that an approach was considered
and rejected, it is settled. Re-raising it as a Pass B finding re-litigates a decision the author
already made — the exact failure this skill exists to prevent. Cite the rejection instead.

**Two triggers, one defect.** When two safeguard triggers fire on the same underlying gap (missing
identity satisfies both the auth and the PII trigger), file **one** group and note the second
trigger as covered by it. Report the trigger as fired either way — one group per fired trigger is
the ceiling, not a quota.

If a recommendation materially depends on an `unknown`, ask for that one fact. Nothing else.

### 4. Research — a floor, then depth on demand

**Floor.** For every framework the detector reports as `used` with a version, produce a short sourced
practice summary — what its current docs recommend for the kind of work this plan proposes. Present
it as its own section, **before triage and separate from findings**. It is a deliverable in its own
right; it does not have to become a finding to be worth showing. Cap at the three frameworks most
central to the plan and say which you skipped.

**The section is mandatory; the research is not always possible.** If you cannot retrieve sources —
no network, a non-interactive run, a tool failure — still emit the section, list the qualifying
frameworks and versions, and mark it `UNRUN: <reason>`. Never omit it.

| Rationalization | Reality |
|---|---|
| "Non-interactive run, so I skipped it" | Emit the section marked `UNRUN`. Skipping hides the gap. |
| "No finding depends on research" | The floor is a readback for the user, not an input to findings. |
| "The stack is obvious / I know this framework" | Unsourced recall cannot set severity. Cite or mark `UNRUN`. |
| "Only `declared` deps, nothing to research" | Correct — say so in the section. Still emit it. |

**Depth (on demand).** Research a specific question further when its answer could materially change
an issue.

Admissibility rules and the `required`/`recommended`/`contextual`/`contested` classification are in
`references/analysis.md`. Unsourced or contested claims may be shown as context but **cannot set
severity or drive bulk application**. Disclose relevant technology you did not research.

### 5. Triage — one group at a time

Assign every issue exactly one label from the **closed set** in `references/root-causes.md`, then
form **one group per label present** (`safeguard-gap`: one group per fired trigger). Do not invent
labels — grouping is classification, not clustering, and inventing categories is what makes group
boundaries vary run to run. Sort `blocking → significant → minor`.

For each group, emit exactly these parts in order, then stop and wait:

```
GROUP: <label> — <one-line specific statement>  [<severity> · <n> affected work items]

Affects: <work items with source spans>
Why flagged: <evidence — what in the plan or repo supports this>
Outcome impact: <what it costs the stated goal>

Proposed resolution:
  <the exact textual consequence of accepting>

  [A] Apply to all <n>    [S] Show individually
  [M] Specify my own      [K] Keep as planned (with reason)
```

Call it a **proposed resolution**, never a "best practice."

- `[A]` — **draft the resolution sentence first, then decide.** Offer `[A]` only when the group holds
  two or more issues and that sentence applies verbatim to every one of them. If it needs "and also"
  or a per-item clause, the edits are not identical — omit `[A]`. Same severity, same evidence basis,
  and no contested research dependency are additional requirements, not substitutes for the test.
- `[S]` — default for heterogeneous groups; omit it when the group holds one issue
- **Single-issue group:** offer `[Y] Accept  [M] Specify my own  [K] Keep as planned`. Never render
  "apply to all 1."
- `[K]` — record the user's reason verbatim; it ships in the artifact as a documented deliberate choice

Never present the next group before the current one is decided.

**A decision can change earlier ones.** Two cases, both of which must be surfaced, not absorbed:

- **`[K]` that supplies missing evidence.** "Legal says a second tenant onboards in Q1" doesn't
  outweigh the `absent-consumer` finding — it makes its premise false, and may revive work cut
  elsewhere. Re-check decided groups against the new fact and say what it reopens.
- **`[M]` that only partially closes a gap.** If the user's own resolution covers part of a coverage
  row, keep that row **open and marked deferred**. Never let a partial fix silently close a Pass A
  gap — the row existing is the entire point of Pass A.

### 6. Write the review artifact, then offer a patch

**Always write `<plan-name>-leanplan-review.md` first**, before any mutation is offered — **beside
the plan** when the plan is a file, otherwise in the working directory. It carries
the outcome model, evidence states, detected stack, research provenance, every distinct issue, the
user's decision, and `[K]` reasons. The review and its subject stay separate records.

Then offer a patch for accepted changes only. **Show the patch before applying.** Re-run Pass A
coverage and contradiction checks after applying.

**Refuse mutation** for: conversation-only plans, HTML, JSON, generated files, paths outside the
workspace, ambiguous multi-file plans, files with overlapping uncommitted changes, and any plan
selected solely through auto-discovery.

**Never commit.** Report the artifact is ready and stop.

## Red Flags — stop and correct

- About to propose a cut before Pass A finished → run Pass A first
- Pass A coverage table not emitted, or summarized in prose → emit the table, one row per behavior
- Suppressed a coverage gap because the plan is small or lean → stakes don't reach Pass A
- Skipped the research section because the run is non-interactive → emit it marked `UNRUN`
- Same defect filed under three lenses → one defect is one issue
- Invented a group name outside the closed label set → reclassify into an existing label
- Two groups sharing a label (other than `safeguard-gap`) → merge them
- Offering `[A]` on a group with mixed edits → omit `[A]`, use `[S]`
- Citing a practice with no source, or a source whose version doesn't match → it cannot set severity
- Writing "no safety issues found" → you found no *triggered* issues; say that instead
- Editing the plan before the review artifact exists → artifact first, always
- Reporting `proposed` stack claims as if the repo uses them → check `status`

## Reference

- `references/root-causes.md` — closed label set, grouping rule, tie-breaks
- `references/analysis.md` — safeguard triggers, Pass B categories, severity rubric, research admissibility
- `scripts/README.md` — detector contract and claim schema
- `fixtures/` — test plans with expected labels; run these after editing the skill
