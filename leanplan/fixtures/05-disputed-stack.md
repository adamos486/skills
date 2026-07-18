# Implementation Plan: Server-Side Search for the Docs Site

## Goal

Our docs site (`apps/web`, Next.js) has no search. Add a search box that queries our existing
Postgres full-text index and shows results. Internal docs, ~2,000 pages, ~30 readers.

## Work

1. Add a `SearchBox` client component with an input and a results dropdown.
2. On each keystroke, call a new `/api/search` route handler, which queries Postgres and
   returns JSON.
3. `SearchBox` holds results in `useState` and renders them.
4. Put `SearchBox` in the site header so it appears on every page. Because the header is a
   client component, wrap the whole page tree in a client boundary at the root layout.
5. Store the current query in a React context provider so other components can read it later.
6. Debounce keystrokes at 300ms.

## Acceptance

- Typing a term shows matching page titles within 300ms.
- Clicking a result navigates to that page.
