# LockWhisper Build Scripts

This directory contains build scripts for the LockWhisper iOS application with support for xcbeautify and quiet mode.

## Prerequisites

- Xcode (latest version recommended)
- xcbeautify (optional, but recommended for prettier output)

To install xcbeautify:
```bash
brew install xcbeautify
```

## Available Build Scripts

### 1. Shell Script (`build_scripts.sh`)

A flexible shell script that provides various build commands with options.

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

#### Options:
- `-q, --quiet` - Enable quiet mode (minimal output)
- `--no-beautify` - Disable xcbeautify (show raw xcodebuild output)
- `-h, --help` - Show help message

#### Examples:
```bash
# Build with xcbeautify
./build_scripts.sh build

# Build in quiet mode
./build_scripts.sh build -q

# Run tests without xcbeautify
./build_scripts.sh test --no-beautify

# Build release configuration quietly
./build_scripts.sh release -q
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

## Features

### xcbeautify Support

Both scripts automatically detect if xcbeautify is installed and use it to format xcodebuild output. If xcbeautify is not installed, the scripts will fall back to raw xcodebuild output.

### Quiet Mode

Quiet mode provides minimal output, showing only:
- Operation being performed
- Success/failure status
- Error messages (if any)

This is useful for CI/CD environments or when you want cleaner output.

### Color-coded Output

The shell script includes color-coded output:
- Green for success messages
- Yellow for warnings
- Red for errors

## CI/CD Integration

These scripts are designed to work well in CI/CD environments:

```yaml
# Example GitHub Actions usage
- name: Build App
  run: ./build_scripts.sh build -q

- name: Run Tests
  run: ./build_scripts.sh test -q
```

## Troubleshooting

### xcbeautify not found

If you see a warning about xcbeautify not being installed:
1. Install it using Homebrew: `brew install xcbeautify`
2. Or use the `--no-beautify` flag to disable xcbeautify
3. Or use the `raw-*` targets in the Makefile

### Build failures

If builds fail in quiet mode, run without the `-q` flag to see full output:
```bash
./build_scripts.sh build  # Instead of: ./build_scripts.sh build -q
```

## Contributing

When modifying these scripts:
1. Test all commands and options
2. Update this README if adding new features
3. Maintain backward compatibility
4. Follow the existing code style