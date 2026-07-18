# Onboarding: First-Run Questionnaire

Welcome to mealplan. Let's build your personalized meal plan by answering a few questions — one at a time, conversationally.

## The Questionnaire

**1. Dietary constraints**

Ask: "What are your main dietary constraints or preferences? (e.g., low carb, lean protein, green vegetables, no gluten, vegan, etc.)"

Record: Free-form text describing any hard dietary rules (e.g., "low carb, emphasis on lean protein and green vegetables, low salt").

**2. Allergies / hard dislikes**

Ask: "Any food allergies or things you absolutely won't eat?"

Record: Free-form text (e.g., "shellfish, tree nuts, spicy food" or "(none given)").

**3. Location**

Ask: "What's your location? (city or zip code — we'll use this to find nearby grocery chains)"

Record: City and state or zip code (e.g., "Austin, TX 78704").

**4. Favorite grocery chains**

Ask: "Which grocery chains do you prefer, in order? (optional — if you skip, we'll infer common chains for your location)"

Record: Ordered list of chain names (e.g., "H-E-B, Whole Foods"). Mark inferred chains as `verify`.

**5. Cooking tastes / cuisines**

Ask: "How do you like to cook? Any favorite cuisines? (e.g., meal prep on Sundays, Mexican, Chinese, Italian, quick weeknight meals, etc.)"

Record: Free-form description of cooking style and preferred cuisines.

**6. Household size / servings**

Ask: "How many servings per meal? (e.g., 2 for a couple, 4 for a family of four)"

Record: Number of servings and/or household composition (e.g., "servings per meal: 2").

**7. Effort per week**

Ask: "How much time do you want to spend cooking each week? (e.g., batch-cook Sunday, light cooking weeknights; fresh daily; mostly takeout)"

Record: Description of preferred cooking effort (e.g., "batch-cook Sunday, light cooking weeknights").

---

## Profile Template

After collecting answers, write `~/.mealplan/profile.md` with this structure:

```markdown
# mealplan profile

## Dietary constraints
- low carb
- emphasis on lean protein and green vegetables
- low salt

## Allergies / hard dislikes
- (none given)

## Location
- Austin, TX 78704

## Grocery chains (preference order)
1. H-E-B
2. Whole Foods

## Cooking tastes
- meal prep on Sundays
- Mexican, Chinese

## Household
- servings per meal: 2

## Effort
- batch-cook Sunday, light cooking weeknights

## Notes
- (free text)
```

---

## After Writing the Profile

1. Create `~/.mealplan/pantry.json` with seed content: `{"items":[]}`
2. Offer to run the first weekly meal plan.
