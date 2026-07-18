# Leanplan fixtures

Run these after editing `SKILL.md`, `references/root-causes.md`, or `references/analysis.md`.
Each fixture asserts an **expected label set**, not expected prose. Group *count* and *labels*
must reproduce across runs; wording will not.

## How to run

Dispatch a fresh subagent per fixture, told to read the skill and follow it, and to stop at the
triage gate showing group 1 verbatim plus the remaining groups with labels and severities.
Run fixture 01 at least three times — stability across runs is the thing being measured.

## 01-overbuilt-shortener.md

The regression fixture. A 12-person internal tool planned as multi-tenant SaaS.

**Expected: 11 groups** — all 8 non-safeguard labels, plus one per fired safeguard trigger
(user-supplied URLs, authn/authz, destructive operation). Observed 11/9/11.

**Required in every run:** `outcome-gap` present, `blocking`, presented first. Losing it is a
hard failure — it is the highest-value finding this fixture carries.

**Known-variable:** `contradiction` and `stack-divergence` are found in most but not all runs
(one run argued a React SPA is not divergent from a Next.js app, which is defensible). `[A]` is
stable — offered on exactly the four Pass B groups, withheld from `outcome-gap`,
`acceptance-gap`, and `contradiction`.

| Label | Must cover |
|---|---|
| `contradiction` | Feature flags gating paths shipped in earlier phases; cache/RLS interaction |
| `disproportionate-operation` | OTel spans per layer, Prometheus per repository method |

Core labels:

| Label | Must cover |
|---|---|
| `outcome-gap` | No work item delivers the `go/` hostname; no work item accepts a human-chosen slug |
| `acceptance-gap` | No criterion exercises create→resolve; coverage measured against invented layers; tenant-onboarding runbook for a nonexistent tenant |
| `safeguard-gap` (user-supplied URLs) | Arbitrary redirect target, no scheme validation |
| `safeguard-gap` (auth) | No identity source despite `LinkOwner`, per-user limits, and `DELETE` |
| `safeguard-gap` (destructive op) | Delete has no recovery, idempotency, or tombstone |
| `invented-requirement` | Unsourced 10,000 req/s **and Phase 4 in full**, which it funds |
| `absent-consumer` | Multi-tenancy, plugin system, feature flags, webhook DLQ, event bus, three slug strategies |
| `premature-indirection` | Repository ABC + in-memory impl, UnitOfWork over a SQLAlchemy session |

**Known-variable, not a failure:** the 7-year retention lands in `invented-requirement` or
`safeguard-gap` (PII) depending on run — either is acceptable, but it must not vanish. Severity of
the authn/authz group varies `blocking`/`significant` across runs.

**Every run must emit** the Pass A coverage table (one row per behavior, `NONE` where unmet) and a
research section — marked `UNRUN: <reason>` with qualifying frameworks listed when sources cannot
be retrieved. Omitting either is a failure.

**Anti-assertions — the run fails if any of these happen:**
- Two groups share a non-`safeguard-gap` label
- A group name appears that is not in the closed set
- `[A]` is offered on a group whose issues need different edits
- `outcome-gap` is not `blocking`, or is not presented first
- Any group beyond the first is presented before group 1 is decided

## 02-lean-baseline.md

The false-positive fixture. A genuinely lean plan that should survive nearly intact. A critic that
manufactures findings here is worse than no critic.

**Expected: 3 groups, all Pass A.** The plan is lean but not clean — it has genuine gaps the
critic should find:
- `outcome-gap` (`blocking`) — acceptance requires `--dry-run`; no work item builds it. **This is
  the stakes-scope regression check:** a lean plan earns no exemption from coverage checks. A run
  that suppresses this finding as "not nitpicking a small plan" has failed.
- `acceptance-gap` — skip-when-empty and the cron schedule are unexercised
- `safeguard-gap` (auth) — the GitHub API call names no identity source, and the read-only
  constraint rests on convention rather than token scope

**The real anti-assertion — zero Pass B findings.** No `absent-consumer`,
`premature-indirection`, `invented-requirement`, or `disproportionate-operation`. One script, no
abstraction, no unsourced figure. Any Pass B finding here is a manufactured one, and a critic that
manufactures findings on a lean plan is worse than no critic.

**Singleton rendering:** single-issue groups must render `[Y] Accept` — **never "apply to all 1."**

## 03-high-stakes.md

The under-cutting fixture. A refund service whose idempotency keys, append-only audit table,
bounded retries, reconciliation job, and group restriction all *look* like over-engineering and are
each demanded by a fired trigger.

**Expected: 0–1 groups.** The plan answers every trigger it fires.

**Anti-assertions — these are the failure this fixture exists to catch:**
- Proposing to cut idempotency, the audit table, retry-with-same-key, reconciliation, or the SSO
  group restriction. Each must survive the refutation question, because payments, PII, and
  destructive-operation triggers all fire and the plan answers them.
- Labeling `refund_events` as `disproportionate-operation` — it answers the payments trigger.
- Reporting "no safety issues found." The correct report names which triggers fired and how the
  plan answered them.

## 06-walkthrough.html and 07-conversation.txt

The ingestion fixtures. Both must be run with `--no-repo`.

**Both must:** enter review-only mode citing *patchable* spans (not format identity), run Stages 2–5
in full, emit the coverage table and a research section marked `UNRUN`, and refuse mutation.

**06 specifically** — the walkthrough records that a generic preferences framework was considered
and **rejected**. Re-proposing it as a Pass B finding is a hard failure: it re-litigates a settled
decision, the exact behavior this skill exists to prevent.

**07 specifically** — the work items exist only in an assistant's summary turn, ratified by the
author saying "right." The run must state which turns it treated as plan content. Getting this
wrong changes findings in both directions: unratified, batching becomes a spurious Pass B cut;
ratified, the upsert-vs-no-duplicate mismatch becomes a real `safeguard-gap`.

**Contamination check:** neither run may emit repo claims. A run that reports a populated stack for
these plans has scanned an unrelated directory.

## 04-low-stakes-trigger.md

The over-firing fixture. A personal birthday script that reads a local contacts CSV. The PII
trigger **fires on content** — and the stakes (author-only, local-only, throwaway, self-healing)
make naming the risk a sufficient answer.

**Expected: 0–1 groups.**

**Anti-assertions — the failure this fixture exists to catch:**
- Demanding access control, encryption at rest, a retention policy, a deletion path, or an audit
  trail for a local CSV the author already owns. Enterprise safeguards on a personal script are
  over-engineering wearing a safety costume.
- Any Pass B finding. One file, stdlib only, no abstraction, no unsourced figure.
- Reporting the PII trigger as unanswered. Correct handling: it fired, and the stated stakes answer
  it — recorded as answered-by-context.
- Failing to state the stakes line at all.

## 05-disputed-stack.md

The research fixture. A Next.js App Router plan whose central choice — wrapping the entire page
tree in a client boundary so a header search box can hold state — is settled by current framework
guidance, not by general principle.

**Expected:** the research floor **fires and is presented as its own section before triage**, with
sourced practice notes for Next.js App Router (detector reports `nextjs-app-router` 15.2.1 `used`).

**Also expected:** a finding that root-layout client-boundary wrapping forfeits server rendering
for the whole site — sourced, not asserted from general principle.

**Anti-assertions:**
- No research section at all. The floor is a standing obligation, not issue-triggered.
- Citing a practice with no URL, or one whose version doesn't match 15.2.1.
- Presenting an official *option* as an official *recommendation* without a normative quote.
- Letting a `contextual` or `contested` claim set severity or drive `[A]`.
