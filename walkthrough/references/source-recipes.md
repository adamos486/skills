# Source Recipes

One pipeline — **analyze → author (for the audience) → render** — works for every source.
What changes is *ingestion* (how you read the source) and *shape* (what learning structure
fits). Pick the closest recipe; fall back to the generic one. For shape/pedagogy details
see pedagogy.md; for DSL see dsl-syntax.md.

## Repo onboarding (one or many repos)

**Ingest:** read the README, entry points, package/module manifests, directory layout,
config, and the main runtime path. Trace one real request/flow end to end. Note the build,
test, and run commands. For multiple repos, map how they call each other.

**Shape:** mental model first ("this service does X by …") → architecture diagram
(`mermaid`) → the main flow walked through with real code → key modules and where to find
them → how to run/test locally → common gotchas (`:::callout warning`). End with a
`:::reveal` "where would you add feature Y?" to cement the model.

## PR / MR review

**Ingest:** `gh pr view <n> --json …` and `gh pr diff <n>` (or `git diff main...branch`).
Read the description, the diff, and the surrounding code the diff touches.

**Shape:** what this PR changes and why → a diagram of the before/after if structure moved
→ each significant change explained against its context → risks and edge cases
(`:::callout warning`) → what a reviewer should verify → alternatives considered. A
`:::quiz` on "why was this approach chosen over X?" works well.

## Plan / design review

**Ingest:** read the `plan.md` / `design.md` (and any linked specs). Identify the goal,
the proposed approach, the alternatives, and the open questions.

**Shape:** the problem and constraints → the proposed design (diagram) → why this over the
alternatives → risks, unknowns, and decision points → what success looks like. Use
`:::reveal` for "what would you push back on?" to make the review active.

## URL / blog post / book / article

**Ingest:** fetch the content (WebFetch) or use text the user pasted. Extract the thesis,
the key supporting arguments, and the evidence.

**Shape:** the central claim → the argument's structure (often a diagram clarifies it) →
the strongest supporting points with examples → where it's weak or contested → what to
take away. Checks should test whether the reader can *apply* or *critique* the idea.

## Lecture / talk / transcript

**Ingest:** the transcript or notes (pasted or fetched). Recover the through-line — talks
ramble; the walkthrough should not.

**Shape:** reorganize into a clean logical progression (not the talk's chronological order)
→ core concepts with definitions → examples the speaker used → synthesis. Add `:::reveal`
retrieval prompts where the talk made a key point.

## Generic fallback (anything else)

**Ingest:** read/fetch whatever the user points at; ask for the audience and the goal if
unclear.

**Shape:** identify the 3–7 things a reader must understand, order them prerequisites-first,
teach each with explanation + example + a check, and close with a synthesis question. When
in doubt, optimize for "can the reader now explain this to someone else?"

## Always

- Confirm the **audience** and **goal** before authoring (ask if not given).
- Author Markdown DSL, run `build-walkthrough.mjs`, then register the route in
  `walkthrough.config.json`.
- Keep each walkthrough to one coherent topic. Split large sources into multiple routes
  the hub links together.
