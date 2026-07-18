# Generation

## Recipe selection

The recipe selection procedure ingests the refreshed pantry, ratings, and profile (from the Check-in step) and produces a weekly meal set. Each meal is a stable object with `{id, title, day, slot, servings, ingredients:[{name, qty, unit}], instructions, optional video_query}`.

### Selection rules

Follow this ordered procedure:

1. **Hard filter: dietary constraints and allergies**
   - Treat every dietary constraint and allergy/dislike listed in the profile as a hard filter — never propose a meal that violates one.
   - On any conflict between a hard filter and a cooking-taste preference, the constraint wins. State the trade-off briefly to the user (e.g., "skipping the Greek pasta because of the dairy allergy, but trying [alternative]").

2. **Choose tasty, varied meals**
   - Within the allowed set (after hard filters), select meals that match the cooking tastes and effort level stated in the profile.
   - For example, if Effort is "batch-cook," favor meal-prep-friendly recipes that yield multiple servings or have easy freezer-friendly components.

3. **Prefer pantry items**
   - Bias selection toward recipes that consume items already in `pantry.json`.
   - This reduces waste and shopping cost.

4. **Avoid repeats**
   - Exclude any meal whose `id` appears in recent `history.jsonl` weeks (last 2–4 weeks, depending on household size).
   - Also exclude any meal rated `down` in `ratings.json`.
   - Favor meal styles rated `up` in `ratings.json`.

5. **Reuse ingredients across the week**
   - Choose meals that share key ingredients to reduce shopping list complexity and cost.
   - For example, if one meal uses half a head of cabbage, plan a second meal that uses the remaining half the same week.

6. **Decide the number of meals**
   - Extract the household size and eating pattern from the profile's household details (e.g., "family of 4, weekday breakfasts included").
   - Extract effort/frequency from the profile's effort notes if specified (e.g., "batch-cook" = prefer meals with multiple components; "quick weeknight" = prefer 20-min meals).
   - Default: plan dinners for 7 days (one per night). If the profile requests a different pattern (e.g., 5 weekday lunches), adjust accordingly.
   - Ask the user if the meal count is ambiguous.

7. **Produce the full meal object**
   - For each selected meal, construct:
     ```
     {
       "id": "<day>-<slot>-<2-3-word-title-slug>",
       "title": "Human-readable meal name",
       "day": "mon" | "tue" | "wed" | "thu" | "fri" | "sat" | "sun",
       "slot": "breakfast" | "lunch" | "dinner",
       "servings": <number>,
       "ingredients": [
         {"name": "ingredient", "qty": 2, "unit": "cups"},
         ...
       ],
       "instructions": [
         "Step 1: ...",
         "Step 2: ...",
         "..."
       ],
       "video_query": "Optional YouTube search string, e.g., 'sheet pan chicken fajitas recipe'"
     }
     ```
   - Keep `instructions` to 5–10 steps; each step is a concise, actionable string.
   - `video_query` is optional. Include it only if a visual guide would genuinely help (e.g., unfamiliar technique or complex plating). The skill may render it as a link; videos are not required for every meal.

### Stable meal ID slug rule

The `id` field is a **stable identifier** reused across `history.jsonl`, `ratings.json`, and `week.html`. It must follow this format:

```
id = "<day>-<slot>-<2-3-word-title-slug>"
```

- `<day>`: three-letter lowercase day name (e.g., `mon`, `tue`, `wed`, ..., `sun`)
- `<slot>`: meal slot, lowercase (e.g., `breakfast`, `lunch`, `dinner`, or `snack`)
- `<2-3-word-title-slug>`: a kebab-case summary of the meal (lowercase, hyphens, e.g., `turkey-chili`, `pad-thai`, `roast-salmon`)

**Examples:**
- `mon-dinner-turkey-chili`
- `wed-lunch-caesar-wrap`
- `fri-breakfast-scrambled-eggs`

This `id` is the join key: the same meal (same ingredients, same instructions) will have the same `id` across weeks if it reappears. Use it to look up past ratings and decide whether to repeat.

## Catalog cross-reference

The catalog cross-reference procedure builds the final shopping list. Follow these steps:

1. **Consolidate ingredient quantities** — across all selected meals, sum quantities for each ingredient (treating same-name ingredients as a single line-item).

2. **Subtract pantry** — check `pantry.json` against the consolidated list. Remove any pantry item from the shopping list, matching by name (case-insensitive, singular/plural tolerant). If the pantry has a partial quantity (e.g., "flour: 2 cups" and the recipe needs 5 cups), reduce the required qty and re-list with the remaining amount.

