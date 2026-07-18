---
name: mealplan
description: Use when the user wants a weekly meal plan built from dietary constraints, location, and favorite grocery chains — generates a weekly menu, grocery shopping list, snack menu, snack shopping list, and a self-contained week.html phone companion, with persistent tracking of pantry, history, and ratings across weeks.
---

# mealplan

Turn dietary constraints + location + favorite grocery chains + cooking tastes into a
complete weekly eating plan, and track results over time to improve.

## State location

All user state lives in `~/.mealplan/` (NOT in the repo). See
`references/state-schemas.md` for exact file shapes and read/write/repair rules.

## Run-mode detection (do this first, every time)

1. If `~/.mealplan/profile.md` does NOT exist → **First run**: read and follow `references/onboarding.md`, write `~/.mealplan/profile.md`, seed `~/.mealplan/pantry.json` as `{"items":[]}`, then offer a weekly run.
2. Else if the user asks to change constraints/location/chains/tastes → **Edit run**:
   amend `~/.mealplan/profile.md`, confirm, stop (no generation unless asked).
3. Else → **Weekly run**: follow "Weekly run" below.

## Weekly run

### 1. Check-in

**Inputs:** `profile.md`, `pantry.json`, last line of `history.jsonl`, `ratings.json`

**Outputs:** updated in-memory understanding (refreshed pantry, applied ratings), plus appended `meal_made` / `meal_skipped` / `rating_set` signals to `signals.jsonl`.

#### a) Load state

