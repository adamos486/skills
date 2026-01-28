# Streaming Recommendations Skill — Research Findings

## Why Web Search Is Essential

Streaming catalogs are constantly changing. Titles rotate on and off platforms monthly. Any recommendation system that relies solely on static knowledge will suggest unavailable content. The skill must always use live web search to verify current availability.

## Key Recommendation Sources

### Availability & Discovery
- **JustWatch** (justwatch.com) — The most comprehensive streaming availability database. Covers all major services, supports watchlists, and shows where titles are available across platforms.
- **FlixPatrol** (flixpatrol.com) — Tracks official TOP 10 trending lists from Netflix, Prime Video, Disney+, HBO Max, and others. Updated daily. Great for "what's popular right now" queries.

### Ratings & Reviews
- **IMDb** (imdb.com) — Most widely recognized rating system. User-submitted scores on a 1-10 scale. Best for general audience appeal.
- **Rotten Tomatoes** (rottentomatoes.com) — Dual rating system: Tomatometer (critics) and Audience Score. Useful for distinguishing critical acclaim from popular opinion.

### AI-Powered Recommendation Tools
- **Taste.io** — Matches users with like-minded reviewers for personalized picks.
- **MovieWiser** — AI-powered mood-based recommendation tool.
- **Taranify** — Netflix-specific mood-based recommendations.

## Major Streaming Services (as of January 2026)

| Service | Monthly Cost (ad-free) | Notes |
|---------|----------------------|-------|
| Netflix | $17.99 (Standard) | 300M+ subscribers, largest catalog |
| Disney+ / Hulu | $19.99 (bundle) | Merging into single app in 2026 |
| HBO Max | $18.49 | Reverted from "Max" branding July 2025 |
| Prime Video | $14.99 (with Prime) | Included with Amazon Prime |
| Apple TV+ | ~$10.99 | Prestige originals (Severance, Silo) |
| Peacock | $16.99 (Premium Plus) | NBC/Universal content |
| Paramount+ | $13.99 (with Showtime) | Price increased Jan 2026 |
| Tubi | Free | 275,000+ titles, ad-supported |

## Mood-Based Recommendations: What the Research Says

- **fMRI studies** show matching genre to emotional state intensifies engagement and satisfaction (PMC, 2024)
- Viewers who watch films aligned to their mood report higher enjoyment and emotional resonance
- Psychologists group emotions into 6 core moods: joy, sadness, anger, fear, surprise, disgust — each maps to genre preferences
- **Hybrid genres** (horror-comedy, romantic thriller) serve complex moods effectively

## Best Practices for Quality Recommendations

1. **Combine genre + mood filtering** — Genre alone is too broad; mood narrows to what actually fits the moment
2. **Mix popular and hidden gems** — Prevents echo chamber effect and creates discovery moments
3. **Verify availability** — Always confirm the title is currently on the stated platform
4. **Spoiler-free synopses** — Sell the vibe, not the plot
5. **Personal connection** — Explain WHY each pick matches what the user asked for
6. **Use multiple search queries** — Cross-reference 2-3 sources for accuracy
7. **Prefer well-rated content** — IMDb 7.0+ or RT 75%+ as a baseline

## Common Pitfalls to Avoid

- **Stale data** — Recommending titles that have left a platform
- **Genre-only matching** — A comedy can be dark or light; mood matters
- **Too many questions** — Users want recommendations, not an interrogation
- **Generic descriptions** — "A great show with interesting characters" says nothing
- **Spoilers in synopses** — Even mild plot reveals can ruin the experience
- **Ignoring availability** — The best recommendation is useless if the user can't watch it
