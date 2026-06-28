# Review Packet Template

Fill **every REQUIRED slot**. Inline all content — the reader has zero access to the repo or the
conversation. Delete the *italic guidance* as you write. Keep the section order. §0 and §9–§11 are
REQUIRED even for a review-only packet (cheap for a reviewer, essential for catch-up).

---

## 0. How to use this packet (routing preamble) — REQUIRED

*The first thing in the file. Route each consumer to its sections so the review wrapper never
hijacks a catch-up or adversarial-review reader.*

> - **External review:** read §1, then §2–§7; produce the output in §8.
> - **Feeding `adversarial-review`:** use §2–§7 as its `requirements.md` context and let it inject
>   its own critic — **ignore §1 and §8**.
> - **Continuing this work in a new thread/agent:** read §9 (status), §3–§7 (design + reasoning),
>   §10 (where the files are), then do §11 (next actions). **You are resuming, not reviewing —
>   ignore §1/§8.**

## 1. Your task as reviewer — REQUIRED (external-review wrapper)

*The adversarial prompt: role, mandate to find problems (not validate), 5–8 review dimensions tuned
to the domain, and the output format. Used only by the external-review consumer.*

> You are a **skeptical senior/staff engineer and [domain] reviewer** doing a
> **pre-implementation design review**. The authors want **hard pushback**, not validation. Find
> what is **wrong, risky, missing, or over-built**.
>
> Review across these dimensions (and beyond): *[5–8 fit to this design]*.
>
> **Respond with:** a one-line verdict; then findings **ranked by severity**
> (Critical/High/Medium/Low/Nit), each with what's wrong, why it matters, and a concrete fix; then
> direct answers to §7. **Challenge our reasoning, not just our conclusions.** Be specific.

## 2. Original request (verbatim) — REQUIRED

*Quote the user's original ask word-for-word. Do not paraphrase.*

## 3. Background the reader needs — REQUIRED

*Self-contained context on the system being changed: what it is, how it works, and its
**invariants/constraints**. Write for someone who has never seen this codebase or product.*

## 4. The design — REQUIRED

*The full design/spec, inlined. Architecture, components, data flow/model, endpoints, lifecycle.
Never link to a spec file; paste it.*

## 5. Decision log — REQUIRED

*The heart of the packet. One row per significant fork. The rejected/deferred column is what lets a
reviewer attack the reasoning — never omit it.*

| Decision | Chosen — and why | Considered & rejected/deferred — and why |
|---|---|---|
| *e.g. Cloud provider* | *Cloudflare Workers — domain already there, no egress* | *AWS Lambda+S3 — rejected: egress, more parts* |

## 6. Areas to scrutinize (least confident) — REQUIRED

*The honest soft spots: the doubts the user raised AND subtle risks you surface proactively. Number
them so a reviewer can respond point by point. Mark each **resolved** or **still-open**, so a
continuation thread knows which risks remain to be addressed.*

## 7. Specific questions for the reviewer — REQUIRED

*The concrete questions you most want answered. Include "most likely way this fails in production?"
and "what would you cut / what's missing?".*

## 8. Desired output — REQUIRED (external-review wrapper)

*Restate the output shape you want back (verdict → severity-ranked findings → answers to §7). One
or two lines. Used only by the external-review consumer.*

## 9. Current status & state — REQUIRED (catch-up)

*Where the work stands **right now**: what's done, what's in progress, what's pending/blocked; the
current revision; and the most recent decision made. A continuation thread reads this first — be
concrete (a fresh thread that can't tell status from a review request will go review instead of
resume).*

## 10. Artifact & file map — REQUIRED (catch-up)

*Absolute paths so a thread that has the repo can navigate it: the spec/design doc, this packet,
the skill or code being changed, the working branch. (The core stays self-contained for readers
without the repo; this map is the bonus for those who have it.) No "see the spec" — give the path.*

## 11. Next actions & how to resume — REQUIRED (catch-up)

*The immediate next step(s), what to read first, which skill/command to run to continue, and the
**working conventions** the new thread must honor (e.g. never commit; the
brainstorm→writing-skills/writing-plans flow; project rules). Concrete enough that a fresh agent
does the right thing without guessing.*
