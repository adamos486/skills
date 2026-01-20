#!/usr/bin/env bash
#
# generate-sbom.sh - Generate Software Bill of Materials
#
# Usage: ./generate-sbom.sh [project_path] [--format cyclonedx|spdx]
#

set -euo pipefail

PROJECT_PATH="${1:-.}"
FORMAT="cyclonedx-json"

# Parse arguments
for arg in "$@"; do
    case $arg in
        --format=*)
            FMT="${arg#*=}"
            case $FMT in
                cyclonedx) FORMAT="cyclonedx-json" ;;
                spdx) FORMAT="spdx-json" ;;
                *) echo "Unknown format: $FMT"; exit 1 ;;
            esac
            shift
            ;;
    esac
done

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "📋 Generating SBOM for: ${PROJECT_PATH}"
echo "   Format: ${FORMAT}"
echo ""

OUTPUT_DIR="${PROJECT_PATH}/sbom"
mkdir -p "${OUTPUT_DIR}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="${OUTPUT_DIR}/sbom-${TIMESTAMP}.json"

if command -v syft &> /dev/null; then
    echo "Running syft..."

    if syft dir:"${PROJECT_PATH}" -o "${FORMAT}=${OUTPUT_FILE}" 2>/dev/null; then
        echo -e "${GREEN}✓ SBOM generated: ${OUTPUT_FILE}${NC}"

        # Show summary
        if command -v jq &> /dev/null; then
            if [[ "$FORMAT" == "cyclonedx-json" ]]; then
                COMPONENT_COUNT=$(jq '.components | length' "${OUTPUT_FILE}" 2>/dev/null || echo "?")
                echo ""
                echo "Summary:"
                echo "  Components: ${COMPONENT_COUNT}"
            fi
        fi

        echo ""
        echo -e "${GREEN}✅ SBOM generation complete${NC}"
        exit 0
    else
        echo -e "${RED}✗ SBOM generation failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ syft not installed${NC}"
    echo ""
    echo "Install syft:"
    echo "  macOS:  brew install syft"
    echo "  Linux:  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin"
    echo ""

    # Fallback: Try cdxgen if available
    if command -v cdxgen &> /dev/null; then
        echo "Trying cdxgen as fallback..."
        if cdxgen -o "${OUTPUT_FILE}" "${PROJECT_PATH}" 2>/dev/null; then
            echo -e "${GREEN}✓ SBOM generated with cdxgen: ${OUTPUT_FILE}${NC}"
            exit 0
        fi
    fi

    exit 2
fi
