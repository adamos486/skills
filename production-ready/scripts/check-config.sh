#!/usr/bin/env bash
#
# check-config.sh - Validate configuration hygiene
#
# Usage: ./check-config.sh [project_path]
#

set -euo pipefail

PROJECT_PATH="${1:-.}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "⚙️  Checking configuration hygiene: ${PROJECT_PATH}"
echo ""

ISSUES=0
WARNINGS=0

pass() {
    echo -e "  ${GREEN}✓${NC} $1"
}

fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((ISSUES++))
}

warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# ─────────────────────────────────────────
# .gitignore checks
# ─────────────────────────────────────────
echo "Checking .gitignore..."

if [[ -f "${PROJECT_PATH}/.gitignore" ]]; then
    pass ".gitignore exists"

    REQUIRED_PATTERNS=(
        ".env"
        "*.key"
        "*.pem"
    )

    RECOMMENDED_PATTERNS=(
        "node_modules"
        "__pycache__"
        ".venv"
        "*.log"
        ".DS_Store"
        "coverage"
        "dist"
        "build"
    )

    for pattern in "${REQUIRED_PATTERNS[@]}"; do
        if grep -qF "${pattern}" "${PROJECT_PATH}/.gitignore" 2>/dev/null; then
            pass "Ignores: ${pattern}"
        else
            fail "Missing from .gitignore: ${pattern}"
        fi
    done

    for pattern in "${RECOMMENDED_PATTERNS[@]}"; do
        if grep -qF "${pattern}" "${PROJECT_PATH}/.gitignore" 2>/dev/null; then
            pass "Ignores: ${pattern}"
        fi
    done
else
    fail "No .gitignore file"
fi

echo ""

# ─────────────────────────────────────────
# Environment file checks
# ─────────────────────────────────────────
echo "Checking environment files..."

# Look for .env files
ENV_FILES=$(find "${PROJECT_PATH}" -name ".env" -o -name ".env.*" \
    -not -path "*/.git/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/.venv/*" \
    -not -path "*/vendor/*" \
    2>/dev/null || true)

if [[ -n "$ENV_FILES" ]]; then
    while IFS= read -r envfile; do
        if [[ -f "$envfile" ]]; then
            # Check if it's a template (contains placeholder patterns)
            if grep -qE "^[A-Z_]+=\s*$|<YOUR_|{{|CHANGEME|REPLACE_ME" "$envfile" 2>/dev/null; then
                pass "Template file: $envfile"
            elif [[ "$envfile" == *".example"* ]] || [[ "$envfile" == *".sample"* ]] || [[ "$envfile" == *".template"* ]]; then
                pass "Example file: $envfile"
            else
                warn "Real .env file found: $envfile (ensure it's in .gitignore)"
            fi
        fi
    done <<< "$ENV_FILES"
else
    pass "No .env files in tracked directories"
fi

# Check for .env.example
if [[ -f "${PROJECT_PATH}/.env.example" ]] || [[ -f "${PROJECT_PATH}/.env.sample" ]]; then
    pass ".env.example/.env.sample exists"
else
    warn "No .env.example - consider adding one for documentation"
fi

echo ""

# ─────────────────────────────────────────
# Hardcoded values check
# ─────────────────────────────────────────
echo "Checking for hardcoded values..."

# Localhost in config files
if grep -rE "(localhost|127\.0\.0\.1|0\.0\.0\.0)" "${PROJECT_PATH}" \
    --include="*.json" --include="*.yml" --include="*.yaml" --include="*.toml" --include="*.ini" \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor --exclude-dir=.venv \
    2>/dev/null | grep -vE "(test|spec|mock|example|sample|dev)" | head -1 | grep -q .; then
    warn "Hardcoded localhost found in config files"
else
    pass "No hardcoded localhost in config"
fi

# Hardcoded ports
if grep -rE ":\s*(3000|8080|5000|4000)\b" "${PROJECT_PATH}" \
    --include="*.json" --include="*.yml" --include="*.yaml" \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor \
    2>/dev/null | grep -vE "(test|spec|example)" | head -1 | grep -q .; then
    warn "Hardcoded ports found in config (consider using environment variables)"
else
    pass "No hardcoded ports in config"
fi

echo ""

# ─────────────────────────────────────────
# Docker configuration
# ─────────────────────────────────────────
if [[ -f "${PROJECT_PATH}/Dockerfile" ]]; then
    echo "Checking Dockerfile..."

    # Check for root user
    if grep -q "USER root" "${PROJECT_PATH}/Dockerfile" 2>/dev/null; then
        fail "Dockerfile runs as root"
    elif grep -q "^USER " "${PROJECT_PATH}/Dockerfile" 2>/dev/null; then
        pass "Dockerfile specifies non-root user"
    else
        warn "Dockerfile doesn't specify USER (defaults to root)"
    fi

    # Check for latest tag
    if grep -qE "FROM .+:latest" "${PROJECT_PATH}/Dockerfile" 2>/dev/null; then
        warn "Dockerfile uses :latest tag (pin to specific version)"
    else
        pass "Dockerfile uses pinned versions"
    fi

    # Check for .dockerignore
    if [[ -f "${PROJECT_PATH}/.dockerignore" ]]; then
        pass ".dockerignore exists"
    else
        warn "No .dockerignore file"
    fi

    echo ""
fi

# ─────────────────────────────────────────
# Summary
# ─────────────────────────────────────────
echo "─────────────────────────────────────────"
echo "Issues:   ${ISSUES}"
echo "Warnings: ${WARNINGS}"
echo ""

if [[ $ISSUES -gt 0 ]]; then
    echo -e "${RED}❌ Configuration check failed${NC}"
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Configuration check passed with warnings${NC}"
    exit 0
else
    echo -e "${GREEN}✅ Configuration check passed${NC}"
    exit 0
fi
