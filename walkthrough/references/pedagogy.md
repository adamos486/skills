# Authoring Pedagogy (non-gating, self-paced)

You are authoring a **learning artifact**, not a summary. The reader should come away
able to explain and apply the material, not just recognize it. This skill borrows the
pedagogical backbone of the repo's `teach` skill but renders it **static, self-paced,
and never gating** — the learner is in control at all times.

**REQUIRED BACKGROUND:** Skim the `teach` skill for the evidence base (Bloom's taxonomy,
prerequisite scaffolding, mastery ladders). Here we use those ideas to *structure and
brainstorm* content — we never block the reader on a quiz.

## The learner is the only reader (hard rule)

Everything that renders in the browser — every route, the hub, every callout, reveal,
diagram caption, and table — is written **for the learner and no one else**. The learner
never sees, and must never be addressed by, anything meant for the *author*, a *reviewer*,
an *agent*, or a future editor. The page is a lesson, not a workspace.

**Never render, in any form a browser shows:**

- **Authoring meta-commentary** — "an older draft said…", "a previous model claimed…",
  "this was corrected", "myth correction", "verified against source", "the docs had
  drifted", "fact-checked". The learner has no prior draft to correct against; to them
  there is only *this* lesson.
- **Instructions to the author/agent** — "don't teach the old version", "we should…",
  "note: rewrite this", "TODO", "FIXME", "as the author you…".
- **Process exhaust** — how the content was produced, what was checked, which sources were
  read, what an earlier version got wrong.

**Why:** meta-commentary breaks the lesson's frame and confuses the learner — they don't
know what "the 4-category version" is, and telling them not to learn it plants the wrong
idea while wasting their attention. State the correct thing **plainly and positively**, as
settled fact, with no reference to the path that got you there.

> ❌ *"Myth correction. An older model described 4 categories with a severity per category.
> That's wrong — the real design is 9 categories, severity per pattern. Don't teach the
> 4-category version."*
>
> ✅ *"The scanner sorts threats into **9 categories**, and severity is assigned **per
> pattern** — a single category (e.g. dangerous scripts) spans MEDIUM to CRITICAL."*

If you discover the source you ingested was itself wrong, you simply teach the truth — you
do **not** narrate the discrepancy to the learner. (Keep that correction in your reply to
the user instead, where it belongs.)

The build step runs an **audience linter** (`build-walkthrough.mjs`) that flags common
meta/author-facing phrases as warnings — treat any hit as a defect to rewrite, not noise.

## Write for the declared audience

The frontmatter `audience` is your target. It changes depth, vocabulary, and emphasis:

| Audience | Emphasize | Go light on |
|----------|-----------|-------------|
| Engineers | code paths, data flow, failure modes, trade-offs | business framing |
| PMs | what/why, user impact, constraints, sequencing | implementation detail |
| Designers | flows, states, edge cases, system vocabulary | backend internals |
| Mixed/new hires | the mental model first, then specifics | jargon without definition |

Define every term the first time. One concept at a time.

## Structure with Bloom's, ordered low → high

Order sections so prerequisites come first, then climb cognitive levels. You don't label
levels in the output — you just sequence the content this way.

1. **Remember/Understand** — explain the concept in plain language, define terms.
2. **Apply** — a concrete, walked-through example (real, not contrived).
3. **Analyze/Evaluate** — trade-offs, when it breaks, compare alternatives.
4. **Create** (optional) — invite the reader to design or modify something.

A good section: *context connection → core explanation → concrete example → second
example or edge case → crisp summary.*

## Use the interactive blocks deliberately

- **`:::reveal`** — pose a question, let the reader *try before seeing the answer*. This
  is the highest-value primitive: retrieval practice without pressure. Use it at the
  Apply/Analyze moments ("What would happen if…?", "Predict the output").
- **`:::quiz`** — a self-check after a section. Always include an explanation (`>`) — the
  explanation teaches, the answer just routes attention. Non-gating: wrong answers
  explain and invite a retry.
- **`:::callout`** — surface the common mistake (`warning`), the pro insight (`tip`), the
  aside (`note`). Misconceptions are where learning happens; name them explicitly.

## Non-gating is a hard rule

Never write "you must answer correctly to continue" or hide later sections behind a quiz.
Everything is visible and skippable. Progress (the top bar + saved position) reflects
*reading*, not *passing*. The learner sets the pace.

## Calibrate to the source

- **Onboarding / design / repo** → deeper: mental model, architecture, why-it-is-this-way,
  failure modes, where to look in the code.
- **PR / plan review** → focused: what changed, why, risks, what to verify, alternatives
  considered.
- **Blog / book / lecture / transcript** → distill the thesis, the supporting moves, and
  the parts worth disagreeing with; add checks that test understanding, not recall.

## Quality bar

- Every claim a reader could doubt has an example or a reason next to it.
- Every diagram earns its place (it shows structure words can't).
- At least one `:::reveal` or `:::quiz` per major section — but only where it genuinely
  tests understanding, never as filler.
