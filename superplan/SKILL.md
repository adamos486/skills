---
name: superplan
description: Create comprehensive, multi-phase implementation plans for features. Interviews user for requirements, researches best practices, generates parallelizable phases with TDD-first acceptance criteria, architecture diagrams, and detailed code deltas. Use when starting significant features, epics, or complex tasks.
metadata:
  version: "1.0"
  generated-at: "2025-01-09"
compatibility: Requires internet access for best practices research. Works with any codebase.
---

# Superplan: Comprehensive Feature Planning

## Overview

Superplan creates detailed, executable implementation plans that enable parallel agent execution. Each plan includes everything needed to implement a feature: requirements, architecture, code changes, tests, and acceptance criteria.

## When to Use Superplan

- Starting a new feature or epic
- Complex tasks requiring multiple phases
- Tasks that could benefit from parallel execution by multiple agents
- When you need comprehensive documentation of implementation decisions
- When the team needs to understand the full scope before committing

## Core Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SUPERPLAN WORKFLOW                          │
├─────────────────────────────────────────────────────────────────────┤
│  1. INTAKE          →  Gather story/requirements from user          │
│  2. INTERVIEW       →  Ask clarifying questions                     │
│  3. RESEARCH        →  Look up best practices (as of TODAY)         │
│  4. EXPLORE         →  Understand existing codebase patterns        │
│  5. ARCHITECT       →  Design solution with diagrams                │
│  6. PHASE           →  Break into parallelizable phases             │
│  7. DETAIL          →  Specify code deltas per phase                │
│  8. TEST            →  Define failing tests per phase (TDD)         │
│  9. DOCUMENT        →  Write plan to docs/<feature>-plan.md         │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: INTAKE - Gather Requirements

### What You're Doing
Collecting the feature requirements from the user through story input.

### Actions

1. **Ask the user to provide their story/requirements** using one of these methods:
   - Copy/paste the story text directly
   - Provide a link to a ticket/story (Jira, Linear, GitHub Issue, etc.)
   - Use an MCP tool to fetch the story if available
   - Describe the feature verbally

2. **Capture the raw input** exactly as provided

3. **Identify the story type**:
   - User Story (`As a <role>, I want <capability>, so that <benefit>`)
   - Technical Task (implementation-focused)
   - Bug Fix (problem/solution)
   - Epic (large feature with sub-stories)

### Output Template

```markdown
## Story Intake

**Source**: [Pasted / Link / MCP / Verbal]
**Type**: [User Story / Technical Task / Bug Fix / Epic]

### Raw Requirements
[Exact copy of what user provided]

### Initial Understanding
[1-2 sentence summary of what you think this feature does]
```

---

## Phase 2: INTERVIEW - Clarifying Questions

### What You're Doing
Asking targeted questions to fill gaps in requirements before planning.

### Question Categories

Ask questions in these categories (select relevant ones):

1. **Scope & Boundaries**
   - What is explicitly out of scope?
   - Are there related features we should NOT touch?
   - What's the MVP vs future enhancements?

2. **User Experience**
   - Who are the primary users?
   - What's the expected user flow?
   - Are there mockups, wireframes, or design specs?

3. **Technical Constraints**
   - Are there performance requirements?
   - Security or compliance needs?
   - Must integrate with specific systems?
   - Technology preferences or restrictions?

4. **Data & State**
   - What data does this feature need?
   - Where does data come from/go to?
   - Any data migration needed?

5. **Testing & Validation**
   - How will we know it's working correctly?
   - Are there specific test scenarios required?
   - Who needs to sign off?

6. **Dependencies**
   - Does this depend on other work being completed?
   - Does other work depend on this?
   - External service dependencies?

### Interview Format

Ask 3-5 most relevant questions, then wait for answers before proceeding. Example:

```markdown
## Clarifying Questions

Before I create the plan, I need to understand a few things:

1. **Scope**: You mentioned user authentication - should this include social login (Google, GitHub) or just email/password?

2. **UX**: Do you have mockups for the login/signup forms, or should I propose a design?

3. **Security**: Any specific requirements around password policies or session management?

4. **Testing**: Are there existing auth tests I should align with, or is this greenfield?

Please answer these so I can create an accurate plan.
```

