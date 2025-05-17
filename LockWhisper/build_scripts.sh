#!/bin/bash

# LockWhisper Build Scripts with xcbeautify and quiet mode support

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
QUIET_MODE=false
USE_XCBEAUTIFY=true

# Check if xcbeautify is installed
check_xcbeautify() {
    if ! command -v xcbeautify &> /dev/null; then
        echo -e "${YELLOW}Warning: xcbeautify is not installed.${NC}"
        echo "To install xcbeautify, run: brew install xcbeautify"
        USE_XCBEAUTIFY=false
    fi
}

# Print usage
usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build       Build the project"
    echo "  test        Run tests"
    echo "  clean       Clean build folder"
    echo "  release     Build release configuration"
    echo "  archive     Create archive for distribution"
    echo ""
    echo "Options:"
    echo "  -q, --quiet     Enable quiet mode (minimal output)"
    echo "  --no-beautify   Disable xcbeautify (show raw xcodebuild output)"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build              # Build with xcbeautify"
    echo "  $0 build -q           # Build in quiet mode"
    echo "  $0 test --no-beautify # Run tests without xcbeautify"
    exit 0
}

# Parse arguments
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

COMMAND=$1
shift

while [[ $# -gt 0 ]]; do
    case $1 in
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        --no-beautify)
            USE_XCBEAUTIFY=false
            shift
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
XCODEBUILD_BASE="xcodebuild -project LockWhisper.xcodeproj -scheme LockWhisper"

# Set up quiet mode options
if [ "$QUIET_MODE" = true ]; then
    XCODEBUILD_OPTIONS="-quiet"
else
    XCODEBUILD_OPTIONS=""
fi

# Function to run xcodebuild with or without xcbeautify
run_xcodebuild() {
    local command=$1
    
    if [ "$USE_XCBEAUTIFY" = true ] && [ "$QUIET_MODE" = false ]; then
        $command | xcbeautify
    else
        $command
    fi
}

# Build function
build() {
    echo -e "${GREEN}Building LockWhisper...${NC}"
    
    local build_cmd="$XCODEBUILD_BASE -configuration Debug build $XCODEBUILD_OPTIONS"
    
    if [ "$QUIET_MODE" = true ]; then
        run_xcodebuild "$build_cmd" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Build completed successfully${NC}"
        else
            echo -e "${RED}✗ Build failed${NC}"
            exit 1
        fi
    else
        run_xcodebuild "$build_cmd"
    fi
}

# Test function
test() {
    echo -e "${GREEN}Running tests...${NC}"
    
    local test_cmd="$XCODEBUILD_BASE test -destination 'platform=iOS Simulator,name=iPhone 15' $XCODEBUILD_OPTIONS"
    
    if [ "$QUIET_MODE" = true ]; then
        run_xcodebuild "$test_cmd" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Tests passed${NC}"
        else
            echo -e "${RED}✗ Tests failed${NC}"
            exit 1
        fi
    else
        run_xcodebuild "$test_cmd"
    fi
}

# Clean function
clean() {
    echo -e "${GREEN}Cleaning build folder...${NC}"
    
    local clean_cmd="$XCODEBUILD_BASE clean $XCODEBUILD_OPTIONS"
    
    if [ "$QUIET_MODE" = true ]; then
        run_xcodebuild "$clean_cmd" > /dev/null 2>&1
        echo -e "${GREEN}✓ Clean completed${NC}"
    else
        run_xcodebuild "$clean_cmd"
    fi
}

# Release build function
release() {
    echo -e "${GREEN}Building release configuration...${NC}"
    
    local release_cmd="$XCODEBUILD_BASE -configuration Release build $XCODEBUILD_OPTIONS"
    
    if [ "$QUIET_MODE" = true ]; then
        run_xcodebuild "$release_cmd" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Release build completed successfully${NC}"
        else
            echo -e "${RED}✗ Release build failed${NC}"
            exit 1
        fi
    else
        run_xcodebuild "$release_cmd"
    fi
}

# Archive function
archive() {
    echo -e "${GREEN}Creating archive...${NC}"
    
    local archive_path="build/LockWhisper.xcarchive"
    local archive_cmd="$XCODEBUILD_BASE -configuration Release archive -archivePath $archive_path $XCODEBUILD_OPTIONS"
    
    if [ "$QUIET_MODE" = true ]; then
        run_xcodebuild "$archive_cmd" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Archive created at: $archive_path${NC}"
        else
            echo -e "${RED}✗ Archive creation failed${NC}"
            exit 1
        fi
    else
        run_xcodebuild "$archive_cmd"
        echo -e "${GREEN}Archive created at: $archive_path${NC}"
    fi
}

# Main execution
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
    *)
        if [ -z "$COMMAND" ]; then
            echo -e "${RED}Error: No command specified${NC}"
        else
            echo -e "${RED}Error: Unknown command: $COMMAND${NC}"
        fi
        usage
        ;;
esac