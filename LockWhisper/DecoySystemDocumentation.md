# LockWhisper Decoy System Documentation

## Overview

The decoy system in LockWhisper provides a secondary layer of security by implementing a fake password mechanism. When a user enters a decoy password instead of their real password, the app displays entirely different data sets, creating plausible deniability.

## Architecture

### Key Components

1. **FakePasswordManager**: Manages the authentication modes (real vs fake) and handles password verification
2. **DecoyPasswordManager**: Generates and manages realistic-looking decoy password entries
3. **FakePasswordKeychainManager**: Handles keychain operations for fake data using separate service identifiers
4. **SymmetricEncryptionManagerProtocol**: Provides a unified interface for both real and fake encryption managers

### How It Works

1. Users can set up two passwords:
   - Real password: Shows actual data
   - Fake password: Shows decoy data

2. When the fake password is entered:
   - FakePasswordManager switches to fake mode
   - All data operations use fake keychain services and UserDefaults keys
   - Decoy data is displayed instead of real data

3. Decoy data includes realistic-looking entries across multiple categories:
   - Banking & Finance
   - Social Media
   - Shopping
   - Email & Communication
   - Entertainment
   - Work & Productivity

### Implementation Details

#### Data Separation

Real and fake data are completely separated:
- Real data: Uses standard keychain services and UserDefaults keys
- Fake data: Uses ".fake" suffixed services and keys

```swift
// Example of key separation
let realKey = "savedPasswords"
let fakeKey = "savedPasswords.fake"
```

#### Encryption

Both real and fake data use the same encryption methods but with different keys:
- Real data: Uses standard encryption keys
- Fake data: Uses ".fake" suffixed encryption keys

#### Mode Detection

The current mode is determined by the FakePasswordManager:
```swift
if FakePasswordManager.shared.isInFakeMode {
    // Use fake data
} else {
    // Use real data
}
```

## Usage

### Setting Up Passwords

1. Navigate to Settings → Password Settings
2. Set up a real password
3. Enable fake password option
4. Set up a fake password

### Switching Modes

Simply enter the appropriate password when launching the app:
- Real password → Real data mode
- Fake password → Fake data mode

### Managing Decoy Data

Decoy data is automatically generated when the fake password is first set up. The system creates realistic-looking password entries across various categories to maintain plausibility.

## Security Considerations

1. **Complete Separation**: Real and fake data never mix
2. **Realistic Decoy Data**: Generated entries look authentic to maintain plausibility
3. **No Visual Indicators**: The app looks identical in both modes
4. **Secure Storage**: Both real and fake data are encrypted

## Testing

The decoy system includes comprehensive tests:
- Password verification tests
- Data separation tests
- Encryption compatibility tests
- Decoy data generation tests

See `DecoyPasswordTests.swift` for implementation details.