# Leanplan analysis reference

## Pass A — evidence-triggered safeguard checks

These fire on what the plan **contains**, not on how confident you feel. If the trigger is present
and the plan does not address the required topics, that is a finding.

| Trigger present in plan or repo | Plan must address |
|---|---|
| PII, personal data, user accounts | access control, secrets handling, data retention/deletion, failure handling |
| Authentication or authorization | identity source, who may perform each operation, session/token handling |
| Payments, billing, financial records | idempotency, reconciliation, audit trail, failure/refund path |
| Production schema change | migration, backward compatibility, rollback, recovery |
| Destructive operation (delete, overwrite, truncate, bulk update) | recovery path, idempotency, confirmation/dry-run |
| Public or consumer-facing API change | compatibility, versioning, deprecation path |
| Accepts user-supplied URLs, paths, or templates | validation and injection/redirect safety |

**Reporting rule:** silence from these checks means no trigger fired *or* the plan already covers
them. Report which triggers fired and how the plan answered. Never write "no safety concerns."

## Stakes calibration

Triggers fire on **content**. Stakes decide what counts as **answering** them. Read stakes from the
plan and repo, state them in one line, and mark them `established` or `supported`.

| Dimension | Read from |
|---|---|
| Audience | Who uses it — the author alone, an internal team, or external/paying users |
| Blast radius | What breaks if it's wrong — nothing, an annoyance, or money/data/privacy |
| Longevity | Throwaway, or load-bearing for years |

**Applying stakes to a fired trigger:**

| Stakes | An adequate answer looks like |
|---|---|
| Author-only, no external exposure, throwaway | Naming the risk and accepting it in one line. Do **not** demand access control, retention policy, deletion paths, or audit trails. |
| Internal team, recoverable blast radius | A stated mechanism, even an informal one ("token scope enforces read-only"). |
| External users, or money/data/privacy at risk | An explicit mechanism plus a failure path. |

**A trigger firing on a low-stakes plan is not automatically a finding.** If the plan's own stakes
make the risk acceptable, record it as answered-by-context and move on. Demanding enterprise
safeguards from a personal script is the mirror image of over-engineering, and this skill exists to
prevent both.

**Scope limit — stakes govern `safeguard-gap` only.** They have no bearing on `outcome-gap`,
`acceptance-gap`, `contradiction`, `stack-divergence`, or any Pass B label. A behavior with no work
item is missing whether the plan is a weekend script or a payments system; a lean plan does not earn
exemption from coverage checks by being lean.

| Rationalization | Reality |
|---|---|
| "It's a small plan, I shouldn't nitpick" | Coverage gaps are not nitpicks. File it. |
| "A critic is tempted to manufacture work here" | True for Pass B. Pass A findings are not manufactured — the row said `NONE`. |
| "The author obviously knows they need that" | Then the plan can say so in one line. Unstated is unbuilt. |

**Stakes never suppress a trigger for external users, money, or third-party data.** No stated
stakes make an open redirect or an unauthenticated refund endpoint acceptable.

## Pass A — outcome coverage

Trace each direction explicitly and report gaps:

- **Forward:** goal → required behavior → planned work. A behavior with no work item is a gap.
- **Backward:** planned work → required behavior. Work with no behavior behind it is a Pass B candidate.
- **Acceptance:** planned work → acceptance evidence. Work no criterion exercises is untested by the plan's own standard.

Also check that acceptance criteria are **derived from the goal**, not from the architecture. A
coverage target measured against layers the plan invented is a vanity metric — flag it.

## Severity rubric

Based on outcome impact and reversibility, not on how much code is involved.

| Severity | Definition |
|---|---|
| `blocking` | The plan cannot achieve its stated goal, violates a hard constraint, or creates a credible risk of severe harm |
| `significant` | Material delivery or risk impact, or substantial avoidable work |
| `minor` | Localized improvement, low outcome impact |

Reversibility raises severity: work that is cheap to add later but expensive to remove later
(schema columns, extension seams, public API surface, retention policies) sits at least at
`significant` when unjustified.

All distinct supported issues are retained. Repeated lens activations are not separate issues.

## Research admissibility

Research a stack question **only** when its answer could materially change an issue. A claim is
admissible only when all four hold:

1. **Version-matched** to the detected component version from `detect-stack.sh`
2. **Sourced** by normative official documentation, or two independent high-quality primary sources
3. **Classified** as `required` / `recommended` / `contextual` / `contested`
4. **Explained** — how the cited text supports the claim

Record in the artifact: source URL, retrieval date, detected version, and a short verbatim quote.

**Official option vs. official recommendation.** Documentation showing that a framework *supports* a
pattern does not establish that it *recommends* it. Quote the normative sentence — look for "should",
"recommended", "prefer", "avoid". If the source only demonstrates the pattern exists, classify
`contextual`, not `recommended`.

**Consequences of classification:**

| Class | May set severity | May drive `[A]` bulk apply |
|---|---|---|
| `required` | yes | yes |
| `recommended` | yes | yes |
| `contextual` | no | no |
| `contested` | no | no |
| unsourced | no | no |

Rank research by affected work-item count and operational risk. Disclose any relevant technology you
did not research — an undisclosed gap reads as coverage.
