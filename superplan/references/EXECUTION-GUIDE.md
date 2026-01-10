# Superplan Execution Guide

This guide provides the detailed execution flow, prompts, and output checkpoints for running Superplan.

---

## Execution Sequence

Follow this exact sequence when running Superplan:

### Step 1: Intake

Start with this prompt to gather requirements:

```
I'll help you create a comprehensive implementation plan.

First, please provide the feature requirements in one of these ways:
1. Paste the user story/requirements directly
2. Share a link to the ticket (Jira, Linear, GitHub, etc.)
3. Describe the feature you want to build

Which would you like to do?
```

**After receiving input:**
- Capture raw requirements exactly as provided
- Identify story type (User Story, Technical Task, Bug Fix, Epic)
- Summarize initial understanding in 1-2 sentences

### Step 2: Interview

After intake, ask 3-5 clarifying questions based on what's missing:

```
Before I create the plan, I need to understand a few things:

1. **Scope**: [Question about boundaries/MVP]
2. **Technical**: [Question about constraints/requirements]
3. **Data**: [Question about data flow/storage]
4. **Testing**: [Question about validation/sign-off]

Please answer these so I can create an accurate plan.
```

See [INTERVIEW-GUIDE.md](INTERVIEW-GUIDE.md) for comprehensive question templates.

**Wait for answers before proceeding.**

### Step 3: Research

After clarification, research current best practices:

- Use web search with TODAY'S DATE
- Research industry standards (OWASP, WCAG, etc.)
- Check framework-specific patterns and recommendations
- Document sources and key findings

### Step 4: Codebase Exploration

Analyze the existing codebase:

- Identify existing patterns for similar features
- Find integration points and files to modify
- Note shared utilities that can be reused
- Document any technical debt that affects the work

### Step 5: Create Plan

Write the plan to `docs/<feature-name>-plan.md`.

**For large plans exceeding ~20,000 tokens**, split into multiple files:
- `docs/<feature-name>-plan-1.md` - Overview, Requirements, Architecture
- `docs/<feature-name>-plan-2.md` - Phase 0 and Phase 1 (parallelizable)
- `docs/<feature-name>-plan-N.md` - Remaining phases, Appendix

See [PLAN-TEMPLATE.md](PLAN-TEMPLATE.md) for the complete plan structure.

### Step 6: Review

Ask the user to review and provide feedback:

```
The implementation plan is ready for review.

Location: docs/<feature>-plan.md
Phases: X total (Y parallelizable)

Please review and let me know:
1. Any requirements I missed or misunderstood?
2. Any technical concerns with the approach?
3. Ready to proceed, or changes needed?
```

---

## Output Checkpoints

Use these status updates throughout execution to show progress:

### After Intake

```
INTAKE COMPLETE
- Source: [Pasted / Link / MCP / Verbal]
- Type: [User Story / Technical Task / Bug Fix / Epic]
- Summary: [1-2 sentence summary]
```

### After Interview

```
INTERVIEW COMPLETE
- Questions asked: [N]
- Key clarifications:
  - [Clarification 1]
  - [Clarification 2]
- Known unknowns identified: [N]
```

### After Research

```
RESEARCH COMPLETE
- Sources consulted: [N]
- Key findings:
  - [Finding 1]
  - [Finding 2]
- Recommendations: [N]
```

### After Codebase Analysis

```
CODEBASE ANALYSIS COMPLETE
- Files analyzed: [N]
- Patterns identified:
  - [Pattern 1]
  - [Pattern 2]
- Integration points: [N]
```

### After Architecture

```
ARCHITECTURE COMPLETE
- Components designed: [N]
- API endpoints: [N] (if applicable)
- Data model changes: [Y/N]
- Key design decisions:
  - [Decision 1]
  - [Decision 2]
```

### After Phase Definition

```
PHASES DEFINED
- Total phases: [N]
- Parallelizable: [List which phases can run together]
- Sequential: [List phases that must run in order]

Phase Overview:
[ASCII diagram of phase dependencies]
```

### After Plan Written

```
PLAN WRITTEN
- Location: docs/<feature>-plan.md (or docs/<feature>-plan-*.md if split)
- Files: [1 | N files if split]
- Total phases: [N]
- Parallelizable phases: [N]
- Lines: ~[N]

Ready for review.
```

---

## Checkpoint Usage

Checkpoints serve multiple purposes:

1. **Progress visibility** - User knows where you are in the process
2. **Context anchors** - Summarize decisions before moving forward
3. **Recovery points** - If interrupted, know where to resume
4. **Quality gates** - Confirm understanding before proceeding

### When to Use Checkpoints

- **Always** use after each major phase (Intake, Interview, Research, etc.)
- **Optionally** use mid-phase for very large features
- **Especially** use when there are many clarifications or complex decisions

### Checkpoint Best Practices

1. Keep summaries concise (3-5 bullet points max)
2. Highlight decisions and their rationale
3. Note any assumptions or unknowns discovered
4. Include counts (files, endpoints, phases) for quick reference

---

## Handling Interruptions

If the conversation is interrupted mid-plan:

### To Resume

1. Read the existing plan file(s)
2. Identify the last completed section
3. Summarize what's done vs. remaining
4. Continue from the next section

### Resume Prompt

```
I see we were working on the [Feature] plan. Let me check the current state.

CURRENT STATE:
- Completed: [Sections done]
- In progress: [Current section]
- Remaining: [Sections left]

[Continue from where we left off]
```

---

## Common Issues & Solutions

### Issue: Scope keeps expanding

**Solution**: Reference the documented Non-Goals and gently redirect:

```
That's a great idea for a future enhancement. For this plan, we agreed to
keep [X] out of scope. I've noted it in the Appendix as a future consideration.
```

### Issue: Missing technical information

**Solution**: Document as a Known Unknown and propose a default:

```
I don't have information about [X]. I'll assume [Y] for now and note this
as a Known Unknown. If this assumption is wrong, we can adjust the plan.
```

### Issue: Plan is getting too large

**Solution**: Proactively split into multiple files:

```
This plan is getting comprehensive. To keep files manageable, I'll split it:
- Part 1: Overview, Requirements, Architecture
- Part 2: Implementation Phases
- Part 3: Testing Strategy, Appendix
```

### Issue: Conflicting requirements

**Solution**: Surface the conflict explicitly:

```
I noticed a potential conflict:
- Requirement A: [X]
- Requirement B: [Y]
- Conflict: [Why they conflict]

Which takes priority, or how should we reconcile this?
```
