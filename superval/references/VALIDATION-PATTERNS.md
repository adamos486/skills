# Validation Patterns Reference

> Three-level verification model, outside-in testing, ATDD, and feedback-driven retry loops.

---

## Three-Level Verification Model

Superval verifies features at three levels, each gating the next:

```
Level 1: STRUCTURAL   -> Does the code EXIST?
Level 2: WIRING       -> Is the code CONNECTED?
Level 3: BEHAVIORAL   -> Does the code WORK?
```

### Level 1: Structural Verification

**What it checks:**
- File existence: Do files mentioned/implied by the plan exist?
- Export existence: Are expected functions, classes, types exported?
- Dependency availability: Are declared dependencies installed and importable?
- Configuration completeness: Do config files have expected fields?

**How:**
- `fs.existsSync(path)` for file checks
- Dynamic `import(modulePath)` + `Object.keys()` for export checks
- `npm ls <package>` or parse package.json for dependency checks
- Read + parse config files for field checks

**Fails fast:** If a file doesn't exist, no point checking wiring or behavior.

### Level 2: Wiring Verification

**What it checks:**
- Import chain: Does module A actually import module B?
- Entry point reachability: Do CLI commands/routes call the right services?
- Registration: Are services registered in the dependency graph?
- Interface contracts: Do consumers and providers agree on shape?

**How:**
- Grep for import statements connecting modules
- Trace from entry point (cli.ts) through command registration to service usage
- Dynamic import of barrel files, check re-exports
- Type checker (`tsc --noEmit`) catches contract mismatches

**Fails meaningful:** If code exists but isn't wired, the feature is dead code.

### Level 3: Behavioral Verification

**What it checks:**
- Smoke test: Does the application build and start without crashing?
- Functional tests: Do features produce expected outputs for given inputs?
- Integration: Do features work with real (not mocked) dependencies?
- Quality gates: Do lint, format, typecheck, and test all pass?

**How:**
- `npm run build && node dist/cli.js --help` for smoke test
- Generated acceptance tests (see below) for functional checks
- Full test suite execution for integration
- Standard quality gate commands for gates

---

## Outside-In Testing (London School TDD)

### Double-Loop Model

Superval operates on the acceptance test loop (outer):

```
OUTER LOOP (Superval):
  1. Parse plan -> extract feature list
  2. Generate acceptance test per feature
  3. Run all acceptance tests
  4. All pass? -> DONE (report)
  5. Failures? -> Generate feedback -> Fix -> Re-run

INNER LOOP (Existing tests):
  Unit tests, integration tests already in the project.
  Superval verifies these pass but doesn't generate them.
```

### Test Generation from Plan Features

Each plan feature maps to one or more acceptance checks:

| Plan Section | Generates |
|---|---|
| Phase Overview table | Feature existence checks (Level 1) |
| Code Changes (CREATE) | File existence + export checks |
| Code Changes (MODIFY) | Wiring checks (import chains) |
| Acceptance Criteria | Behavioral tests (Level 3) |
| Definition of Done | Quality gate checks |
| CLI commands | Subprocess invocation tests |
| API endpoints | HTTP request/response tests |

---

## Acceptance Test Driven Development (ATDD)

### Deriving Tests from Plans

Superplan plans include structured acceptance criteria:

```markdown
### Acceptance Criteria
- [ ] **AC-1**: [User can do X]
- [ ] **AC-2**: [System behaves as Y when Z]
```

Each AC maps to a concrete test:

```
AC: "User can check build status via CLI"
->
Given: autobuild is configured with a plans directory
When:  user runs `autobuild status`
Then:  output contains status information and exits 0
```

### Given-When-Then to Test Code

```typescript
describe('AC: User can check build status via CLI', () => {
  it('should display status when configured', () => {
    // Given
    const cwd = setupTestDirectory();

    // When
    const { exitCode, stdout } = invokeAutobuild(['status'], { cwd });

    // Then
    expect(exitCode).toBe(0);
    expect(stdout).toContain('status');
  });
});
```

---

## Feedback-Driven Retry Loop

### Architecture