---

## Phase 3: RESEARCH - Best Practices Lookup

### What You're Doing
Researching current best practices as of TODAY'S DATE (2025-01-09).

### Research Areas

1. **Industry Standards**
   - Current best practices for the technology/pattern
   - Security recommendations (OWASP, etc.)
   - Accessibility guidelines (WCAG, etc.)

2. **Technology-Specific**
   - Framework-specific patterns
   - Library versions and recommendations
   - Known issues or gotchas

3. **Architecture Patterns**
   - Recommended patterns for this type of feature
   - Anti-patterns to avoid
   - Scalability considerations

### Research Output

```markdown
## Best Practices Research (as of 2025-01-09)

### Sources Consulted
- [Source 1](url)
- [Source 2](url)

### Key Findings

#### [Topic 1]
[Summary of best practice and why it applies]

#### [Topic 2]
[Summary of best practice and why it applies]

### Recommendations for This Feature
1. [Specific recommendation based on research]
2. [Specific recommendation based on research]
```

---

## Phase 4: EXPLORE - Codebase Analysis

### What You're Doing
Understanding existing patterns, conventions, and integration points in the codebase.

### Exploration Targets

1. **Existing Patterns**
   - How are similar features implemented?
   - What conventions exist for this type of code?
   - Testing patterns used

2. **Integration Points**
   - Which files/modules will this touch?
   - API contracts that must be maintained
   - Shared utilities that can be reused

3. **Technical Debt**
   - Areas that might need refactoring first
   - Known issues that could impact this work

### Exploration Output

```markdown
## Codebase Analysis

### Relevant Existing Code
| File | Purpose | Relevance |
|------|---------|-----------|
| `src/auth/index.ts` | Auth utilities | Will extend |
| `src/api/routes.ts` | API routing | Will add routes |

### Patterns to Follow
- [Pattern 1 with example from codebase]
- [Pattern 2 with example from codebase]

### Integration Points
- [Integration point 1]
- [Integration point 2]

### Technical Debt Notes
- [Any debt that affects this work]
```

---

## Phase 5: ARCHITECT - Solution Design

### What You're Doing
Designing the technical solution with diagrams.

### Architecture Components

1. **High-Level Architecture**
   - System/component diagram
   - Data flow

2. **API Design** (if applicable)
   - Endpoints
   - Request/response schemas
   - Error handling

3. **Data Model** (if applicable)
   - Schema changes
   - Migrations needed

4. **Component Design** (if applicable)
   - Component hierarchy
   - State management
   - Props/interfaces

### Diagram Format

Use ASCII/text diagrams for portability:

```markdown
## Architecture

### System Overview

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Client    │ ───► │   API       │ ───► │  Database   │
│  (React)    │ ◄─── │  (Node)     │ ◄─── │  (Postgres) │
└─────────────┘      └─────────────┘      └─────────────┘
                            │
                            ▼
                     ┌─────────────┐
                     │   Redis     │
                     │  (Cache)    │
                     └─────────────┘
```

### Data Flow

```
User Login Request
       │
       ▼
┌──────────────────┐
│ Validate Input   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Check Credentials│
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
  Valid    Invalid
    │         │
    ▼         ▼
┌───────┐ ┌───────┐
│ Token │ │ Error │
└───────┘ └───────┘
```
```

---

## Phase 6: PHASE - Parallel Work Breakdown

### What You're Doing
Breaking work into phases that can be executed in parallel where possible.

### Phase Design Principles

1. **Independence**: Phases should be executable without waiting for others when possible
2. **Testability**: Each phase should be independently testable
3. **Clear Boundaries**: Well-defined inputs and outputs
4. **Reasonable Size**: Each phase ~2-4 hours of work

### Parallelization Rules

- **CAN parallelize**: Independent components, separate API endpoints, unrelated tests
- **CANNOT parallelize**: Sequential dependencies, shared state setup, migrations before data access

### Phase Structure

```markdown
## Implementation Phases

