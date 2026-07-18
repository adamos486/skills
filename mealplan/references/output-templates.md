# Output templates

Markdown templates for the four weekly output files. Produced by the Emit-outputs step and written to `~/.mealplan/weeks/<week>/`.

## menu.md

```markdown
# Weekly Menu — {{week}}

## {{day}} — {{slot}}: {{title}}  ({{servings}} servings)
**Ingredients:** {{comma-separated}}
**Instructions:**
1. {{step}}
2. {{step}}
{{#video}}**Video:** [{{video_query}}](https://www.youtube.com/results?search_query={{video_query_urlencoded}}){{/video}}
```

## shopping-list.md

```markdown
# Shopping List — {{week}} — {{chain}}

> Confidence: **known** = reliably carried · **estimated** = likely · **verify** = confirm in store

## {{section}}
- [ ] {{product}} — {{qty}} {{unit}} · ~${{est_price}} · _{{confidence}}_
```

## snack-menu.md

```markdown
# Snack Menu — {{week}}
- {{snack}} — {{one-line note}}
```

## snack-list.md

```markdown
# Snack Shopping List — {{week}}

## Local — {{chain}}
- [ ] {{product}} — ~${{est_price}} · _{{confidence}}_

## Online
- [ ] {{product}} — {{source}}
```
