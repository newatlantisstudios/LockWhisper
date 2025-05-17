#!/bin/bash

# LockWhisper Build Scripts with xcbeautify and quiet mode support
# Enhanced version with better error handling and more features

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default values
QUIET_MODE=false
USE_XCBEAUTIFY=true
VERBOSE_MODE=false
PARALLEL_BUILDS=false
CLEAN_DERIVED_DATA=false

# Configuration
PROJECT_NAME="LockWhisper"
PROJECT_FILE="${PROJECT_NAME}.xcodeproj"
DEFAULT_SCHEME="${PROJECT_NAME}"
DEFAULT_SIMULATOR="iPhone 15"
BUILD_DIR="build"
DERIVED_DATA_DIR="${BUILD_DIR}/DerivedData"

# Exit on error in strict mode
set -euo pipefail

# Check if xcbeautify is installed
check_xcbeautify() {
    if ! command -v xcbeautify &> /dev/null; then
        echo -e "${YELLOW}Warning: xcbeautify is not installed.${NC}"
        echo "To install xcbeautify, run: brew install xcbeautify"
        echo "Falling back to raw xcodebuild output."
        USE_XCBEAUTIFY=false
    fi
}

# Check if xcpretty is installed as fallback
check_xcpretty() {
    if [ "$USE_XCBEAUTIFY" = false ] && command -v xcpretty &> /dev/null; then
        echo -e "${BLUE}Note: Using xcpretty as fallback formatter.${NC}"
        return 0
    fi
    return 1
}

# Print usage
usage() {
    echo -e "${BOLD}Usage: $0 [COMMAND] [OPTIONS]${NC}"
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo "  build       Build the project"
    echo "  test        Run tests"
    echo "  clean       Clean build folder"
    echo "  release     Build release configuration"
    echo "  archive     Create archive for distribution"
    echo "  analyze     Run static analysis"
    echo "  coverage    Generate test coverage report"
    echo "  docs        Generate documentation"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  -q, --quiet         Enable quiet mode (minimal output)"
    echo "  -v, --verbose       Enable verbose mode (detailed output)"
    echo "  --no-beautify       Disable xcbeautify (show raw xcodebuild output)"
    echo "  --parallel          Enable parallel builds"
    echo "  --clean-derived     Clean derived data before building"
    echo "  --simulator [name]  Specify simulator (default: ${DEFAULT_SIMULATOR})"
    echo "  --scheme [name]     Specify scheme (default: ${DEFAULT_SCHEME})"
    echo "  -h, --help          Show this help message"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  $0 build                    # Build with xcbeautify"
    echo "  $0 build -q                 # Build in quiet mode"
    echo "  $0 test --no-beautify       # Run tests without xcbeautify"
    echo "  $0 test --simulator \"iPhone 14 Pro\"  # Test on specific simulator"
    echo "  $0 build --parallel --clean-derived  # Parallel build with clean"
    exit 0
}

# Parse arguments
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

COMMAND=$1
shift

# Additional configuration
SIMULATOR_NAME="${DEFAULT_SIMULATOR}"
SCHEME_NAME="${DEFAULT_SCHEME}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE_MODE=true
            QUIET_MODE=false
            shift
            ;;
        --no-beautify)
            USE_XCBEAUTIFY=false
            shift
            ;;
        --parallel)
            PARALLEL_BUILDS=true
            shift
            ;;
        --clean-derived)
            CLEAN_DERIVED_DATA=true
            shift
            ;;
        --simulator)
            SIMULATOR_NAME="$2"
            shift 2
            ;;
        --scheme)
            SCHEME_NAME="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Set up xcodebuild base command
XCODEBUILD_BASE="xcodebuild -project ${PROJECT_FILE} -scheme ${SCHEME_NAME}"

# Set up build options
XCODEBUILD_OPTIONS=""
if [ "$QUIET_MODE" = true ]; then
    XCODEBUILD_OPTIONS="-quiet"
elif [ "$VERBOSE_MODE" = true ]; then
    XCODEBUILD_OPTIONS="-verbose"
fi

if [ "$PARALLEL_BUILDS" = true ]; then
    XCODEBUILD_OPTIONS="$XCODEBUILD_OPTIONS -parallelizeTargets"