### Phase Overview

```
       ┌─────────────────────────────────────────┐
       │           Phase 0: Setup                │
       │     (Database migrations, configs)      │
       └──────────────────┬──────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
   ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
   │  Phase 1A   │ │  Phase 1B   │ │  Phase 1C   │
   │  (Backend   │ │  (Frontend  │ │  (Tests)    │
   │   API)      │ │   UI)       │ │             │
   └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
          │               │               │
          └───────────────┼───────────────┘
                          │
                          ▼
               ┌─────────────────────┐
               │   Phase 2: Integrate │
               │   (Wire up + E2E)    │
               └─────────────────────┘
```

### Phase Dependencies
| Phase | Depends On | Can Run With |
|-------|------------|--------------|
| 0     | None       | None         |
| 1A    | 0          | 1B, 1C       |
| 1B    | 0          | 1A, 1C       |
| 1C    | 0          | 1A, 1B       |
| 2     | 1A, 1B, 1C | None         |
```

---

## Phase 7: DETAIL - Code Deltas Per Phase

### What You're Doing
Specifying exact code changes for each phase.

### Code Delta Format

For each file that will be modified or created:

```markdown
### Phase 1A: Backend API

#### File: `src/api/auth/login.ts` (CREATE)

```typescript
// Full file contents for new files
import { Router } from 'express';
import { validateLogin } from './validators';
import { authenticateUser } from '../../services/auth';

export const loginRouter = Router();

loginRouter.post('/login', async (req, res) => {
  const { email, password } = req.body;

  const validation = validateLogin(email, password);
  if (!validation.valid) {
    return res.status(400).json({ error: validation.error });
  }

  const result = await authenticateUser(email, password);
  if (!result.success) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  res.json({ token: result.token });
});
```

#### File: `src/api/routes.ts` (MODIFY)

```diff
 import { userRouter } from './users';
+import { loginRouter } from './auth/login';

 export function registerRoutes(app: Express) {
   app.use('/api/users', userRouter);
+  app.use('/api/auth', loginRouter);
 }
```
```

---

## Phase 8: TEST - TDD Acceptance Criteria

### What You're Doing
Defining failing tests for each phase BEFORE implementation.

### Testing Pyramid

Follow the testing pyramid - more unit tests, fewer integration, even fewer E2E:

```
        /\
       /  \       E2E Tests (few)
      /────\      - Critical user journeys only
     /      \
    /────────\    Integration Tests (some)
   /          \   - API contracts, database
  /────────────\
 /              \ Unit Tests (many)
/────────────────\- Business logic, utilities
```

### Test Specification Format

```markdown
### Phase 1A Tests

#### Unit Tests (src/services/auth.test.ts)

These tests MUST FAIL before implementation:

```typescript
describe('authenticateUser', () => {
  it('should return success with valid credentials', async () => {
    // Arrange
    const email = 'test@example.com';
    const password = 'validPassword123';

    // Act
    const result = await authenticateUser(email, password);

    // Assert
    expect(result.success).toBe(true);
    expect(result.token).toBeDefined();
  });

  it('should return failure with invalid password', async () => {
    // Arrange
    const email = 'test@example.com';
    const password = 'wrongPassword';

    // Act
    const result = await authenticateUser(email, password);

    // Assert
    expect(result.success).toBe(false);
    expect(result.error).toBe('Invalid credentials');
  });

  it('should return failure for non-existent user', async () => {
    // Arrange
    const email = 'nonexistent@example.com';
    const password = 'anyPassword';

    // Act
    const result = await authenticateUser(email, password);

    // Assert
    expect(result.success).toBe(false);
  });
});
```

#### Integration Tests (tests/integration/auth.test.ts)

```typescript
describe('POST /api/auth/login', () => {
  it('should return 200 with token for valid login', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@example.com', password: 'validPassword' });

    expect(response.status).toBe(200);
    expect(response.body.token).toBeDefined();
  });

  it('should return 400 for missing credentials', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({});

    expect(response.status).toBe(400);
  });
});
```

