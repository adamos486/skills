# State File Contracts Reference

> Contracts for reading state from superbuild plan updates and autobuild .autobuild/ directory.

---

## Superbuild State (In-Document)

Superbuild tracks state by updating the plan document directly.

### Phase Status in Overview Table

```markdown
| Phase | Name | ... | Status |
|-------|------|-----|--------|
| 0 | Bootstrap | ... | ✅ |
| 1 | Core Services | ... | ✅ |
| 2A | Backend | ... | 🔄 |
```

**Read:** Parse table, extract Status column.

### Task Checkboxes

```markdown
#### Objectives
- [x] Create config service
- [x] Create logger service
- [ ] Create state service   <-- incomplete
```

**Read:** Count `- [x]` (done) vs `- [ ]` (pending) under each phase.

### Definition of Done Checkboxes

```markdown
#### Definition of Done (Quality Gate)
- [x] Code passes linter
- [x] Code passes formatter check
- [x] Code passes type checker
- [x] All new tests pass
- [ ] All existing tests pass  <-- failed
```

**Read:** All must be `[x]` for phase to truly be complete.

### Trust Level: LOW

Superbuild updates are self-reported. The agent that built the code also checked the boxes. Superval must **independently verify every claim**.

---

## Autobuild State (.autobuild/ Directory)

Autobuild uses filesystem-based state with independent verification.

### Directory Layout

```
.autobuild/
  config.json           # Execution config (stack, commands)
  commits.sh            # Generated commit script
  phases/
    phase-0.json        # Per-phase state
    phase-1.json
    phase-2a.json
    ...
  logs/
    execution.log       # Overall timeline
    phase-0.log         # Per-phase agent output
    ...
```

### config.json Contract

```typescript
interface AutobuildConfig {
  version: string;          // "1.0.0"
  plan_path: string;        // "docs/feature-plan.md"
  commit_mode: string;      // "auto" | "message-only" | "single"
  started_at: string;       // ISO 8601
  last_updated: string;     // ISO 8601
  stack: {
    language: string;       // "typescript" | "python" | "go" | "rust"
    framework?: string;     // "express" | "fastapi" | etc.
    package_manager: string; // "npm" | "pnpm" | "yarn" | "pip" | etc.
    test_framework: string; // "vitest" | "jest" | "pytest" | "go test"
    linter?: string;        // "eslint" | "ruff" | "golangci-lint"
    formatter?: string;     // "prettier" | "black" | "gofmt"
  };
  commands: {
    lint?: string;          // "npm run lint"
    format?: string;        // "npm run format:check"
    typecheck?: string;     // "npm run typecheck"
    test: string;           // "npm test"
  };
  phases: {
    total: number;
    completed: number;
    failed: number;
    pending: number;
  };
}
```

**Superval uses:** `stack`, `commands`, `phases` to bootstrap detection.

### Phase State Contract

```typescript
interface PhaseState {
  phase_id: string;         // "0", "1", "2a"
  phase_name: string;       // "Bootstrap"
  status: "pending" | "running" | "complete" | "failed" | "blocked";
  attempt: number;          // Current attempt (0 = not started)
  max_attempts: number;     // Usually 2

  timestamps: {
    started?: string;       // ISO 8601
    completed?: string;     // ISO 8601
    failed?: string;        // ISO 8601
    duration_seconds?: number;
  };

  dependencies: {
    depends_on: string[];   // ["1"]
    parallel_with: string[]; // ["2b", "2c"]
    blocks: string[];       // ["3"]
  };

  execution: {
    subagent_id: string;
    subagent_model: string;
    tasks_total: number;
    tasks_completed: number;
  } | null;

  quality_gates: {
    lint?: { passed: boolean; command: string; output_summary: string };
    format?: { passed: boolean; command: string; output_summary: string };
    typecheck?: { passed: boolean; command: string; output_summary: string };
    test: { passed: boolean; command: string; output_summary: string; coverage?: string };
  } | null;

  verification: {
    subagent_claimed: string;
    fresh_verification: "passed" | "failed";
    verified_at: string;
  } | null;

  commit: {
    message: string;
    type: string;
    scope: string;
    files_created: string[];
    files_modified: string[];
    files_deleted: string[];
    committed: boolean;
    commit_sha?: string;
  } | null;

  plan_updates: {
    tasks_checked: number;
    dod_checked: number;
    status_updated: boolean;
  } | null;

  error: {
    type: string;
    message: string;
    details?: string;
  } | null;
}
```

**Superval uses:**
- `status` to know what was attempted
- `quality_gates` to know what was claimed
- `commit.files_created/modified` to know what files to verify
- `verification.fresh_verification` to know autobuild's own verdict
- `error` to understand failure context

### Trust Level: MEDIUM

Autobuild includes independent verification (trust-but-verify pattern). The `verification.fresh_verification` field indicates whether autobuild's own verifier confirmed the sub-agent's claims. Still, superval re-verifies everything independently.

---

## Reading State: Priority Order

When both state sources exist, superval reads in this order:

```
1. .autobuild/config.json     -> Stack detection, commands (if available)
2. .autobuild/phases/*.json   -> Per-phase file lists, status (if available)
3. Plan document               -> Phase overview, objectives, file expectations
4. Fresh detection             -> Fallback if no state files exist
```

Priority for conflicts:
- **Plan document is always the source of truth** for what SHOULD exist
- **State files are evidence** of what was ATTEMPTED
- **Fresh verification** is the final arbiter of what ACTUALLY exists

---

## Superval's Own State

Superval writes its own state to `.superval/` (if the directory doesn't exist, create it):

```
.superval/
  report.json            # Latest validation report
  report.md              # Human-readable report
  acceptance-tests/      # Generated acceptance test files
    structural.test.ts
    wiring.test.ts
    behavioral.test.ts
```

### report.json Contract

```typescript
interface SupervalReport {
  version: "1.0.0";
  plan_path: string;
  project_path: string;
  timestamp: string;
  attempt: number;

  features: FeatureResult[];
  acceptance_criteria: ACResult[];
  quality_gates: GateResult[];

  summary: {
    total_features: number;
    passed: number;
    failed: number;
    skipped: number;
    status: "PASS" | "FAIL";
  };
}

interface FeatureResult {
  id: string;
  description: string;
  phase: string;
  structural: "PASS" | "FAIL" | "SKIP";
  wiring: "PASS" | "FAIL" | "SKIP";
  behavioral: "PASS" | "FAIL" | "SKIP";
  status: "PASS" | "FAIL";
  details?: string;
}
```