fi

# Function to run xcodebuild with or without xcbeautify
run_xcodebuild() {
    local command=$1
    local show_progress=${2:-true}
    
    # Add derived data path
    command="$command -derivedDataPath $DERIVED_DATA_DIR"
    
    if [ "$QUIET_MODE" = true ]; then
        if [ "$show_progress" = true ]; then
            # Show simple progress indicator in quiet mode
            $command > /dev/null 2>&1 &
            local pid=$!
            echo -n "Working"
            while kill -0 $pid 2>/dev/null; do
                echo -n "."
                sleep 1
            done
            wait $pid
            local result=$?
            echo ""
            return $result
        else
            $command > /dev/null 2>&1
        fi
    elif [ "$USE_XCBEAUTIFY" = true ]; then
        $command | xcbeautify
    elif check_xcpretty; then
        $command | xcpretty --color
    else
        $command
    fi
}

# Function to clean derived data
clean_derived_data() {
    if [ "$CLEAN_DERIVED_DATA" = true ]; then
        echo -e "${YELLOW}Cleaning derived data...${NC}"
        rm -rf "$DERIVED_DATA_DIR"
        rm -rf ~/Library/Developer/Xcode/DerivedData/${PROJECT_NAME}-*
    fi
}

# Build function
build() {
    echo -e "${GREEN}Building ${PROJECT_NAME}...${NC}"
    
    clean_derived_data
    
    local build_cmd="$XCODEBUILD_BASE -configuration Debug build $XCODEBUILD_OPTIONS"
    
    if [ "$QUIET_MODE" = true ]; then
        if run_xcodebuild "$build_cmd"; then
            echo -e "${GREEN}✓ Build completed successfully${NC}"
        else
            echo -e "${RED}✗ Build failed${NC}"
            exit 1
        fi
    else
        if run_xcodebuild "$build_cmd" false; then
            echo -e "${GREEN}✓ Build completed successfully${NC}"
        else
            echo -e "${RED}✗ Build failed${NC}"
            exit 1
        fi
    fi
}

# Test function
test() {
    echo -e "${GREEN}Running tests...${NC}"
    
    local test_cmd="$XCODEBUILD_BASE test -destination 'platform=iOS Simulator,name=${SIMULATOR_NAME}' $XCODEBUILD_OPTIONS"
    
    if [ "$QUIET_MODE" = true ]; then
        if run_xcodebuild "$test_cmd"; then
            echo -e "${GREEN}✓ Tests passed${NC}"
        else
            echo -e "${RED}✗ Tests failed${NC}"
            exit 1
        fi
    else
        if run_xcodebuild "$test_cmd" false; then
            echo -e "${GREEN}✓ All tests passed${NC}"
        else
            echo -e "${RED}✗ Some tests failed${NC}"
            exit 1
        fi
    fi
}

# Clean function
clean() {
    echo -e "${GREEN}Cleaning build folder...${NC}"
    
    local clean_cmd="$XCODEBUILD_BASE clean $XCODEBUILD_OPTIONS"
    
    if [ "$QUIET_MODE" = true ]; then
        run_xcodebuild "$clean_cmd" false
        echo -e "${GREEN}✓ Clean completed${NC}"
    else
        run_xcodebuild "$clean_cmd" false
        echo -e "${GREEN}✓ Clean completed${NC}"
    fi
    
    # Also clean build directory
    echo -e "${YELLOW}Removing build directory...${NC}"
    rm -rf "$BUILD_DIR"
}

# Release build function
release() {
    echo -e "${GREEN}Building release configuration...${NC}"
    
    clean_derived_data
    
    local release_cmd="$XCODEBUILD_BASE -configuration Release build $XCODEBUILD_OPTIONS"
    
    if [ "$QUIET_MODE" = true ]; then
        if run_xcodebuild "$release_cmd"; then
            echo -e "${GREEN}✓ Release build completed successfully${NC}"
        else
            echo -e "${RED}✗ Release build failed${NC}"
            exit 1
        fi
    else
        if run_xcodebuild "$release_cmd" false; then
            echo -e "${GREEN}✓ Release build completed successfully${NC}"
        else
            echo -e "${RED}✗ Release build failed${NC}"
            exit 1
        fi
    fi
}

