#!/usr/bin/env bash
#
# production-audit.sh - Main orchestrator for production readiness checks
#
# Usage: ./production-audit.sh [project_path] [--mode quick|security|full]
#
# Modes:
#   quick    - Fast checks suitable for CI (secrets, critical vulns)
#   security - Deep security audit (secrets, all vulns, SBOM)
#   full     - Comprehensive audit (all checks + reports)
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_PATH="${1:-.}"
MODE="${2:-full}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="${PROJECT_PATH}/docs/reports"
OUTPUT_DIR="${REPORT_DIR}"
DATE_STAMP=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/security-audit-${DATE_STAMP}.md"

# Track results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  🚀 PRODUCTION READINESS AUDIT${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  Project: ${PROJECT_PATH}"
    echo -e "  Mode:    ${MODE}"
    echo -e "  Time:    $(date)"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${YELLOW}▶ $1${NC}"
    echo "─────────────────────────────────────────"
}

pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((TOTAL_CHECKS++))
    ((PASSED_CHECKS++))
}

fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((TOTAL_CHECKS++))
    ((FAILED_CHECKS++))
}

warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

skip() {
    echo -e "  ${BLUE}○${NC} $1 (skipped)"
}

check_tool() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Initialize output directory (docs/reports/)
mkdir -p "${OUTPUT_DIR}"

# Initialize findings arrays
declare -a CRITICAL_FINDINGS=()
declare -a HIGH_FINDINGS=()
declare -a MEDIUM_FINDINGS=()
declare -a TOOLS_USED=()

print_header

# ============================================================
# CHECK 1: Secret Scanning
# ============================================================
print_section "Secret Scanning"

if check_tool gitleaks; then
    echo "  Running gitleaks..."
    if gitleaks detect --source="${PROJECT_PATH}" --no-banner --report-path="${OUTPUT_DIR}/secrets-${TIMESTAMP}.json" --report-format=json 2>/dev/null; then
        pass "No hardcoded secrets detected"
    else
        fail "Potential secrets found - see ${OUTPUT_DIR}/secrets-${TIMESTAMP}.json"
    fi
else
    warn "gitleaks not installed - install with: brew install gitleaks"
    skip "Secret scanning"
fi

# ============================================================
# CHECK 2: Dependency Vulnerabilities
# ============================================================
print_section "Dependency Vulnerabilities"

if check_tool grype; then
    echo "  Scanning dependencies with grype..."

    SEVERITY_THRESHOLD="high"
    if [[ "$MODE" == "quick" ]]; then
        SEVERITY_THRESHOLD="critical"
    fi

    if grype dir:"${PROJECT_PATH}" --only-fixed --fail-on="${SEVERITY_THRESHOLD}" -o json > "${OUTPUT_DIR}/vulnerabilities-${TIMESTAMP}.json" 2>/dev/null; then
        pass "No ${SEVERITY_THRESHOLD}+ vulnerabilities with available fixes"
    else
        fail "${SEVERITY_THRESHOLD}+ vulnerabilities found - see ${OUTPUT_DIR}/vulnerabilities-${TIMESTAMP}.json"
    fi
else
    warn "grype not installed - install with: brew install grype"

    # Fallback to native audit commands
    echo "  Checking for native audit tools..."

    if [[ -f "${PROJECT_PATH}/package.json" ]] && check_tool npm; then
        echo "  Running npm audit..."
        if npm audit --prefix="${PROJECT_PATH}" --audit-level=high 2>/dev/null; then
            pass "npm audit passed"
        else
            fail "npm audit found high+ vulnerabilities"
        fi
    fi

    if [[ -f "${PROJECT_PATH}/requirements.txt" ]] && check_tool pip-audit; then
        echo "  Running pip-audit..."
        if pip-audit -r "${PROJECT_PATH}/requirements.txt" 2>/dev/null; then
            pass "pip-audit passed"
        else
            fail "pip-audit found vulnerabilities"
        fi
    fi

    if [[ -f "${PROJECT_PATH}/Cargo.toml" ]] && check_tool cargo-audit; then
        echo "  Running cargo audit..."
        if (cd "${PROJECT_PATH}" && cargo audit 2>/dev/null); then
            pass "cargo audit passed"
        else
            fail "cargo audit found vulnerabilities"
        fi
    fi

    if [[ -f "${PROJECT_PATH}/go.mod" ]]; then
        echo "  Running govulncheck..."
        if check_tool govulncheck; then
            if (cd "${PROJECT_PATH}" && govulncheck ./... 2>/dev/null); then
                pass "govulncheck passed"
            else
                fail "govulncheck found vulnerabilities"
            fi
        else
            warn "govulncheck not installed"
        fi
    fi