1. Load `profile.md` (user's constraints, location, chains, tastes).
2. Load `pantry.json` (current inventory).
3. Load the **last line** of `history.jsonl` (last week's meals); if file is empty or does not exist, skip reconciliation.
4. Load `ratings.json` (past meal ratings).

#### b) Reconcile last week (if it exists)

Do NOT ask an open "what did you eat?" — **pre-fill last week's planned meals** and ask the user to mark each:

- For each meal: "Did you make **[meal title]**?" (✓ / ✗)
  - If **✓ made it**: ask a 1-tap rating (👍 up / 👎 down, optional note). Write to `ratings.json` (new entry or update if exists). Append `{"ts": "<date>", "type": "rating_set", "payload": {"id": "<meal-id>", "rating": "up|down", "notes": "..."}}` to `signals.jsonl`. Also append `{"ts": "<date>", "type": "meal_made", "payload": {"id": "<meal-id>", "week": "<week>"}}` to `signals.jsonl`.
  - If **✗ skipped**: the planned ingredients are assumed still on hand → add/return them to `pantry.json` (merge into existing items or append). Append `{"ts": "<date>", "type": "meal_skipped", "payload": {"id": "<meal-id>", "week": "<week>"}}` to `signals.jsonl`.

> **Note:** The `week` field in `meal_made` and `meal_skipped` signals refers to the prior (reconciled) week — the one being looked back on during check-in, not the new week being planned.

#### c) Elicit weekly deltas

Ask the user two quick questions (three when a last week exists):

1. **Constraints/location/chain changes?** "Any changes to your dietary constraints, location, or preferred grocery chains?" If yes → treat as an Edit run (update `profile.md`), confirm, and stop (proceed to generation on user request).
2. **Pantry additions?** "Anything to add to your pantry now (groceries already bought)?" If yes → update `pantry.json` with new items.
3. **Shopping list accuracy** *(ask only when a last week exists)*: "For last week's shopping list, did the store have everything, and were the prices about right? For any item that was missing or mispriced, log a `catalog_miss` signal (see `references/state-schemas.md`)."

#### d) First-run case

If no last week exists (first weekly run):
- Confirm `profile.md` is set.
- Ask: "What do you have in your pantry right now?" → populate `pantry.json` with current items.
- Proceed to generation.

### 2. Select recipes — follow `references/generation.md` (Recipe selection)

Select 7 days of dinners (or adjust per household pattern) using the recipe-selection procedure. Each meal must satisfy hard constraints (dietary, allergies), match tastes and effort, prefer pantry items, and avoid recent repeats (check `history.jsonl` and `ratings.json`). Output a weekly meal set: a list of meal objects, each with stable `id` (kebab-slug format), ingredients, instructions, and optional video guide.

### 3. Build the shopping list

Follow `references/generation.md` (Catalog cross-reference). This consolidates ingredients across the selected meals, subtracts pantry items, maps each remaining ingredient to the user's top-preference chain with a `known`/`estimated`/`verify` confidence label, does opportunistic web checks on ~5 verify/expensive items, and groups by store section. Produces the shopping model.

### 4. Generate snacks

Follow `references/generation.md` (Snacks): a snack menu under the same hard constraints, plus a snack shopping list split into local/online. Produces the snack model.

### 5. Emit outputs

**Inputs:** the selected meal set, the shopping model, and the snack model.

**Outputs:** four markdown files written to `~/.mealplan/weeks/<week>/`, plus `week.html` (see `references/week-html-template.html`), plus appended signals and history.

**Constraint self-check (before writing any output):** re-scan every meal's AND every snack's full ingredient list against the profile's dietary constraints and allergy/hard-dislike list. If any item violates a constraint or allergy, replace that meal/snack before emitting. Never emit a plan that contains a flagged allergen.

1. Compute `week = today's date (YYYY-MM-DD format)`.
2. Create directory `~/.mealplan/weeks/<week>/` if it does not exist.
3. Render and write the four markdown files from `references/output-templates.md`:
   - `menu.md` — write this disclaimer at the top of the file and state it to the user: "This plan is model-generated; if you have medical or allergy-critical dietary needs, verify each ingredient yourself." Then list all planned meals with ingredients, instructions, optional video links.
   - `shopping-list.md` — grouped by grocery chain and section, with confidence labels (`known`/`estimated`/`verify`).
   - `snack-menu.md` — snack list with one-line notes.
   - `snack-list.md` — snack shopping split into local (by chain) and online sources.
4. Generate `week.html` (see `references/week-html-template.html` — a self-contained phone companion).
5. Append a `week_generated` signal to `signals.jsonl`: `{"ts": "<date>", "type": "week_generated", "payload": {"week": "<week>", "meal_count": <meal count>, "verify_count": <number of items with confidence='verify'>}}`.
6. Append ONE line per week to `history.jsonl` (matching the shape in `references/state-schemas.md`): a single JSON object `{"week": "<week>", "meals": [ {"id": "<meal-id>", "title": "<title>", "made": false, "notes": ""}, ... one entry per planned meal ], "created": "<date>"}`. At planning time every meal is recorded with `made: false` and empty `notes`; the actual made/skipped outcome is captured by the `meal_made` / `meal_skipped` signals during the next check-in (history lines are not rewritten).

---

## Error handling

- **No `profile.md`** → run onboarding (do not error); see `references/onboarding.md`.
- **Missing or empty state file** (`pantry.json`, `history.jsonl`, `ratings.json`, `signals.jsonl`) → treat as empty; create on first write.
- **Web lookup fails or store is unavailable** → fall back to `confidence: estimated` / `verify`; never block generation.
- **Chain or store unknown to the model** → label those items `verify`, state the uncertainty explicitly, and suggest the user confirm in-store.
- **Corrupt or unparseable state file** → report the file (and JSONL line number) plus the bad content; ask the user before overwriting. Follow the repair rule in `references/state-schemas.md`.
- **Constraint vs. preference conflict** → the dietary constraint wins; note the trade-off briefly to the user.

## Writing state safely

When writing any `~/.mealplan/` JSON or JSONL file:
- Write the **complete record** with every field the schema requires. Key examples: `ratings.json` entries must include `last` (the rating date); `pantry.json` items must include `{name, qty, unit, added}`. See `references/state-schemas.md` for all shapes.
- **Validate** that the written JSON parses before considering the write done.
- For `.jsonl` files, always **append** a new line — never rewrite or truncate the file.

## Signals

Append to `~/.mealplan/signals.jsonl` at these exact moments:

| Event | When to fire |
|---|---|
| `week_generated` | End of "Emit outputs" — once per weekly run |
| `meal_made` | Check-in, when the user marks a meal as made |
| `meal_skipped` | Check-in, when the user marks a meal as skipped |
| `rating_set` | Check-in, when the user provides a thumbs-up/down rating |
| `catalog_miss` | When the user reports an item wasn't available in-store **or** was priced incorrectly — covers both availability misses and price errors |
| `html_opened` | Best-effort / optional — a `file://` open cannot be reliably detected from the agent in MVP, so this event may stay unused |

These signals are the roadmap gates (M1–M4). In the MVP they are written but not analyzed; future milestones will read them to improve recipe selection, catalog accuracy, and pricing estimates.

> **Known M0 limitation:** A "list churn" signal (detecting manual strikes or additions to the shopping list) is not auto-captured in the file-based MVP — there is no way to observe post-write edits to the written files. This remains a known gap for a future milestone.