# Archive function
archive() {
    echo -e "${GREEN}Creating archive...${NC}"
    
    local archive_path="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
    local archive_cmd="$XCODEBUILD_BASE -configuration Release archive -archivePath $archive_path $XCODEBUILD_OPTIONS"
    
    # Clean before archiving
    clean_derived_data
    
    if [ "$QUIET_MODE" = true ]; then
        if run_xcodebuild "$archive_cmd"; then
            echo -e "${GREEN}✓ Archive created at: $archive_path${NC}"
        else
            echo -e "${RED}✗ Archive creation failed${NC}"
            exit 1
        fi
    else
        if run_xcodebuild "$archive_cmd" false; then
            echo -e "${GREEN}✓ Archive created at: $archive_path${NC}"
        else
            echo -e "${RED}✗ Archive creation failed${NC}"
            exit 1
        fi
    fi
}

# Analyze function
analyze() {
    echo -e "${GREEN}Running static analysis...${NC}"
    
    local analyze_cmd="$XCODEBUILD_BASE analyze $XCODEBUILD_OPTIONS"
    
    if [ "$QUIET_MODE" = true ]; then
        if run_xcodebuild "$analyze_cmd"; then
            echo -e "${GREEN}✓ Analysis completed${NC}"
        else
            echo -e "${RED}✗ Analysis failed${NC}"
            exit 1
        fi
    else
        if run_xcodebuild "$analyze_cmd" false; then
            echo -e "${GREEN}✓ Analysis completed successfully${NC}"
        else
            echo -e "${RED}✗ Analysis found issues${NC}"
            exit 1
        fi
    fi
}

# Coverage function
coverage() {
    echo -e "${GREEN}Generating test coverage report...${NC}"
    
    local coverage_cmd="$XCODEBUILD_BASE test -enableCodeCoverage YES -destination 'platform=iOS Simulator,name=${SIMULATOR_NAME}' $XCODEBUILD_OPTIONS"
    
    if run_xcodebuild "$coverage_cmd" false; then
        echo -e "${GREEN}✓ Coverage report generated${NC}"
        
        # Try to find and display coverage summary
        local coverage_file=$(find "$DERIVED_DATA_DIR" -name "*.xcresult" -type d | head -1)
        if [ -n "$coverage_file" ] && command -v xcrun &> /dev/null; then
            echo -e "${BLUE}Coverage summary:${NC}"
            xcrun xccov view --report "$coverage_file" 2>/dev/null | head -20 || true
        fi
    else
        echo -e "${RED}✗ Coverage generation failed${NC}"
        exit 1
    fi
}

# Documentation function
docs() {
    echo -e "${GREEN}Generating documentation...${NC}"
    
    if command -v jazzy &> /dev/null; then
        jazzy --module-name ${PROJECT_NAME} --output ${BUILD_DIR}/docs
        echo -e "${GREEN}✓ Documentation generated at: ${BUILD_DIR}/docs${NC}"
    elif command -v swift-doc &> /dev/null; then
        swift-doc generate ./LockWhisper --module-name ${PROJECT_NAME} --output ${BUILD_DIR}/docs
        echo -e "${GREEN}✓ Documentation generated at: ${BUILD_DIR}/docs${NC}"
    else
        echo -e "${YELLOW}No documentation generator found.${NC}"
        echo "Install jazzy: gem install jazzy"
        echo "Or swift-doc: brew install swift-doc"
        exit 1
    fi
}

# Main execution
echo -e "${BLUE}${PROJECT_NAME} Build System${NC}"
echo -e "${BLUE}$(date)${NC}"
echo ""

check_xcbeautify

case $COMMAND in
    build)
        build
        ;;
    test)
        test
        ;;
    clean)
        clean
        ;;
    release)
        release
        ;;
    archive)
        archive
        ;;
    analyze)
        analyze
        ;;
    coverage)
        coverage
        ;;
    docs)
        docs
        ;;
    *)
        if [ -z "$COMMAND" ]; then
            echo -e "${RED}Error: No command specified${NC}"
        else
            echo -e "${RED}Error: Unknown command: $COMMAND${NC}"
        fi
        usage
        ;;
esac

echo ""
echo -e "${BLUE}Completed at: $(date)${NC}"