### Test-First Workflow

For each phase:
1. Write tests FIRST (they will fail - this is expected)
2. Run tests to confirm they fail
3. Implement the code
4. Run tests to confirm they pass
5. All existing tests must still pass
```

### Durable vs Brittle Tests

Write **durable tests** that test business logic, not implementation details:

```typescript
// ❌ BRITTLE - Tests implementation details
it('should call bcrypt.compare with password', () => {
  expect(bcrypt.compare).toHaveBeenCalledWith('password', hash);
});

// ✅ DURABLE - Tests behavior
it('should authenticate user with correct password', () => {
  const result = await authenticateUser('user@test.com', 'correctPassword');
  expect(result.authenticated).toBe(true);
});
```

---

## Phase 9: DOCUMENT - Write the Plan

### What You're Doing
Writing the complete plan to `docs/<feature>-plan.md`. For large plans that exceed ~20,000 tokens, split into multiple files: `docs/<feature>-plan-1.md`, `docs/<feature>-plan-2.md`, etc.

### Multi-File Plan Strategy

Large comprehensive plans may exceed file size limits (~25,000 tokens). When this happens:

1. **Split by logical boundaries** - Each file should contain complete sections:
   - **File 1 (`-plan-1.md`)**: Executive Summary, Requirements, Research & Best Practices, Architecture
   - **File 2 (`-plan-2.md`)**: Phase 0 and Phase 1 (parallelizable phases)
   - **File 3+ (`-plan-N.md`)**: Remaining phases, Testing Strategy, Assumptions, Appendix

2. **Each file must be self-contained readable**:
   - Include a header referencing the plan set
   - Include navigation links to other parts
   - Include the Table of Contents for that specific file

3. **Size thresholds** (estimate ~4 tokens per word):
   - Under ~4,000 lines / ~20,000 tokens: Single file
   - Over ~4,000 lines / ~20,000 tokens: Split into multiple files

### Multi-File Header Template

For split plans, use this header in each file:

```markdown
# [Feature Name] Implementation Plan - Part [N] of [Total]

> **Plan Set**: `docs/<feature>-plan-*.md`
> **This File**: Part [N] - [Section Names]
> **Navigation**: [Part 1](feature-plan-1.md) | [Part 2](feature-plan-2.md) | ...
>
> Generated: [DATE]
> Status: Draft | In Review | Approved | In Progress | Complete
```

### Plan File Structure

```markdown
# <Feature Name> Implementation Plan

Generated: <DATE>
Status: Draft | In Review | Approved | In Progress | Complete

