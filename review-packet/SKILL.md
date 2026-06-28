---
name: review-packet
description: Use when a design, spec, or brainstorm needs to leave this thread — to be reviewed by another agent, to feed adversarial-review, or to catch up / hand off the work to a brand-new thread or a different AI. Triggers: "review packet", "context dump", "second opinion", "paste into ChatGPT/Codex/Gemini", "hand this off", "catch up a new thread", "continue this in another agent", "I'm running out of context".
---

# Review Packet

## Overview

Package the current work into one **self-contained, routed** document that something *outside
this thread* can use: an external reviewer, the `adversarial-review` critic, or a brand-new
agent thread continuing the work. One file — a routing preamble, a shared context core, and a
continuation layer.

**Core principle:** a reader can only use what they can see. A reviewer can't critique reasoning
that isn't written down; **a fresh thread can't *resume* work whose status, file locations, and
next step aren't written down.** The packet carries both the reasoning *and* the state.

## When to Use

- Hand a design to an **external reviewer** (paste into ChatGPT/Codex/Gemini).
- **Feed `adversarial-review`** — its context core (§2–§7) becomes that skill's `requirements.md`;
  it injects its own plan-critic.
- **Catch up / hand off** the work to a new thread or a different agent (you're out of context;
  someone else continues).
- **Not for:** reviewing a code diff (use `/code-review`).

## Workflow

1. **Locate the design.** Newest `docs/superpowers/specs/*-design.md`; if there's no spec,
   reconstruct from this conversation.
2. **Mine the conversation for what the next reader cannot see** — both the reasoning and the state:
   - **original request, verbatim**; **background + invariants**; the **decision log** (chosen,
     why, *and what was considered + rejected/deferred, and why*); the **soft spots** (proactive);
   - **current status** — what's done / in-flight / pending / blocked; current rev; last decision;
   - **artifact & file map** — **absolute** paths to the spec, this packet, the skill/code, the branch;
   - **next actions & how to resume** — the immediate next step, what to read first, which
     skill/command to run, and the **working conventions** to honor (e.g. never commit; the
     brainstorm→writing-skills/writing-plans flow; project rules).
3. **Fill every REQUIRED slot** in `references/packet-template.md` (including §0 routing and §9–§11).
4. **Write** to `docs/superpowers/specs/YYYY-MM-DD-<topic>-review-packet.md`. **Do not commit.**
5. **Hand off.** Print the path and which sections each consumer reads (review / adversarial-review
   / catch-up). Offer to print inline.

## What Makes the Packet Work (the contract)

- **Self-contained** — inline everything; it works even for a reader with no repo access.
- **Routed** — the §0 preamble sends each of the three consumers to its sections, so the review
  wrapper never hijacks a catch-up or adversarial-review reader.
- **Expose the reasoning** — rejected/deferred alternatives *with their why*.
- **Surface soft spots honestly** — a dedicated "scrutinize these" section.
- **Continuation-complete** — a fresh thread can resume from it *alone*: current status, an
  absolute file map, and the immediate next action are all present and concrete.
- **Adversarial (for the review consumer)** — the wrapper tells an external reviewer to find
  problems; for `adversarial-review`, feed §2–§7 and let it inject its own critic.

## Common Mistakes (from baseline testing)

| Mistake | Fix |
|---|---|
| No current-status / next-action | A continuation thread does the *wrong thing* — baseline fresh threads "produced a review" instead of resuming. State status + the immediate next action |
| Relative paths or "see the spec" | A new thread/agent can't open them — use **absolute** paths in the file map |
| Review prompt with no routing preamble | Fed to `adversarial-review` it collides with that skill's own critic; a catch-up thread adopts the reviewer persona instead of continuing. Add §0 routing |
| Omitting working conventions | The new thread violates them (commits, skips the next skill). List no-commit + the next step |
| Rejected alternatives dropped | The reviewer can't attack reasoning they can't see — include considered/rejected + *why* |
| Echoing only the user's flagged doubts | Proactively surface the subtle risks nobody raised |
| Linking instead of inlining | Inline it; an external reader has no access |
| Committing the file | Leave it for the user to commit |

## Reference

- `references/packet-template.md` — the section skeleton with REQUIRED slots. Fill all of them.