fi

# ============================================================
# CHECK 3: SBOM Generation (security/full modes)
# ============================================================
if [[ "$MODE" != "quick" ]]; then
    print_section "SBOM Generation"

    if check_tool syft; then
        echo "  Generating Software Bill of Materials..."
        if syft dir:"${PROJECT_PATH}" -o cyclonedx-json="${OUTPUT_DIR}/sbom-${TIMESTAMP}.json" 2>/dev/null; then
            pass "SBOM generated: ${OUTPUT_DIR}/sbom-${TIMESTAMP}.json"
        else
            fail "SBOM generation failed"
        fi
    else
        warn "syft not installed - install with: brew install syft"
        skip "SBOM generation"
    fi
fi

# ============================================================
# CHECK 4: Configuration Hygiene
# ============================================================
print_section "Configuration Hygiene"

# Check for .env files that shouldn't be committed
if find "${PROJECT_PATH}" -name ".env" -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/.venv/*" | grep -q .; then
    fail ".env file(s) found - ensure they're in .gitignore"
else
    pass "No .env files in tracked directories"
fi

# Check .gitignore exists
if [[ -f "${PROJECT_PATH}/.gitignore" ]]; then
    pass ".gitignore exists"

    # Check for common sensitive patterns
    PATTERNS=(".env" "*.key" "*.pem" "credentials" "secrets")
    MISSING_PATTERNS=()

    for pattern in "${PATTERNS[@]}"; do
        if ! grep -q "${pattern}" "${PROJECT_PATH}/.gitignore" 2>/dev/null; then
            MISSING_PATTERNS+=("${pattern}")
        fi
    done

    if [[ ${#MISSING_PATTERNS[@]} -gt 0 ]]; then
        warn ".gitignore missing patterns: ${MISSING_PATTERNS[*]}"
    else
        pass ".gitignore contains sensitive patterns"
    fi
else
    fail "No .gitignore file found"
fi

# Check for hardcoded localhost/dev URLs in config
if grep -r "localhost\|127\.0\.0\.1\|0\.0\.0\.0" "${PROJECT_PATH}" \
    --include="*.json" --include="*.yml" --include="*.yaml" --include="*.toml" \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor \
    2>/dev/null | grep -v "test\|spec\|mock" | head -5 | grep -q .; then
    warn "Hardcoded localhost references found in config files"
else
    pass "No hardcoded localhost in config files"
fi

# ============================================================
# CHECK 5: Documentation (full mode only)
# ============================================================
if [[ "$MODE" == "full" ]]; then
    print_section "Documentation"

    # README
    if [[ -f "${PROJECT_PATH}/README.md" ]] || [[ -f "${PROJECT_PATH}/README" ]]; then
        pass "README exists"
    else
        fail "No README found"
    fi

    # LICENSE
    if [[ -f "${PROJECT_PATH}/LICENSE" ]] || [[ -f "${PROJECT_PATH}/LICENSE.md" ]]; then
        pass "LICENSE file exists"
    else
        warn "No LICENSE file found"
    fi

    # SECURITY.md
    if [[ -f "${PROJECT_PATH}/SECURITY.md" ]] || [[ -f "${PROJECT_PATH}/.github/SECURITY.md" ]]; then
        pass "SECURITY.md exists"
    else
        warn "No SECURITY.md - consider adding vulnerability reporting guidelines"
    fi

    # CONTRIBUTING.md
    if [[ -f "${PROJECT_PATH}/CONTRIBUTING.md" ]] || [[ -f "${PROJECT_PATH}/.github/CONTRIBUTING.md" ]]; then
        pass "CONTRIBUTING.md exists"
    else
        skip "CONTRIBUTING.md (optional for private projects)"
    fi

    # CHANGELOG
    if [[ -f "${PROJECT_PATH}/CHANGELOG.md" ]] || [[ -f "${PROJECT_PATH}/CHANGELOG" ]]; then
        pass "CHANGELOG exists"
    else
        warn "No CHANGELOG found"
    fi
fi

# ============================================================
# CHECK 6: CI/CD Configuration (full mode only)
# ============================================================
if [[ "$MODE" == "full" ]]; then
    print_section "CI/CD Configuration"

    CI_FOUND=false

    if [[ -d "${PROJECT_PATH}/.github/workflows" ]] && ls "${PROJECT_PATH}/.github/workflows"/*.yml &>/dev/null; then
        pass "GitHub Actions workflows found"
        CI_FOUND=true
    fi

    if [[ -f "${PROJECT_PATH}/.gitlab-ci.yml" ]]; then
        pass "GitLab CI configuration found"
        CI_FOUND=true
    fi

    if [[ -f "${PROJECT_PATH}/Jenkinsfile" ]]; then
        pass "Jenkins pipeline found"
        CI_FOUND=true
    fi

    if [[ -f "${PROJECT_PATH}/.circleci/config.yml" ]]; then
        pass "CircleCI configuration found"
        CI_FOUND=true
    fi

    if [[ "$CI_FOUND" == false ]]; then
        warn "No CI/CD configuration detected"
    fi
fi

# ============================================================
# CHECK 7: Health Check Endpoint (full mode only)
# ============================================================
if [[ "$MODE" == "full" ]]; then
    print_section "Health & Monitoring"

    # Look for health check patterns
    if grep -r "health\|liveness\|readiness" "${PROJECT_PATH}" \
        --include="*.go" --include="*.py" --include="*.js" --include="*.ts" --include="*.rb" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor --exclude-dir=.venv \
        2>/dev/null | head -1 | grep -q .; then
        pass "Health check endpoint pattern found"
    else
        warn "No health check endpoint detected"
    fi

    # Look for logging setup
    if grep -r "logger\|logging\|winston\|pino\|log4j\|logrus\|zap" "${PROJECT_PATH}" \
        --include="*.go" --include="*.py" --include="*.js" --include="*.ts" --include="*.rb" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor --exclude-dir=.venv \
        2>/dev/null | head -1 | grep -q .; then
        pass "Structured logging detected"
    else
        warn "No structured logging library detected"
    fi
fi

# ============================================================
# GENERATE MARKDOWN REPORT
# ============================================================
generate_markdown_report() {
    local PROJECT_NAME
    PROJECT_NAME=$(basename "$(cd "${PROJECT_PATH}" && pwd)")

    cat > "${REPORT_FILE}" << EOF
# Security Audit Report

**Project:** ${PROJECT_NAME}
**Date:** ${DATE_STAMP}
**Audit Mode:** ${MODE}
**Auditor:** Claude Code (production-ready skill)

## Executive Summary

- **Total Checks:** ${TOTAL_CHECKS}
- **Passed:** ${PASSED_CHECKS}
- **Failed:** ${FAILED_CHECKS}
- **Warnings:** ${WARNINGS}

## Tools Used

| Tool | Purpose |
|------|---------|
EOF

    # Add tools used
    if check_tool gitleaks; then
        echo "| gitleaks | Secret detection |" >> "${REPORT_FILE}"
    fi
    if check_tool grype; then
        echo "| grype | Vulnerability scanning |" >> "${REPORT_FILE}"
    fi
    if check_tool syft; then
        echo "| syft | SBOM generation |" >> "${REPORT_FILE}"
    fi
    if check_tool trufflehog; then
        echo "| trufflehog | Deep secret scanning |" >> "${REPORT_FILE}"
    fi

    cat >> "${REPORT_FILE}" << EOF

## Findings Summary

### Checks Performed

| Check | Status |
|-------|--------|
| Secret Scanning | $(if [[ -f "${OUTPUT_DIR}/secrets-${TIMESTAMP}.json" ]] && [[ $(cat "${OUTPUT_DIR}/secrets-${TIMESTAMP}.json" 2>/dev/null | wc -c) -lt 10 ]]; then echo "✅ Passed"; else echo "⚠️ Review needed"; fi) |
| Vulnerability Scan | $(if [[ -f "${OUTPUT_DIR}/vulnerabilities-${TIMESTAMP}.json" ]]; then echo "✅ Completed"; else echo "⚠️ Not run"; fi) |
| Configuration Check | ✅ Completed |
EOF

    if [[ "$MODE" != "quick" ]]; then
        cat >> "${REPORT_FILE}" << EOF
| SBOM Generation | $(if [[ -f "${OUTPUT_DIR}/sbom-${TIMESTAMP}.json" ]]; then echo "✅ Generated"; else echo "⚠️ Not generated"; fi) |
EOF
    fi

    if [[ "$MODE" == "full" ]]; then
        cat >> "${REPORT_FILE}" << EOF
| Documentation Review | ✅ Completed |
| CI/CD Configuration | ✅ Completed |
| Health & Monitoring | ✅ Completed |
EOF
    fi

    cat >> "${REPORT_FILE}" << EOF

## Detailed Results

### Secret Scanning
$(if [[ -f "${OUTPUT_DIR}/secrets-${TIMESTAMP}.json" ]]; then echo "Results saved to: \`${OUTPUT_DIR}/secrets-${TIMESTAMP}.json\`"; else echo "No scan results available."; fi)

### Vulnerability Scanning
$(if [[ -f "${OUTPUT_DIR}/vulnerabilities-${TIMESTAMP}.json" ]]; then echo "Results saved to: \`${OUTPUT_DIR}/vulnerabilities-${TIMESTAMP}.json\`"; else echo "No scan results available."; fi)
EOF

    if [[ "$MODE" != "quick" ]] && [[ -f "${OUTPUT_DIR}/sbom-${TIMESTAMP}.json" ]]; then
        cat >> "${REPORT_FILE}" << EOF

### Software Bill of Materials (SBOM)
SBOM generated and saved to: \`${OUTPUT_DIR}/sbom-${TIMESTAMP}.json\`
EOF
    fi

    cat >> "${REPORT_FILE}" << EOF

## Recommendations

1. Address any failed checks before production deployment
2. Review all warnings and assess risk
3. Re-run audit after making fixes
4. Consider setting up automated security scanning in CI/CD

## Next Steps

- [ ] Fix critical vulnerabilities
- [ ] Review and remediate high-severity issues
- [ ] Update dependencies with known fixes
- [ ] Re-run audit after fixes

---
*Generated by production-ready skill v2.0.0*
*Report location: ${REPORT_FILE}*
EOF
}

# Generate the markdown report
generate_markdown_report

# ============================================================
# SUMMARY
# ============================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  AUDIT SUMMARY${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Total Checks:  ${TOTAL_CHECKS}"
echo -e "  ${GREEN}Passed:${NC}        ${PASSED_CHECKS}"
echo -e "  ${RED}Failed:${NC}        ${FAILED_CHECKS}"
echo -e "  ${YELLOW}Warnings:${NC}      ${WARNINGS}"
echo ""
echo -e "  Results saved to: ${OUTPUT_DIR}/"
echo -e "  ${BLUE}Report:${NC}        ${REPORT_FILE}"
echo ""

# Exit with appropriate code
if [[ $FAILED_CHECKS -gt 0 ]]; then
    echo -e "${RED}❌ Audit FAILED - address issues before production deployment${NC}"
    exit 1
else
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Audit PASSED with warnings - review before deployment${NC}"
    else
        echo -e "${GREEN}✅ Audit PASSED - project is production ready!${NC}"
    fi
    exit 0
fi
