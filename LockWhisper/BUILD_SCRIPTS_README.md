# LockWhisper Build Scripts

This directory contains enhanced build scripts for the LockWhisper iOS application with support for xcbeautify, quiet mode, and advanced features.

## Prerequisites

- Xcode (latest version recommended)
- xcbeautify (optional, but recommended for prettier output)
- xcpretty (optional fallback formatter)

To install xcbeautify:
```bash
brew install xcbeautify
```

To install xcpretty (fallback):
```bash
gem install xcpretty
```

## Available Build Scripts

### 1. Shell Script (`build_scripts.sh`)

A comprehensive shell script that provides various build commands with advanced options.

#### Usage

```bash
./build_scripts.sh [COMMAND] [OPTIONS]
```

#### Commands:
- `build` - Build the project
- `test` - Run tests
- `clean` - Clean build folder
- `release` - Build release configuration
- `archive` - Create archive for distribution
- `analyze` - Run static analysis
- `coverage` - Generate test coverage report
- `docs` - Generate documentation

#### Options:
- `-q, --quiet` - Enable quiet mode (minimal output with progress indicator)
- `-v, --verbose` - Enable verbose mode (detailed output)
- `--no-beautify` - Disable xcbeautify (show raw xcodebuild output)
- `--parallel` - Enable parallel builds
- `--clean-derived` - Clean derived data before building
- `--simulator [name]` - Specify simulator (default: iPhone 15)
- `--scheme [name]` - Specify scheme (default: LockWhisper)
- `-h, --help` - Show help message

#### Examples:
```bash
# Build with xcbeautify
./build_scripts.sh build

# Build in quiet mode
./build_scripts.sh build -q

# Build with verbose output
./build_scripts.sh build -v

# Run tests without xcbeautify
./build_scripts.sh test --no-beautify

# Build release configuration quietly
./build_scripts.sh release -q

# Test on specific simulator
./build_scripts.sh test --simulator "iPhone 14 Pro"

# Parallel build with clean derived data
./build_scripts.sh build --parallel --clean-derived

# Generate test coverage
./build_scripts.sh coverage

# Run static analysis
./build_scripts.sh analyze
```

### 2. Makefile

A Makefile for those who prefer using make commands.

#### Usage

```bash
make [TARGET]
```

#### Targets with xcbeautify:
- `make build` - Build with xcbeautify
- `make test` - Run tests with xcbeautify
- `make clean` - Clean build folder with xcbeautify
- `make release` - Build release configuration with xcbeautify
- `make archive` - Create archive with xcbeautify

#### Quiet mode targets:
- `make quiet-build` - Build in quiet mode
- `make quiet-test` - Run tests in quiet mode
- `make quiet-clean` - Clean in quiet mode
- `make quiet-release` - Build release in quiet mode

#### Raw output targets:
- `make raw-build` - Build with raw xcodebuild output
- `make raw-test` - Run tests with raw xcodebuild output

#### Other:
- `make help` - Show all available targets

### 3. NPM Scripts (`package.json`)

For those who prefer npm commands:

```bash
npm run build         # Build with shell script
npm run test          # Run tests
npm run clean         # Clean build
npm run build:quiet   # Build quietly
npm run test:raw      # Test without formatting
```

## Features

### xcbeautify Support

Both scripts automatically detect if xcbeautify is installed and use it to format xcodebuild output. If xcbeautify is not installed, the scripts will:
1. Check for xcpretty as a fallback formatter
2. Otherwise fall back to raw xcodebuild output

### Quiet Mode

Quiet mode provides minimal output with a progress indicator:
- Shows operation being performed
- Displays working progress dots
- Shows success/failure status
- Displays error messages (if any)

This is ideal for CI/CD environments or when you want cleaner output.

### Verbose Mode

Verbose mode provides detailed xcodebuild output for debugging build issues.

### Parallel Builds

Enable parallel target building for faster compilation times when appropriate.

### Clean Derived Data

Option to clean Xcode's derived data before building, ensuring a fresh build environment.

### Color-coded Output

The shell script includes color-coded output:
- Green for success messages
- Yellow for warnings
- Red for errors
- Blue for informational messages
- Bold for headers

### Timestamp Support

Build start and completion times are displayed for tracking build duration.

### Error Handling

Scripts use strict error handling (`set -euo pipefail`) to catch and report errors immediately.

## Advanced Features

### Static Analysis

Run Xcode's static analyzer to find potential issues:
```bash
./build_scripts.sh analyze
```

### Test Coverage

Generate test coverage reports:
```bash
./build_scripts.sh coverage
```

### Documentation Generation

Generate documentation using jazzy or swift-doc:
```bash
./build_scripts.sh docs
```

## CI/CD Integration

These scripts are designed to work well in CI/CD environments:

```yaml
# Example GitHub Actions usage
- name: Build App
  run: ./build_scripts.sh build -q

- name: Run Tests
  run: ./build_scripts.sh test -q

- name: Generate Coverage
  run: ./build_scripts.sh coverage
```

```bash
# Example Jenkins pipeline
stage('Build') {
    sh './build_scripts.sh build --quiet --clean-derived'
}

stage('Test') {
    sh './build_scripts.sh test --quiet'
}

stage('Archive') {
    sh './build_scripts.sh archive --quiet'
}
```

## Testing the Build Scripts

Run the comprehensive test suite:
```bash
./test_build_scripts.sh
```

This will verify:
- Script syntax and functionality
- Available tools and dependencies
- Configuration files
- Documentation completeness

## Troubleshooting

### xcbeautify not found

If you see a warning about xcbeautify not being installed:
1. Install it using Homebrew: `brew install xcbeautify`
2. Or use the `--no-beautify` flag to disable xcbeautify
3. Or install xcpretty as a fallback: `gem install xcpretty`
4. Or use the `raw-*` targets in the Makefile

### Build failures

If builds fail in quiet mode, run without the `-q` flag to see full output:
```bash
./build_scripts.sh build -v  # Verbose mode for debugging
```

### Permission denied

Make sure the scripts are executable:
```bash
chmod +x build_scripts.sh
chmod +x test_build_scripts.sh
```

### Simulator not found

List available simulators:
```bash
xcrun simctl list devices
```

Then specify the correct simulator:
```bash
./build_scripts.sh test --simulator "iPhone 14"
```

## Contributing

When modifying these scripts:
1. Test all commands and options using `test_build_scripts.sh`
2. Update this README if adding new features
3. Maintain backward compatibility
4. Follow the existing code style
5. Add appropriate error handling
6. Update CLAUDE.md if build commands change

## License

These build scripts are part of the LockWhisper project and follow the same license terms.