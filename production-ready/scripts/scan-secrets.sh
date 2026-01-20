#!/usr/bin/env bash
#
# scan-secrets.sh - Scan for hardcoded secrets and credentials
#
# Usage: ./scan-secrets.sh [project_path] [--deep]
#
# Options:
#   --deep    Use trufflehog for deeper scanning (slower, more thorough)
#

set -euo pipefail

PROJECT_PATH="${1:-.}"
DEEP_SCAN=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --deep)
            DEEP_SCAN=true
            shift
            ;;
    esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔐 Scanning for secrets in: ${PROJECT_PATH}"
echo ""

FOUND_ISSUES=false

# Primary: gitleaks (fast, CI-friendly)
if command -v gitleaks &> /dev/null; then
    echo "Running gitleaks..."

    if gitleaks detect --source="${PROJECT_PATH}" --no-banner -v 2>/dev/null; then
        echo -e "${GREEN}✓ gitleaks: No secrets found${NC}"
    else
        echo -e "${RED}✗ gitleaks: Potential secrets detected!${NC}"
        FOUND_ISSUES=true
    fi
else
    echo -e "${YELLOW}⚠ gitleaks not installed${NC}"
    echo "  Install: brew install gitleaks"
fi

# Deep scan with trufflehog (optional)
if [[ "$DEEP_SCAN" == true ]]; then
    echo ""
    echo "Running deep scan with trufflehog..."

    if command -v trufflehog &> /dev/null; then
        if trufflehog filesystem "${PROJECT_PATH}" --only-verified 2>/dev/null | head -20; then
            echo -e "${GREEN}✓ trufflehog: No verified secrets found${NC}"
        else
            echo -e "${YELLOW}⚠ trufflehog: Check output for potential secrets${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ trufflehog not installed${NC}"
        echo "  Install: brew install trufflehog"
    fi
fi

# Fallback: Basic pattern matching
echo ""
echo "Running basic pattern checks..."

PATTERNS=(
    "password\s*=\s*['\"][^'\"]+['\"]"
    "api[_-]?key\s*=\s*['\"][^'\"]+['\"]"
    "secret[_-]?key\s*=\s*['\"][^'\"]+['\"]"
    "aws[_-]?access[_-]?key"
    "AKIA[0-9A-Z]{16}"  # AWS Access Key ID
    "-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----"
    "ghp_[a-zA-Z0-9]{36}"  # GitHub Personal Access Token
    "sk-[a-zA-Z0-9]{48}"   # OpenAI API Key
)

for pattern in "${PATTERNS[@]}"; do
    if grep -rE "${pattern}" "${PROJECT_PATH}" \
        --include="*.py" --include="*.js" --include="*.ts" --include="*.go" \
        --include="*.rb" --include="*.java" --include="*.env*" --include="*.yml" \
        --include="*.yaml" --include="*.json" --include="*.toml" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor \
        --exclude-dir=.venv --exclude-dir=__pycache__ \
        2>/dev/null | grep -v "test\|spec\|mock\|example\|sample" | head -3; then
        echo -e "${RED}✗ Found pattern: ${pattern}${NC}"
        FOUND_ISSUES=true
    fi
done

if [[ "$FOUND_ISSUES" == false ]]; then
    echo -e "${GREEN}✓ Basic patterns: No obvious secrets found${NC}"
fi

echo ""
if [[ "$FOUND_ISSUES" == true ]]; then
    echo -e "${RED}❌ Secret scan completed - issues found!${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Secret scan completed - no issues found${NC}"
    exit 0
fi
