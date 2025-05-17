# LockWhisper Makefile with xcbeautify and quiet mode support

.PHONY: all build test clean release archive help check-xcbeautify quiet-build quiet-test quiet-clean quiet-release

# Default target
all: build

# Check if xcbeautify is installed
check-xcbeautify:
	@command -v xcbeautify >/dev/null 2>&1 || \
		(echo "Warning: xcbeautify is not installed. To install: brew install xcbeautify" && false)

# Build commands with xcbeautify
build: check-xcbeautify
	@echo "Building LockWhisper..."
	@xcodebuild -project LockWhisper.xcodeproj -scheme LockWhisper -configuration Debug build | xcbeautify

test: check-xcbeautify
	@echo "Running tests..."
	@xcodebuild test -project LockWhisper.xcodeproj -scheme LockWhisper \
		-destination 'platform=iOS Simulator,name=iPhone 15' | xcbeautify

clean: check-xcbeautify
	@echo "Cleaning build folder..."
	@xcodebuild clean -project LockWhisper.xcodeproj -scheme LockWhisper | xcbeautify

release: check-xcbeautify
	@echo "Building release configuration..."
	@xcodebuild -project LockWhisper.xcodeproj -scheme LockWhisper -configuration Release build | xcbeautify

archive: check-xcbeautify
	@echo "Creating archive..."
	@xcodebuild -project LockWhisper.xcodeproj -scheme LockWhisper -configuration Release \
		archive -archivePath build/LockWhisper.xcarchive | xcbeautify
	@echo "Archive created at: build/LockWhisper.xcarchive"

# Quiet mode commands (minimal output)
quiet-build:
	@echo "Building LockWhisper (quiet mode)..."
	@xcodebuild -project LockWhisper.xcodeproj -scheme LockWhisper -configuration Debug build -quiet >/dev/null 2>&1 && \
		echo "✓ Build completed successfully" || \
		(echo "✗ Build failed" && false)

quiet-test:
	@echo "Running tests (quiet mode)..."
	@xcodebuild test -project LockWhisper.xcodeproj -scheme LockWhisper \
		-destination 'platform=iOS Simulator,name=iPhone 15' -quiet >/dev/null 2>&1 && \
		echo "✓ Tests passed" || \
		(echo "✗ Tests failed" && false)

quiet-clean:
	@echo "Cleaning build folder (quiet mode)..."
	@xcodebuild clean -project LockWhisper.xcodeproj -scheme LockWhisper -quiet >/dev/null 2>&1
	@echo "✓ Clean completed"

quiet-release:
	@echo "Building release configuration (quiet mode)..."
	@xcodebuild -project LockWhisper.xcodeproj -scheme LockWhisper -configuration Release build -quiet >/dev/null 2>&1 && \
		echo "✓ Release build completed successfully" || \
		(echo "✗ Release build failed" && false)

# Raw xcodebuild commands (without xcbeautify)
raw-build:
	@echo "Building LockWhisper (raw output)..."
	@xcodebuild -project LockWhisper.xcodeproj -scheme LockWhisper -configuration Debug build

raw-test:
	@echo "Running tests (raw output)..."
	@xcodebuild test -project LockWhisper.xcodeproj -scheme LockWhisper \
		-destination 'platform=iOS Simulator,name=iPhone 15'

# Help target
help:
	@echo "LockWhisper Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build         - Build with xcbeautify"
	@echo "  make test          - Run tests with xcbeautify"
	@echo "  make clean         - Clean build folder with xcbeautify"
	@echo "  make release       - Build release configuration with xcbeautify"
	@echo "  make archive       - Create archive with xcbeautify"
	@echo ""
	@echo "Quiet mode targets (minimal output):"
	@echo "  make quiet-build   - Build in quiet mode"
	@echo "  make quiet-test    - Run tests in quiet mode"
	@echo "  make quiet-clean   - Clean in quiet mode"
	@echo "  make quiet-release - Build release in quiet mode"
	@echo ""
	@echo "Raw output targets (without xcbeautify):"
	@echo "  make raw-build     - Build with raw xcodebuild output"
	@echo "  make raw-test      - Run tests with raw xcodebuild output"
	@echo ""
	@echo "Other:"
	@echo "  make help          - Show this help message"