3. **Cross-reference the user's top-preference chain** — from the user's profile (grocery chains/location data), identify the preferred store. For each remaining ingredient, build a shopping model entry:
   ```
   {
     "name": "<ingredient name>",
     "qty": <quantity>,
     "unit": "<unit>",
     "section": "<aisle/department>",
     "product": "<likely product name/brand>",
     "est_price": <estimated price>,
     "confidence": "known|estimated|verify"
   }
   ```
   - `confidence: known` — the chain reliably carries this item as a staple. Use sparingly; only for genuine, universally stocked basics (e.g., eggs, milk, salt).
   - `confidence: estimated` — the chain likely carries it; product name, section, and price are educated guesses. **Default most items here**; do not over-claim `known`.
   - `confidence: verify` — you are uncertain whether the chain stocks it, the price is volatile or unusually high, or a specialty/imported item is needed. For chain-only items marked `verify`, suggest a substitute. For items the chain is unlikely to carry, recommend an online alternative (e.g., Amazon, Thrive).

4. **Opportunistic web search** — for up to ~5 items marked `verify` or with high estimated cost (e.g., > $15), perform an opportunistic quick web search against the user's top-preference chain to check current availability and price. On success, upgrade the `confidence` to `estimated` or `known` with the found price and aisle. On failure or if a search tool is unavailable, leave the item as `verify` and note in the output that confirmation is needed in-store. Never block shopping list generation on a failed lookup.

5. **Group by section in aisle order** — sort the final shopping list by `section` using a standard grocery store aisle sequence:
   - produce
   - meat/seafood
   - dairy
   - frozen
   - pantry/dry
   - bakery
   - other

## Snacks

Generate a snack menu following the same hard constraints and preferences (dietary, allergy, ratings) as the main meal selection. Produce snack meals using the stable `id` format: `snack-<2-3-word-title-slug>`. Then build a snack shopping model:
- For each snack ingredient, use the same `{name, qty, unit, section, product, est_price, confidence}` shopping model.
- Add a `source` field to snack items: `source: local` if the item is carried by the user's top-preference chain, or `source: online` if it is a specialty/imported item best purchased from an online retailer (e.g., Amazon, Thrive).
- Apply the same `confidence` labels and opportunistic web-search logic as the main shopping list.

## week.html

The skill copies `references/week-html-template.html` to `~/.mealplan/weeks/<week>/week.html` and replaces the contents of the `<script id="weekdata">` island with the real week's JSON. Nothing else in the file changes.

### Data-island contract

The `<script id="weekdata" type="application/json">` block must contain a single JSON object with exactly these top-level fields:

| Field | Type | Description |
|---|---|---|
| `week` | string | Week identifier (e.g. `"2026-06-28"`). Used as the `localStorage` namespace prefix `mealplan:<week>:<itemId>`. |
| `chain` | string | User's preferred grocery chain, shown in the header subtitle. |
| `menu` | array | Meal objects. Each must have a unique `id` (stable meal slug). |
| `shopping` | array | Shopping list items. Each must have a unique `id`. |
| `snackMenu` | array | Snack descriptions. Each must have a unique `id`. |
| `snackShopping` | array | Snack shopping items. Each must have a unique `id`. |

Every item across all arrays must carry a unique `id` field — this is the `localStorage` key suffix for check-off persistence. The template's example JSON shows the expected shape for each array element; the skill must produce objects with those same field names.

Check-off state persists in `localStorage` keyed by `mealplan:<week>:<itemId>`. Replacing the data island (e.g. for a new week) automatically isolates state because the `week` prefix changes.

**Mapping note:** When building the week.html data island, each menu item uses `day`, `slot`, `servings`, `title`, `video_query`, `instructions` (array of step strings), and `ingredients` as an array of DISPLAY STRINGS (render each `{name,qty,unit}` ingredient to a string like `"1 lb chicken breast"`). The structured `ingredients:[{name,qty,unit}]` form remains the canonical meal-object representation used by the shopping step; only the html island uses the stringified form.

## Honesty

**Stated limitation:** quantitative constraints such as "low salt" or "low carb" are interpreted by model judgment, not numerically measured — verify exact nutrition values independently if medically required.

**Guardrail:** the agent must not fabricate confident prices or falsely claim a store stocks something.
- When knowledge is thin or uncertain, prefer `confidence: verify` and recommend the user confirm availability in-store or online.
- When an item is genuinely unavailable or mispriced, the agent will never repeat the same false claim. **Log a `catalog_miss` signal** whenever the user reports an item wasn't available or was priced incorrectly — use this signal to update future estimates and build institutional memory of store-specific gaps.
- Ingredient substitution and online fallbacks are acceptable; fabrication is not.
