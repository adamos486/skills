# State Schemas

All user state lives under `~/.mealplan/`. Create the directory and any missing file lazily; a missing file means "empty", never an error.

## Files

### `profile.md`

Human-readable markdown file containing user preferences and constraints. Exact format defined in `references/onboarding.md`.

### `pantry.json`

JSON object tracking grocery inventory.

**Schema:**
```json
{
  "items": [
    {
      "name": "chicken breast",
      "qty": 2,
      "unit": "lb",
      "added": "2026-06-28"
    }
  ]
}
```

### `history.jsonl`

One JSON object per line, tracking completed weeks and meals.

**Schema (one line):**
```json
{
  "week": "2026-06-28",
  "meals": [
    {
      "id": "mon-dinner-chili",
      "title": "Turkey chili",
      "made": true,
      "notes": ""
    }
  ],
  "created": "2026-06-28"
}
```

### `ratings.json`

JSON object mapping recipe IDs to user ratings and feedback.

**Schema:**
```json
{
  "mon-dinner-chili": {
    "rating": "up",
    "notes": "great",
    "last": "2026-06-28"
  }
}
```

### `signals.jsonl`

One event per line, tracking user interactions and skill actions for analytics.

**Schema (one line):**
```json
{
  "ts": "2026-06-28",
  "type": "week_generated",
  "payload": {
    "week": "2026-06-28",
    "meal_count": 7,
    "verify_count": 4
  }
}
```

**Event types (MVP):**
- `week_generated`: meal plan created
- `meal_made`: user cooked a meal
- `meal_skipped`: user skipped a meal
- `rating_set`: user rated a recipe
- `catalog_miss`: user reports an item wasn't available in-store or was priced incorrectly (covers both availability misses and price errors)
- `html_opened`: user opened week.html (best-effort)

## Repair Rule

If a JSON/JSONL file fails to parse:
1. Report exactly which file and (for JSONL) which line
2. Show the bad content
3. Ask the user before overwriting — never silently discard
