#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building Lambda deployment packages...${NC}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

build_lambda() {
  local SRC_DIR="$1"
  local OUT_ZIP="$2"
  local LAMBDA_NAME=$(basename "$SRC_DIR")

  echo -e "\n${YELLOW}Building ${LAMBDA_NAME}...${NC}"

  if [ ! -d "$SRC_DIR" ]; then
    echo -e "${RED}Error: Source directory $SRC_DIR does not exist${NC}"
    return 1
  fi

  # Create a temporary build directory
  local BUILD_DIR=$(mktemp -d)
  trap "rm -rf $BUILD_DIR" EXIT

  # Copy source files to build directory
  cp -r "$SRC_DIR"/* "$BUILD_DIR/"
  cd "$BUILD_DIR"

  # Install dependencies if requirements.txt exists
  if [ -f "requirements.txt" ]; then
    # Check if requirements file has actual dependencies
    if grep -q '^[^#]' requirements.txt; then
      echo "  Installing dependencies..."
      pip install -q -r requirements.txt -t . --upgrade
    else
      echo "  No dependencies to install"
    fi
  fi

  # Remove old zip if exists
  rm -f "$ROOT/$OUT_ZIP"

  # Create zip file excluding unnecessary files
  echo "  Creating deployment package..."
  zip -q -r "$ROOT/$OUT_ZIP" . \
    -x "*.pyc" \
    -x "*__pycache__/*" \
    -x "*.dist-info/*" \
    -x "requirements.txt"

  cd "$ROOT"

  # Validate the zip was created
  if [ -f "$OUT_ZIP" ]; then
    local SIZE=$(du -h "$OUT_ZIP" | cut -f1)
    echo -e "  ${GREEN}✓ Created $OUT_ZIP ($SIZE)${NC}"
  else
    echo -e "  ${RED}✗ Failed to create $OUT_ZIP${NC}"
    return 1
  fi
}

# Create artifacts directory
mkdir -p infra/artifacts

# Build all Lambda functions
build_lambda src/collector infra/artifacts/collector.zip
build_lambda src/weekly_report infra/artifacts/weekly_report.zip
build_lambda src/telegram_notifier infra/artifacts/telegram_notifier.zip

echo -e "\n${GREEN}Build complete!${NC}"
echo -e "\nCreated artifacts:"
ls -lh infra/artifacts/*.zip

