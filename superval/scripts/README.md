# Superval Scripts

Automation scripts used by the superval validation skill.

## detect-test-framework.sh

Detects available test frameworks, quality tools, and stack information.

```bash
./detect-test-framework.sh [project-dir]
```

**Output:** KEY=VALUE pairs for STACK, TEST_FRAMEWORK, LINTER, FORMATTER, etc.
**Exit 0:** Test framework found (VERDICT=READY)
**Exit 1:** No test framework (VERDICT=NO_TEST_FRAMEWORK)

## validate-structural.sh

Level 1 structural verification: checks that expected files exist.

```bash
./validate-structural.sh <files-list>
```

**Input:** File with one path per line
**Exit 0:** All files exist
**Exit 1:** One or more files missing
