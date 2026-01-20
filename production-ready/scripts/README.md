# Production Ready Automation Scripts

These scripts automate common production readiness checks. They are designed to be language-agnostic and work with any project.

## Scripts Overview

| Script | Purpose | Dependencies |
|--------|---------|--------------|
| `production-audit.sh` | Main orchestrator - runs all checks | All tools below |
| `scan-secrets.sh` | Detect hardcoded secrets | gitleaks |
| `audit-dependencies.sh` | Check for vulnerable dependencies | syft, grype |
| `generate-sbom.sh` | Generate Software Bill of Materials | syft |
| `check-config.sh` | Validate configuration hygiene | bash |

## Installation

### Required Tools

Install the following tools for full functionality:

```bash
# macOS (Homebrew)
brew install gitleaks syft grype

# Linux (using official installers)
# gitleaks
curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/main/scripts/install.sh | sh -s -- -b /usr/local/bin

# syft
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# grype
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```

## Usage

### Quick Audit (All Checks)

```bash
./production-audit.sh /path/to/project
```

### Individual Checks

```bash
# Scan for secrets
./scan-secrets.sh /path/to/project

# Audit dependencies
./audit-dependencies.sh /path/to/project

# Generate SBOM
./generate-sbom.sh /path/to/project

# Check configuration
./check-config.sh /path/to/project
```

### Output

Scripts output results in multiple formats:
- Console output with color-coded status
- JSON reports in `./docs/reports/`
- Markdown audit report: `./docs/reports/security-audit-YYYY-MM-DD.md`
- Exit codes: 0 = pass, 1 = issues found, 2 = tool error

The `docs/reports/` directory is created automatically if it doesn't exist.

## CI/CD Integration

Add to your GitHub Actions workflow:

```yaml
- name: Production Readiness Audit
  run: |
    curl -sSfL https://raw.githubusercontent.com/.../production-audit.sh | bash -s -- .
```

## Customization

Create a `.production-ready.yml` in your project root to customize behavior:

```yaml
secrets:
  exclude_paths:
    - "test/fixtures/*"
    - "*.test.js"

dependencies:
  severity_threshold: high  # low, medium, high, critical

sbom:
  format: cyclonedx-json  # or spdx-json
```
