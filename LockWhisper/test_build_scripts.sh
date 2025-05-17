#!/bin/bash

# Test script to verify build scripts are working correctly
# Enhanced version with comprehensive testing

echo "Testing LockWhisper build scripts..."
echo "===================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Function to run test and check result
run_test() {
    local description=$1
    local command=$2
    local skip_if_missing=${3:-false}
    
    echo -n "Testing: $description... "
    
    # Check if we should skip this test
    if [ "$skip_if_missing" = true ]; then
        # Extract the command/tool name for checking
        local tool_name=$(echo "$command" | awk '{print $1}')
        if ! command -v "$tool_name" &> /dev/null; then
            echo -e "${YELLOW}SKIPPED${NC} (tool not available)"
            ((TESTS_SKIPPED++))
            return
        fi
    fi
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
        echo "  Command: $command"
        ((TESTS_FAILED++))
    fi
}

# Function to display section header
section_header() {
    echo ""
    echo -e "${BOLD}$1${NC}"
    echo "$1" | sed 's/./-/g'
}

# Start time
START_TIME=$(date +%s)

# Test shell script
section_header "1. Testing shell script (build_scripts.sh)"
run_test "Script exists" "test -f build_scripts.sh"
run_test "Script is executable" "test -x build_scripts.sh"
run_test "Script has no syntax errors" "bash -n build_scripts.sh"
run_test "Help command works" "./build_scripts.sh -h"
run_test "Script can handle invalid command" "./build_scripts.sh invalid_command 2>&1 | grep -q 'Unknown command'"
run_test "Script can handle invalid option" "./build_scripts.sh build --invalid 2>&1 | grep -q 'Unknown option'"

# Test Makefile
section_header "2. Testing Makefile"
run_test "Makefile exists" "test -f Makefile"
run_test "Makefile syntax is valid" "make -n help"
run_test "Make help works" "make help"
run_test "Makefile has build target" "make -n build"
run_test "Makefile has test target" "make -n test"
run_test "Makefile has clean target" "make -n clean"

# Test package.json
section_header "3. Testing package.json"
run_test "package.json exists" "test -f package.json"
run_test "package.json is valid JSON" "python3 -m json.tool package.json > /dev/null"
run_test "npm is available" "command -v npm" true
run_test "npm scripts list works" "npm run --silent" true

# Test documentation
section_header "4. Testing documentation"
run_test "README exists" "test -f BUILD_SCRIPTS_README.md"
run_test "README is not empty" "test -s BUILD_SCRIPTS_README.md"
run_test "CLI usage documented" "grep -q 'build_scripts.sh' BUILD_SCRIPTS_README.md"
run_test "Makefile usage documented" "grep -q 'make' BUILD_SCRIPTS_README.md"

# Test build tools availability
section_header "5. Testing build tools"
run_test "xcodebuild is available" "command -v xcodebuild"
run_test "xcbeautify is available" "command -v xcbeautify" true
run_test "xcpretty is available" "command -v xcpretty" true
run_test "Project file exists" "test -f LockWhisper.xcodeproj/project.pbxproj"

# Test script features
section_header "6. Testing script features"
run_test "Quiet mode option exists" "./build_scripts.sh build -h | grep -q -- '--quiet'"
run_test "Verbose mode option exists" "./build_scripts.sh build -h | grep -q -- '--verbose'"
run_test "Parallel build option exists" "./build_scripts.sh build -h | grep -q -- '--parallel'"
run_test "Clean derived data option exists" "./build_scripts.sh build -h | grep -q -- '--clean-derived'"
run_test "Simulator option exists" "./build_scripts.sh build -h | grep -q -- '--simulator'"
run_test "Scheme option exists" "./build_scripts.sh build -h | grep -q -- '--scheme'"

# Test new commands
section_header "7. Testing new commands"
run_test "Analyze command exists" "./build_scripts.sh -h | grep -q 'analyze'"
run_test "Coverage command exists" "./build_scripts.sh -h | grep -q 'coverage'"
run_test "Docs command exists" "./build_scripts.sh -h | grep -q 'docs'"

# Test environment
section_header "8. Testing environment"
run_test "Build directory can be created" "mkdir -p build && rmdir build"
run_test "Derived data directory is writable" "touch ~/Library/Developer/Xcode/DerivedData/.test && rm ~/Library/Developer/Xcode/DerivedData/.test"

# Additional checks
section_header "9. Additional checks"
run_test "Script uses proper error handling" "grep -q 'set -euo pipefail' build_scripts.sh"
run_test "Script has color output" "grep -q 'GREEN=' build_scripts.sh"
run_test "Script has timestamp output" "grep -q 'date' build_scripts.sh"

# End time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Summary
echo ""
echo "===================================="
echo -e "${BOLD}Test Summary${NC}"
echo "===================================="
echo -e "Tests passed:  ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests failed:  ${RED}${TESTS_FAILED}${NC}"
echo -e "Tests skipped: ${YELLOW}${TESTS_SKIPPED}${NC}"
echo -e "Total tests:   $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))"
echo -e "Duration:      ${duration}s"
echo ""

# Recommendations
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Some tests failed!${NC}"
    echo "Please check the failed tests above."
    echo ""
fi

if [ $TESTS_SKIPPED -gt 0 ]; then
    echo -e "${YELLOW}Some tests were skipped:${NC}"
    if ! command -v xcbeautify &> /dev/null; then
        echo "  - Install xcbeautify: brew install xcbeautify"
    fi
    if ! command -v xcpretty &> /dev/null; then
        echo "  - Install xcpretty: gem install xcpretty"
    fi
    if ! command -v npm &> /dev/null; then
        echo "  - Install Node.js and npm: brew install node"
    fi
    echo ""
fi

echo -e "${BOLD}Quick build test:${NC}"
echo "  ./build_scripts.sh build -q"
echo ""
echo -e "${BOLD}Full test suite:${NC}"
echo "  ./build_scripts.sh test"
echo ""
echo -e "${BOLD}Commands with different formatters:${NC}"
echo "  ./build_scripts.sh build              # With xcbeautify"
echo "  ./build_scripts.sh build --no-beautify # Raw output"
echo "  make build                           # With xcbeautify via Makefile"
echo "  npm run build                        # With package.json scripts"
echo ""

# Exit code
exit $TESTS_FAILED