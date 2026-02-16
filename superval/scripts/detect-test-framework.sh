#!/bin/bash
# detect-test-framework.sh
# Detect available test frameworks and quality tools in the project.
# Exit 0 if a test framework is found, exit 1 if none detected.
#
# Usage: ./detect-test-framework.sh [project-dir]

set -euo pipefail

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "ERROR: Directory not found: $PROJECT_DIR"
  exit 2
fi

cd "$PROJECT_DIR"

# Output format: KEY=VALUE pairs

# ============================================================
# Stack Detection
# ============================================================

STACK="unknown"

if [ -f "package.json" ]; then
  if [ -f "tsconfig.json" ]; then
    STACK="typescript"
  else
    STACK="javascript"
  fi
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
  STACK="python"
elif [ -f "go.mod" ]; then
  STACK="go"
elif [ -f "Cargo.toml" ]; then
  STACK="rust"
elif [ -f "Gemfile" ]; then
  STACK="ruby"
elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
  STACK="java"
fi

echo "STACK=$STACK"

# ============================================================
# Package Manager Detection (Node.js)
# ============================================================

if [ "$STACK" = "typescript" ] || [ "$STACK" = "javascript" ]; then
  if [ -f "pnpm-lock.yaml" ]; then
    echo "PACKAGE_MANAGER=pnpm"
  elif [ -f "yarn.lock" ]; then
    echo "PACKAGE_MANAGER=yarn"
  elif [ -f "bun.lockb" ]; then
    echo "PACKAGE_MANAGER=bun"
  else
    echo "PACKAGE_MANAGER=npm"
  fi
fi

# ============================================================
# Test Framework Detection
# ============================================================

TEST_FRAMEWORK="none"

case "$STACK" in
  typescript|javascript)
    # Check package.json for test frameworks
    if [ -f "package.json" ]; then
      if grep -q '"vitest"' package.json 2>/dev/null; then
        TEST_FRAMEWORK="vitest"
      elif grep -q '"jest"' package.json 2>/dev/null; then
        TEST_FRAMEWORK="jest"
      elif grep -q '"mocha"' package.json 2>/dev/null; then
        TEST_FRAMEWORK="mocha"
      elif grep -q '"ava"' package.json 2>/dev/null; then
        TEST_FRAMEWORK="ava"
      fi
    fi
    # Check for config files
    if [ "$TEST_FRAMEWORK" = "none" ]; then
      if [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]; then
        TEST_FRAMEWORK="vitest"
      elif [ -f "jest.config.ts" ] || [ -f "jest.config.js" ] || [ -f "jest.config.json" ]; then
        TEST_FRAMEWORK="jest"
      elif [ -f ".mocharc.yml" ] || [ -f ".mocharc.json" ]; then
        TEST_FRAMEWORK="mocha"
      fi
    fi
    ;;
  python)
    if [ -f "pyproject.toml" ] && grep -q "pytest" pyproject.toml 2>/dev/null; then
      TEST_FRAMEWORK="pytest"
    elif [ -f "pytest.ini" ] || [ -f "setup.cfg" ] && grep -q "pytest" setup.cfg 2>/dev/null; then
      TEST_FRAMEWORK="pytest"
    elif command -v pytest &>/dev/null; then
      TEST_FRAMEWORK="pytest"
    elif [ -d "tests" ]; then
      TEST_FRAMEWORK="unittest"
    fi
    ;;
  go)
    # Go always has built-in testing
    TEST_FRAMEWORK="go-test"
    ;;
  rust)
    # Rust always has built-in testing
    TEST_FRAMEWORK="cargo-test"
    ;;
  ruby)
    if [ -f "Gemfile" ] && grep -q "rspec" Gemfile 2>/dev/null; then
      TEST_FRAMEWORK="rspec"
    elif [ -f "Gemfile" ] && grep -q "minitest" Gemfile 2>/dev/null; then
      TEST_FRAMEWORK="minitest"
    fi
    ;;
  java)
    if [ -f "pom.xml" ] && grep -q "junit" pom.xml 2>/dev/null; then
      TEST_FRAMEWORK="junit"
    elif [ -f "build.gradle" ] && grep -q "junit" build.gradle 2>/dev/null; then
      TEST_FRAMEWORK="junit"
    fi
    ;;
esac

echo "TEST_FRAMEWORK=$TEST_FRAMEWORK"

# ============================================================
# E2E Framework Detection
# ============================================================

E2E_FRAMEWORK="none"

if [ -f "package.json" ]; then
  if grep -q '"playwright"' package.json 2>/dev/null || grep -q '"@playwright/test"' package.json 2>/dev/null; then
    E2E_FRAMEWORK="playwright"
  elif grep -q '"cypress"' package.json 2>/dev/null; then
    E2E_FRAMEWORK="cypress"
  fi
