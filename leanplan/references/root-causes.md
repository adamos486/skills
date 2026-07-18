# Root-cause labels (closed set)

Grouping is **classification, not invention**. Every issue gets exactly one label from this list.
Do not create new labels. If an issue seems to need one, it is almost always `absent-consumer` or
`disproportionate-operation` — re-read those two before inventing.

| Label | Definition | Typical source |
|---|---|---|
| `outcome-gap` | A required behavior or hard constraint has no work item that delivers it | Pass A forward |
| `acceptance-gap` | The goal or planned work is not exercised by any acceptance evidence, or acceptance is derived from the architecture rather than the goal | Pass A acceptance |
| `safeguard-gap` | A safeguard trigger fired and the plan does not answer it | Pass A triggers |
| `contradiction` | The plan is internally inconsistent, or its ordering/dependencies are infeasible | Pass A consistency |
| `invented-requirement` | An unsourced scale, load, retention, or availability figure — **and the work it funds** | Pass B |
| `absent-consumer` | An extension seam, plugin point, event bus, feature flag, strategy interface, or tenancy dimension with no current second consumer | Pass B |
| `premature-indirection` | An abstraction or layer with one real implementation, or whose second implementation exists only for tests | Pass B |
| `disproportionate-operation` | Resilience, observability, or retention machinery sized past the plan's **established** scale | Pass B |
| `stack-divergence` | The plan introduces a technology the repo already solves another way, without stating that replacement is the goal | Detector |

## Grouping rule

**One group per label present** — issues sharing a label merge into a single group, however many
phases they span. This is what makes group count reproducible across runs.

**Exception:** `safeguard-gap` forms **one group per fired trigger**. Missing authentication and
missing URL validation are different defects requiring different fixes; merging them produces an
unactionable group.

Maximum groups = 8 non-safeguard labels + one per fired trigger.

## Tie-breaks

Apply in order. The first matching rule wins.

1. **A fired safeguard trigger always wins.** Deletion with no recovery path is `safeguard-gap`, not
   `disproportionate-operation`, even if the deletion machinery is also oversized.
2. **An unsourced figure beats the work it funds.** If a load/scale/retention number with no stated
   source is the reason work exists, label the number and the work together as
   `invented-requirement`. Only use `disproportionate-operation` when the work is oversized relative
   to a *sourced or established* scale.
3. **No consumer beats one implementation.** A seam built for hypothetical future callers is
   `absent-consumer`. An abstraction over a real, current, single implementation is
   `premature-indirection`. If both apply, the missing consumer is the root cause.
4. **Delivery beats quality.** If a work item is both unbuilt and over-abstracted, `outcome-gap`
   wins — you cannot trim what does not yet deliver.

## Severity by label

Labels do not set severity; outcome impact does. But these defaults hold unless evidence moves them:

| Label | Default |
|---|---|
| `outcome-gap` | `blocking` |
| `safeguard-gap` | `blocking` if it risks harm or data loss, else `significant` |
| `contradiction` | `significant` |
| `acceptance-gap` | `significant` |
| `invented-requirement` | `significant` |
| `absent-consumer` | `significant` (reversibility: seams are expensive to remove) |
| `premature-indirection` | `significant` |
| `disproportionate-operation` | `minor` unless it carries ongoing cost or liability |
| `stack-divergence` | `significant` — a parallel stack is ongoing maintenance, not a one-time cost |
