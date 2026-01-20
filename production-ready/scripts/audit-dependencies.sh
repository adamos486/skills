#!/usr/bin/env bash
#
# audit-dependencies.sh - Check for vulnerable dependencies
#
# Usage: ./audit-dependencies.sh [project_path] [--severity critical|high|medium|low]
#

set -euo pipefail

PROJECT_PATH="${1:-.}"
SEVERITY="${2:-high}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "📦 Auditing dependencies in: ${PROJECT_PATH}"
echo "   Severity threshold: ${SEVERITY}"
echo ""

FOUND_ISSUES=false
AUDITS_RUN=0

# Universal: grype (works with any project)
if command -v grype &> /dev/null; then
    echo "Running grype (universal scanner)..."

    if grype dir:"${PROJECT_PATH}" --only-fixed --fail-on="${SEVERITY}" 2>/dev/null; then
        echo -e "${GREEN}✓ grype: No ${SEVERITY}+ vulnerabilities${NC}"
    else
        echo -e "${RED}✗ grype: ${SEVERITY}+ vulnerabilities found${NC}"
        FOUND_ISSUES=true
    fi
    ((AUDITS_RUN++))
    echo ""
fi

# Node.js / npm
if [[ -f "${PROJECT_PATH}/package.json" ]]; then
    echo "Detected: Node.js project"

    if command -v npm &> /dev/null; then
        echo "Running npm audit..."
        if npm audit --prefix="${PROJECT_PATH}" --audit-level="${SEVERITY}" 2>/dev/null; then
            echo -e "${GREEN}✓ npm audit: Passed${NC}"
        else
            echo -e "${RED}✗ npm audit: Vulnerabilities found${NC}"
            FOUND_ISSUES=true
        fi
        ((AUDITS_RUN++))
    fi
    echo ""
fi

# Python
if [[ -f "${PROJECT_PATH}/requirements.txt" ]] || [[ -f "${PROJECT_PATH}/pyproject.toml" ]]; then
    echo "Detected: Python project"

    if command -v pip-audit &> /dev/null; then
        echo "Running pip-audit..."

        REQ_FILE=""
        if [[ -f "${PROJECT_PATH}/requirements.txt" ]]; then
            REQ_FILE="${PROJECT_PATH}/requirements.txt"
        fi

        if [[ -n "$REQ_FILE" ]]; then
            if pip-audit -r "${REQ_FILE}" 2>/dev/null; then
                echo -e "${GREEN}✓ pip-audit: Passed${NC}"
            else
                echo -e "${RED}✗ pip-audit: Vulnerabilities found${NC}"
                FOUND_ISSUES=true
            fi
        else
            if (cd "${PROJECT_PATH}" && pip-audit 2>/dev/null); then
                echo -e "${GREEN}✓ pip-audit: Passed${NC}"
            else
                echo -e "${RED}✗ pip-audit: Vulnerabilities found${NC}"
                FOUND_ISSUES=true
            fi
        fi
        ((AUDITS_RUN++))
    else
        echo -e "${YELLOW}⚠ pip-audit not installed: pip install pip-audit${NC}"
    fi
    echo ""
fi

# Rust / Cargo
if [[ -f "${PROJECT_PATH}/Cargo.toml" ]]; then
    echo "Detected: Rust project"

    if command -v cargo-audit &> /dev/null || command -v cargo &> /dev/null; then
        echo "Running cargo audit..."
        if (cd "${PROJECT_PATH}" && cargo audit 2>/dev/null); then
            echo -e "${GREEN}✓ cargo audit: Passed${NC}"
        else
            echo -e "${RED}✗ cargo audit: Vulnerabilities found${NC}"
            FOUND_ISSUES=true
        fi
        ((AUDITS_RUN++))
    else
        echo -e "${YELLOW}⚠ cargo-audit not installed: cargo install cargo-audit${NC}"
    fi
    echo ""
fi

# Go
if [[ -f "${PROJECT_PATH}/go.mod" ]]; then
    echo "Detected: Go project"

    if command -v govulncheck &> /dev/null; then
        echo "Running govulncheck..."
        if (cd "${PROJECT_PATH}" && govulncheck ./... 2>/dev/null); then
            echo -e "${GREEN}✓ govulncheck: Passed${NC}"
        else
            echo -e "${RED}✗ govulncheck: Vulnerabilities found${NC}"
            FOUND_ISSUES=true
        fi
        ((AUDITS_RUN++))
    else
        echo -e "${YELLOW}⚠ govulncheck not installed: go install golang.org/x/vuln/cmd/govulncheck@latest${NC}"
    fi
    echo ""
fi

# Ruby / Bundler
if [[ -f "${PROJECT_PATH}/Gemfile" ]]; then
    echo "Detected: Ruby project"

    if command -v bundle-audit &> /dev/null; then
        echo "Running bundle-audit..."
        if (cd "${PROJECT_PATH}" && bundle-audit check --update 2>/dev/null); then
            echo -e "${GREEN}✓ bundle-audit: Passed${NC}"
        else
            echo -e "${RED}✗ bundle-audit: Vulnerabilities found${NC}"
            FOUND_ISSUES=true
        fi
        ((AUDITS_RUN++))
    else
        echo -e "${YELLOW}⚠ bundle-audit not installed: gem install bundle-audit${NC}"
    fi
    echo ""
fi

# Summary
echo "─────────────────────────────────────────"
if [[ $AUDITS_RUN -eq 0 ]]; then
    echo -e "${YELLOW}⚠ No audit tools available or no recognized project files${NC}"
    echo "  Install grype for universal scanning: brew install grype"
    exit 2
fi

if [[ "$FOUND_ISSUES" == true ]]; then
    echo -e "${RED}❌ Dependency audit completed - vulnerabilities found!${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Dependency audit completed - no ${SEVERITY}+ issues${NC}"
    exit 0
fi
