#!/bin/bash

# Test script to verify build scripts are working correctly

echo "Testing LockWhisper build scripts..."
echo "===================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Function to run test and check result
run_test() {
    local description=$1
    local command=$2
    
    echo -n "Testing: $description... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        echo "  Command: $command"
    fi
}

# Test shell script
echo "1. Testing shell script (build_scripts.sh)"
echo "----------------------------------------"
run_test "Script exists" "test -f build_scripts.sh"
run_test "Script is executable" "test -x build_scripts.sh"
run_test "Help command" "./build_scripts.sh -h"
echo ""

# Test Makefile
echo "2. Testing Makefile"
echo "------------------"
run_test "Makefile exists" "test -f Makefile"
run_test "Make help" "make help"
echo ""

# Test package.json
echo "3. Testing package.json"
echo "----------------------"
run_test "package.json exists" "test -f package.json"
run_test "npm scripts" "npm run --silent"
echo ""

# Test documentation
echo "4. Testing documentation"
echo "-----------------------"
run_test "README exists" "test -f BUILD_SCRIPTS_README.md"
echo ""

# Summary
echo "===================================="
echo "Test completed!"
echo ""
echo "To run a full build test:"
echo "  ./build_scripts.sh build"
echo "  make build"
echo "  npm run build"
echo ""
echo "For quiet mode:"
echo "  ./build_scripts.sh build -q"
echo "  make quiet-build"
echo "  npm run build:quiet"