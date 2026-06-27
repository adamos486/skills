---
name: review-packet
description: Use when a design, spec, or brainstorm is ready for outside review and you'll hand it to another agent — after a brainstorming design is approved, or when the user asks for a "review packet", "context dump", a "second opinion from another AI", or something to "paste into ChatGPT / Codex / Gemini" to critique a design.
---

# Review Packet

## Overview

Package a finished design into one **self-contained, adversarial** document that a
*different* agent can review with **zero access** to your repo or this conversation.

**Core principle:** a reviewer can only challenge what they can see. Conclusions alone get
rubber-stamped; the *reasoning* — including the alternatives you rejected and the parts
you're unsure about — is what needs review, so it must be on the page.

## When to Use

- After a brainstorming/design is approved, before implementation.
- The user asks to "get this reviewed", "second opinion", "context dump", "send to another
  AI", "paste into ChatGPT/Codex/Gemini".
- **Not for:** reviewing a code diff (use `/code-review`) or stress-testing a step-by-step
  *plan* with a local CLI critic (use `adversarial-review`). This skill packages a *design*
  for an external agent to read.

## Workflow

1. **Locate the design.** Newest `docs/superpowers/specs/*-design.md`; if there's no spec
   (e.g. skill work that skipped it), reconstruct the design from this conversation.
2. **Mine the conversation for what the reviewer cannot see:**
   - the **original request, verbatim**;
   - **background + invariants** of the system being changed, written for someone who has
     never seen it;
   - the **decision log** — every significant fork: what was chosen, why, **and what was
     considered and rejected/deferred, and why**;
   - the **soft spots** — proactively surface low-confidence areas and subtle risks, not
     just the doubts the user named out loud.
3. **Fill every REQUIRED slot** in `references/packet-template.md`.
4. **Write** to `docs/superpowers/specs/YYYY-MM-DD-<topic>-review-packet.md`. **Do not
   commit** — it's the user's to commit.
5. **Hand off.** Print the path and: "paste this whole file into your external reviewer."
   Offer to print it inline.

## What Makes the Packet Work (the contract)

- **Self-contained** — assume zero repo/thread access. Inline everything; never link to the
  spec or to files.
- **Expose the reasoning** — include rejected/deferred alternatives *with their why*, so the
  logic itself can be attacked, not just the conclusion.
- **Surface soft spots honestly** — a dedicated "scrutinize these" section; include risks
  even if you believe you handled them.
- **Adversarial** — instruct the reviewer to find problems and challenge the reasoning, not
  validate; ask for severity-ranked findings.
- **Convergent** — always the template's structure, so packets are complete and comparable.

## Common Mistakes (from baseline testing)

| Mistake | Fix |
|---|---|
| Only the final decisions; rejected alternatives dropped | The reviewer can't attack reasoning they can't see — include the considered/rejected options + *why* |
| Echoing only the user's flagged doubts | Proactively surface the subtle risks nobody raised, too |
| One-line description of the existing system | Inline its invariants/constraints — the reviewer has never seen it |
| Linking to the spec or repo | Inline it; the reviewer has no access |
| Improvising structure each time | Use the template — identical inputs otherwise diverge into incompatible shapes |
| Committing the file | Leave it for the user to commit |

## Reference

- `references/packet-template.md` — the section skeleton with REQUIRED slots. Fill all of them.