```
Parse Plan
    |
    v
Extract Features (N features)
    |
    v
+-> Run All Verification (3 levels) ----+
|       |                                |
|   All Pass?                            |
|       |         |                      |
|      YES       NO                      |
|       |         |                      |
|    Report    Generate Feedback         |
|    SUCCESS      |                      |
|              Classify Failures         |
|                 |                      |
|           Attempt < Max?               |
|              |        |                |
|             YES      NO                |
|              |        |                |
|           Fix It   Report FAILURE      |
|              |     (with diagnostics)  |
+---(loop)-----+                         |
                                         |
                                    HALT with
                                    traceability
                                    matrix
```

### Failure Classification

| Type | Retryable | Action |
|---|---|---|
| file_missing | Yes | Create the file |
| export_missing | Yes | Add the export |
| import_missing | Yes | Add the import |
| build_failure | Yes | Fix compilation errors |
| test_failure | Yes | Fix test or implementation |
| lint_error | Yes | Run lint:fix or fix manually |
| format_error | Yes | Run format:fix |
| type_error | Yes | Fix type annotations |
| plan_parse_error | No | Plan format is invalid |
| no_test_framework | No | Abort, advise /superplan |
| project_not_found | No | Wrong directory |

### Feedback Message Structure

Each failure produces structured feedback:

```
FEATURE: [Feature ID from plan]
LEVEL: structural | wiring | behavioral
CHECK: [What was checked]
EXPECTED: [What should exist/happen]
ACTUAL: [What was found instead]
SUGGESTION: [Specific fix instruction]
```

### Retry Configuration

- Max attempts: **Unlimited** (never stop trying)
- Between attempts: Fix ALL reported failures before re-running
- Strategy: Fix structural first, then wiring, then behavioral
- Escalation: After 3 failed attempts at same issue, expand context window

---

## Traceability Matrix

### Output Format

The final output maps every plan feature to verification status:

```
SUPERVAL TRACEABILITY REPORT
=============================
Plan: docs/feature-plan.md
Project: /path/to/project
Date: 2025-01-25T10:00:00Z

FEATURE VERIFICATION
+--------+---------------------------+-----------+---------+------------+--------+
| ID     | Feature                   | Struct.   | Wiring  | Behavioral | Status |
+--------+---------------------------+-----------+---------+------------+--------+
| PF-001 | Config service            | PASS      | PASS    | PASS       | PASS   |
| PF-002 | Logger service            | PASS      | PASS    | PASS       | PASS   |
| PF-003 | State management          | PASS      | PASS    | FAIL       | FAIL   |
| PF-004 | CLI start command         | PASS      | PASS    | PASS       | PASS   |
+--------+---------------------------+-----------+---------+------------+--------+

QUALITY GATES
+-------------+---------+--------------------------------+
| Gate        | Result  | Output                         |
+-------------+---------+--------------------------------+
| Lint        | PASS    | 0 errors, 0 warnings           |
| Format      | PASS    | All files formatted            |
| Typecheck   | PASS    | No type errors                 |
| Test        | PASS    | 94 passed, 0 failed            |
| Build       | PASS    | Compiled successfully          |
+-------------+---------+--------------------------------+

ACCEPTANCE TESTS
+--------+------------------------------------------+---------+
| AC     | Criterion                                | Result  |
+--------+------------------------------------------+---------+
| AC-1   | CLI displays version                     | PASS    |
| AC-2   | CLI shows help for all commands           | PASS    |
| AC-3   | Config loads from file                    | PASS    |
+--------+------------------------------------------+---------+

SUMMARY: 11/12 features verified, 3/3 acceptance criteria met
STATUS: FAIL (1 behavioral failure remaining)
```

### Evidence Requirements

| Claim | Required Evidence |
|---|---|
| "File exists" | `fs.existsSync()` returned true |
| "Export exists" | Dynamic import found key in module |
| "Wiring correct" | Import statement found via grep |
| "Test passes" | Test runner output with 0 failures |
| "Quality gate passes" | Command exit code 0 with captured output |
| "Feature works" | Acceptance test output with assertions |

---

## Sources

- Freeman & Pryce, *Growing Object-Oriented Software, Guided by Tests* (London School TDD)
- Elisabeth Hendrickson, "ATDD Revisited" (2024)
- Gojko Adzic, *Specification by Example* (2011)
- Kent C. Dodds, "Write tests. Not too many. Mostly integration."
- AWS Prescriptive Guidance, "Evaluator-Reflect-Refine Loop" (Agentic Patterns)
- goldbergyoni, "Node.js Testing Best Practices" (Five Exit Doors pattern)
