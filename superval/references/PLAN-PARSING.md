# Plan Parsing Reference

> How to extract features, phases, acceptance criteria, and file lists from superplan-format plans.

---

## Plan Document Locations

Plans created by `/superplan` are stored at:
- **Primary:** `docs/<feature>-plan.md`
- **Multi-file:** `docs/<feature>-plan-1.md`, `docs/<feature>-plan-2.md`, etc.

## Scanning for Plans

Search order:
1. User-provided path (if given as argument)
2. `docs/*-plan.md` or `docs/*-plan-*.md`
3. Root-level `*-plan.md`
4. `.autobuild/config.json` -> `plan_path` field

If no plan found: **ABORT** with message:
```
SUPERVAL ABORT: No plan found.

Searched:
  - docs/*-plan.md
  - docs/*-plan-*.md
  - .autobuild/config.json

To create a plan, run: /superplan
```

---

## Extracting the Phase Overview Table

The phase overview table is the master index of all features:

```markdown
### Phase Overview (with Poker Estimates)

| Phase | Name | Depends On | Parallel With | Estimate | Status |
|-------|------|------------|---------------|----------|--------|
| 0 | Bootstrap | - | - | 5 | ✅ |
| 1 | Core Services | 0 | - | 3 | ✅ |
| 2A | Backend API | 1 | 2B, 2C | 8 | ✅ |
```

### Parsing Algorithm

```
1. Find line matching: "| Phase | Name |"
2. Skip separator line (|-------|---...)
3. Read rows until next blank line or non-table line
4. For each row, extract:
   - phase_id: Column 1 (normalize: lowercase, strip spaces)
   - phase_name: Column 2
   - depends_on: Column 3 (split by comma)
   - parallel_with: Column 4 (split by comma)
   - estimate: Column 5 (integer)
   - status: Column 6 (icon: ⬜/✅/🔄/⏸️/⏭️)
```

### Phase Status Icons

| Icon | Meaning | Superval Action |
|---|---|---|
| `⬜` | Not started | Should have been built - verify |
| `🔄` | In progress | Partial - verify what exists |
| `✅` | Complete | Verify everything |
| `⏸️` | Blocked | Skip verification |
| `⏭️` | Skipped | Skip verification |

---

## Extracting Features per Phase

Each phase section has this structure:

```markdown
### Phase N: [Name]

> **Depends On**: Phase X
> **Status**: ⬜ Not Started

#### Objectives
- [ ] Objective 1
- [ ] Objective 2

#### Code Changes

##### File: `path/to/file.ts` (CREATE)
[code block]

##### File: `path/to/other.ts:45-67` (MODIFY)
[code block]

#### Tests (Write First)
##### File: `path/to/test.ts` (CREATE)
[code block]

#### Definition of Done (Quality Gate)
- [ ] Code passes linter
- [ ] All tests pass
```

### Extraction Points

**Objectives -> Feature checklist:**
```
Pattern: "- [ ] " or "- [x] " under "#### Objectives"
Extract: Text after checkbox
```

**Code Changes -> File list:**
```
Pattern: "##### File: `<path>` (CREATE|MODIFY|DELETE)"
Extract: path, operation type
```

**Tests -> Test file list:**
```
Pattern: "##### File: `<path>` (CREATE)" under "#### Tests"
Extract: path
```

**Definition of Done -> Quality gate checklist:**
```
Pattern: "- [ ] " under "#### Definition of Done"
Extract: Each quality gate requirement
```

---

## Extracting Acceptance Criteria

Found in the Requirements section:

```markdown
### Acceptance Criteria
- [ ] **AC-1**: User can check build status via CLI
- [ ] **AC-2**: Config loads from file and environment
- [x] **AC-3**: Errors are logged with stack traces
```

### Parsing

```
Pattern: "- [ ] **AC-\d+**: (.+)" or "- [x] **AC-\d+**: (.+)"
Extract: AC ID, description, checked status
```

Each AC becomes a behavioral test in the acceptance test suite.

---

## Extracting from .autobuild/ State Files

If the project was built with `/autobuild`, state files provide additional context:

### config.json
```json
{
  "plan_path": "docs/feature-plan.md",
  "stack": { "language": "typescript", "test_framework": "vitest" },
  "commands": { "lint": "npm run lint", "test": "npm test" },
  "phases": { "total": 6, "completed": 6 }
}
```

**Extract:** stack info, quality gate commands, completion status.

### phases/phase-{id}.json
```json
{
  "phase_id": "1",
  "status": "complete",
  "quality_gates": { "test": { "passed": true } },
  "commit": { "files_created": [...], "files_modified": [...] }
}
```

**Extract:** per-phase file lists, quality gate results, completion status.

---

## Extracting from Plan Updates (Superbuild)

If built with `/superbuild`, the plan document itself is the state:

- `- [x]` = task completed
- `✅` in status column = phase completed
- Quality gate checkboxes checked = gates passed

Superval should read these checkboxes to understand what was claimed complete, then independently verify.

---

## Building the Feature Map

Combine all extraction points into a unified feature map:

```
FeatureMap {
  plan_path: string
  phases: Phase[]
  acceptance_criteria: AC[]
  expected_files: FileExpectation[]
  quality_commands: QualityCommands
}

Phase {
  id: string
  name: string
  status: string
  objectives: string[]
  files_created: string[]
  files_modified: string[]
  test_files: string[]
  dod_items: string[]
}

AC {
  id: string
  description: string
  checked: boolean
}

FileExpectation {
  path: string
  operation: 'CREATE' | 'MODIFY' | 'DELETE'
  phase: string
  has_test: boolean
}
```

This feature map drives all three verification levels.
