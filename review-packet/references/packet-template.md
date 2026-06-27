# Review Packet Template

Fill **every REQUIRED slot**. Inline all content — the reviewer has zero access to the repo
or the conversation. Delete the *italic guidance* as you write. Keep the section order.

---

## 1. Your task as reviewer  — REQUIRED

*Open with the adversarial prompt. State the role, the mandate to find problems (not
validate), the review dimensions, and the output format. Tune the role and dimensions to the
domain (security, distributed systems, UX, etc.).*

> You are a **skeptical senior/staff engineer and [domain] reviewer** doing a
> **pre-implementation design review**. The authors want **hard pushback**, not validation.
> Find what is **wrong, risky, missing, or over-built**.
>
> Review across these dimensions (and beyond): *[list 5–8 dimensions that fit this design —
> e.g. security, platform feasibility, cost/abuse, data model, correctness/edge cases,
> simplicity/YAGNI, operability, gaps]*.
>
> **Respond with:** a one-line verdict; then findings **ranked by severity**
> (Critical/High/Medium/Low/Nit), each with what's wrong, why it matters, and a concrete fix;
> then direct answers to the questions in §7. **Challenge our reasoning, not just our
> conclusions.** Be specific; wrong-but-specific beats vague.

## 2. Original request (verbatim) — REQUIRED

*Quote the user's original ask word-for-word. Do not paraphrase.*

## 3. Background the reviewer needs — REQUIRED

*Self-contained context on the system being changed. What it is, how it works, and its
**invariants/constraints** that the design must not break. Write for someone who has never
seen this codebase or product.*

## 4. The design — REQUIRED

*The full design/spec, inlined. Architecture, components, data flow/model, endpoints,
lifecycle — whatever applies. Never link to a spec file; paste it.*

## 5. Decision log — REQUIRED

*The heart of the packet. One row per significant fork. The rejected/deferred column is what
lets the reviewer attack the reasoning — never omit it.*

| Decision | Chosen — and why | Considered & rejected/deferred — and why |
|---|---|---|
| *e.g. Cloud provider* | *Cloudflare Workers — domain already there, no egress fees* | *AWS Lambda+S3 — rejected: egress cost, more parts* |

## 6. Areas to scrutinize (least confident) — REQUIRED

*The honest soft spots. Include both the doubts the user raised AND subtle risks you surface
proactively (the ones nobody mentioned). Number them so the reviewer can respond point by
point.*

## 7. Specific questions for the reviewer — REQUIRED

*The concrete questions you most want answered. Include "what's the most likely way this
fails in production?" and "what would you cut / what's missing?".*

## 8. Desired output — REQUIRED

*Restate the output shape you want back (verdict → severity-ranked findings → answers to §7
→ anything else). One or two lines.*