## Table of Contents
1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Architecture](#architecture)
4. [Implementation Phases](#implementation-phases)
5. [Assumptions & Known Unknowns](#assumptions--known-unknowns)
6. [Appendix](#appendix)

---

## Overview

### Summary
[2-3 sentence summary]

### Goals
- [ ] Goal 1
- [ ] Goal 2

### Non-Goals
- Non-goal 1
- Non-goal 2

---

## Requirements

### User Story
[Original story]

### Acceptance Criteria
- [ ] AC 1
- [ ] AC 2

### Clarifications
[Q&A from interview phase]

---

## Architecture

### System Diagram
[ASCII diagram]

### Data Flow
[ASCII diagram]

### API Design
[Endpoints, schemas]

### Data Model
[Schema changes]

---

## Implementation Phases

### Phase 0: Setup
**Depends on**: None
**Can parallelize with**: None
**Estimated complexity**: Low

#### Objectives
- [ ] Objective 1
- [ ] Objective 2

#### Code Changes
[Detailed code deltas]

#### Tests (Write First - Must Fail Initially)
[Test specifications]

#### Acceptance Criteria
- [ ] All tests pass
- [ ] No regressions in existing tests
- [ ] [Specific criteria]

#### Manual Testing Instructions
[How to manually verify]

---

### Phase 1A: [Name]
[Same structure as Phase 0]

---

## Assumptions & Known Unknowns

### Assumptions
| # | Assumption | Risk if Wrong | Mitigation |
|---|------------|---------------|------------|
| 1 | Users have email | Medium | Add social login later |

### Known Unknowns
| # | Unknown | Impact | How to Resolve |
|---|---------|--------|----------------|
| 1 | Peak load numbers | Could affect architecture | Load test before launch |

### Open Questions
- [ ] Question 1 (assigned to: @person)
- [ ] Question 2 (assigned to: @person)

---

## Appendix

### Best Practices Research
[Research findings]

### Codebase Analysis
[Existing patterns]

### References
- [Link 1]
- [Link 2]
```

### Chunked Writing & Multi-File Splitting

For large plans (>500 lines), write in chunks. For very large plans that will exceed ~20,000 tokens, use multiple files:

**Single File Plans** (under ~4,000 lines):
1. Write Overview + Requirements first
2. Save and confirm written
3. Write Architecture section
4. Save and confirm written
5. Write each Phase separately
6. Save after each phase
7. Write Assumptions + Appendix last

**Multi-File Plans** (over ~4,000 lines / ~20,000 tokens):

When content exceeds limits, split proactively:

1. **File 1** (`<feature>-plan-1.md`):
   - Executive Summary, Requirements, Research & Best Practices, Architecture
   - Phase Overview diagram
   - Target: ~3,000-4,000 lines max

2. **File 2** (`<feature>-plan-2.md`):
   - Phase 0: Setup
   - Phase 1A, 1B, 1C (parallelizable phases)
   - Target: ~3,000-4,000 lines max

3. **File 3+** (`<feature>-plan-N.md`):
   - Remaining phases (Phase 2, etc.)
   - Testing Strategy
   - Assumptions & Known Unknowns
   - Appendix

**Detection**: If a single phase's code deltas and tests exceed ~2,000 lines, that phase alone may need its own file.

This prevents context loss, creates natural checkpoints, and ensures files remain readable.

---

## Execution Instructions

When running Superplan, follow this exact sequence:

### Step 1: Intake
```
I'll help you create a comprehensive implementation plan.

First, please provide the feature requirements in one of these ways:
1. Paste the user story/requirements directly
2. Share a link to the ticket (Jira, Linear, GitHub, etc.)
3. Describe the feature you want to build

Which would you like to do?
```

### Step 2: After Intake
Summarize understanding and ask clarifying questions.

### Step 3: After Clarification
Research best practices using web search with TODAY'S DATE.

### Step 4: Codebase Exploration
Use exploration tools to understand existing patterns.

### Step 5: Create Plan
Write plan to `docs/<feature-name>-plan.md`. For large plans exceeding ~20,000 tokens, split into multiple files: `docs/<feature-name>-plan-1.md`, `docs/<feature-name>-plan-2.md`, etc.

### Step 6: Review
Ask user to review plan and provide feedback.

---

## Output Checkpoints

Use these status updates throughout:

```
📥 INTAKE COMPLETE
[Summary of what was captured]

❓ INTERVIEW COMPLETE
[Summary of clarifications received]

🔍 RESEARCH COMPLETE
[Key findings summary]

🗺️ CODEBASE ANALYSIS COMPLETE
[Key patterns identified]

🏗️ ARCHITECTURE COMPLETE
[Design summary]

📋 PHASES DEFINED
[Phase overview with parallelization notes]

📝 PLAN WRITTEN
Location: docs/<feature>-plan.md (or docs/<feature>-plan-*.md if split)
Files: [1 | N files if split]
Total phases: X
Parallelizable phases: Y

Ready for review.
```

---

## References

For detailed guidance on specific topics, see:

- [Interview Guide](references/INTERVIEW-GUIDE.md) - Comprehensive question templates
- [Plan Template](references/PLAN-TEMPLATE.md) - Full plan file template
- [Testing Pyramid](references/TESTING-PYRAMID.md) - TDD and test strategy details
