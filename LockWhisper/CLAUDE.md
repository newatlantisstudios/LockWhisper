# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## LockWhisper iOS Application

LockWhisper is a privacy-focused iOS application built with UIKit that provides encrypted storage for various types of personal data including PGP communications, passwords, notes, files, and more.

## Build Commands

```bash
# Build the project
xcodebuild -project LockWhisper.xcodeproj -scheme LockWhisper -configuration Debug build

# Run tests
xcodebuild test -project LockWhisper.xcodeproj -scheme LockWhisper -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean build folder
xcodebuild clean -project LockWhisper.xcodeproj -scheme LockWhisper
```

## Architecture Overview

### Core Components

1. **DashboardViewController**: Main entry point, displays grid of feature tiles (PGP, Notepad, Contacts, File Vault, etc.)
2. **SceneDelegate**: Handles scene lifecycle, sets up navigation controller with DashboardViewController
3. **AppDelegate**: Handles app lifecycle, performs data migration from older versions (V3 migration)

### Encryption Infrastructure

- **SymmetricEncryptionManager**: Generic manager for symmetric key encryption using CryptoKit
- **KeychainManager Protocol**: Interface for secure key storage
- **Module-specific encryption**: Each feature module has its own encryption manager (e.g., NoteEncryptionManager, PasswordEncryptionManager)
- **Constants.swift**: Centralized location for all keychain keys, UserDefaults keys, and service identifiers

### Feature Modules

Each major feature follows a similar pattern with its own set of controllers and encryption:

1. **PGP Module**
   - ConversationsViewController (list)
   - ConversationViewController (detail)
   - PGPEncryptionManager
   - Web-based PGP implementation using openpgp.min.js

2. **Notepad Module**
   - NotepadViewController (list)
   - NoteDetailViewController (detail)
   - NewNoteViewController (creation)
   - CoreData backed with NotepadModel.xcdatamodeld

3. **File Vault Module**
   - FileVaultViewController (list)
   - FileEncryptionManager
   - File preview capabilities

4. **Password Module**
   - PasswordViewController (list)
   - PasswordDetailViewController (detail)
   - PasswordEncryptionManager

### Data Persistence

- **CoreData**: Used for notes and TODO items
- **UserDefaults**: Stores encrypted contacts, passwords, and settings
- **Keychain**: Stores encryption keys for each module
- **File System**: Encrypted files for File Vault feature

### Security Features

- Biometric authentication support (Face ID/Touch ID)
- Per-module encryption with unique keys
- Fallback handling for encryption failures (configurable)
- Migration support for upgrading encryption schemes

### Testing

The project uses Swift Testing framework (note the `@Test` attribute instead of XCTest). Test file is located at:
- `LockWhisperTests/LockWhisperTests.swift`

### Key Configuration Files

- **Info.plist**: Contains privacy descriptions for camera, microphone, and photo library access
- **project.pbxproj**: Xcode project configuration
- **Constants.swift**: All hardcoded keys and identifiers

### Migration System

The app includes a robust migration system for updating data formats:
- V3 migration: Converts contacts to new format, migrates keys to encrypted storage
- Migration status tracked in UserDefaults

## Development Guidelines

1. Always use the centralized Constants struct for keys and identifiers
2. Each feature module should have its own encryption manager
3. Follow the established pattern for view controllers (list → detail → add/edit)
4. Use StyledButton for consistent UI elements
5. Implement proper error handling for encryption/decryption operations
6. Test on both light and dark modes (uses system appearance)