fi

if [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
  E2E_FRAMEWORK="playwright"
elif [ -f "cypress.config.ts" ] || [ -f "cypress.config.js" ]; then
  E2E_FRAMEWORK="cypress"
fi

echo "E2E_FRAMEWORK=$E2E_FRAMEWORK"

# ============================================================
# Quality Tool Detection
# ============================================================

LINTER="none"
FORMATTER="none"
TYPECHECKER="none"

case "$STACK" in
  typescript|javascript)
    # Linter
    if [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ] || [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ]; then
      LINTER="eslint"
    elif [ -f "biome.json" ]; then
      LINTER="biome"
    fi
    # Formatter
    if [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f ".prettierrc.js" ] || [ -f "prettier.config.js" ]; then
      FORMATTER="prettier"
    elif [ -f "biome.json" ]; then
      FORMATTER="biome"
    fi
    # Type checker
    if [ -f "tsconfig.json" ]; then
      TYPECHECKER="tsc"
    fi
    ;;
  python)
    if command -v ruff &>/dev/null || ([ -f "pyproject.toml" ] && grep -q "ruff" pyproject.toml 2>/dev/null); then
      LINTER="ruff"
    elif command -v pylint &>/dev/null; then
      LINTER="pylint"
    elif command -v flake8 &>/dev/null; then
      LINTER="flake8"
    fi
    if command -v black &>/dev/null || ([ -f "pyproject.toml" ] && grep -q "black" pyproject.toml 2>/dev/null); then
      FORMATTER="black"
    fi
    if command -v mypy &>/dev/null || ([ -f "pyproject.toml" ] && grep -q "mypy" pyproject.toml 2>/dev/null); then
      TYPECHECKER="mypy"
    elif command -v pyright &>/dev/null; then
      TYPECHECKER="pyright"
    fi
    ;;
  go)
    LINTER="go-vet"
    if command -v golangci-lint &>/dev/null; then
      LINTER="golangci-lint"
    fi
    FORMATTER="gofmt"
    TYPECHECKER="go-build"
    ;;
  rust)
    LINTER="clippy"
    FORMATTER="rustfmt"
    TYPECHECKER="cargo-check"
    ;;
esac

echo "LINTER=$LINTER"
echo "FORMATTER=$FORMATTER"
echo "TYPECHECKER=$TYPECHECKER"

# ============================================================
# Test Command Detection
# ============================================================

TEST_COMMAND="none"

case "$STACK" in
  typescript|javascript)
    if [ -f "package.json" ]; then
      # Check for test script in package.json
      if grep -q '"test"' package.json 2>/dev/null; then
        # Extract the actual command (rough parse)
        PM="npm"
        [ -f "pnpm-lock.yaml" ] && PM="pnpm"
        [ -f "yarn.lock" ] && PM="yarn"
        TEST_COMMAND="$PM test"
      fi
    fi
    ;;
  python)
    case "$TEST_FRAMEWORK" in
      pytest) TEST_COMMAND="pytest" ;;
      unittest) TEST_COMMAND="python -m unittest discover" ;;
    esac
    ;;
  go)
    TEST_COMMAND="go test ./..."
    ;;
  rust)
    TEST_COMMAND="cargo test"
    ;;
esac

echo "TEST_COMMAND=$TEST_COMMAND"

# ============================================================
# Existing Test File Count
# ============================================================

TEST_FILE_COUNT=0

case "$STACK" in
  typescript|javascript)
    TEST_FILE_COUNT=$(find . -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.test.js" -o -name "*.spec.ts" -o -name "*.spec.js" | grep -v node_modules | wc -l | tr -d ' ')
    ;;
  python)
    TEST_FILE_COUNT=$(find . -name "test_*.py" -o -name "*_test.py" | grep -v __pycache__ | grep -v .venv | wc -l | tr -d ' ')
    ;;
  go)
    TEST_FILE_COUNT=$(find . -name "*_test.go" | wc -l | tr -d ' ')
    ;;
  rust)
    TEST_FILE_COUNT=$(find . -path ./target -prune -o -name "*.rs" -print | xargs grep -l '#\[test\]' 2>/dev/null | wc -l | tr -d ' ')
    ;;
esac

echo "TEST_FILE_COUNT=$TEST_FILE_COUNT"

# ============================================================
# Verdict
# ============================================================

if [ "$TEST_FRAMEWORK" = "none" ]; then
  echo ""
  echo "VERDICT=NO_TEST_FRAMEWORK"
  echo "ACTION=Run '/superplan bootstrap the testing pyramid for me'"
  exit 1
else
  echo ""
  echo "VERDICT=READY"
  exit 0
fi
