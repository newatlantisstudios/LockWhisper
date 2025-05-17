# LockWhisper Recovery Mechanism

## Overview

The LockWhisper app now includes an optional recovery mechanism that works alongside the auto-destruct security feature. This allows users to recover their data even after the auto-destruct mechanism has been triggered.

## Features

### 1. Recovery Options
- **Recovery Key**: A base64-encoded 256-bit encryption key
- **Recovery PIN**: A 6-digit PIN for simplified recovery
- **Time Window**: Configurable recovery period (1 hour to 7 days)

### 2. Pre-destruction Backup
- Automatically creates an encrypted backup before auto-destruct
- Backup includes:
  - Notes
  - Passwords
  - Contacts
  - TODO items
  - PGP conversations
- Backup is encrypted with the recovery key
- Backup expires after the configured time window

### 3. Recovery Process
- Users can recover data using their recovery key
- Biometric authentication required for recovery
- Recovery interface accessible from locked screen
- Data restoration overwrites current data

## Implementation Details

### New Files
- `RecoveryManager.swift`: Core recovery logic
- `RecoverySettingsViewController.swift`: Settings interface
- `RecoveryViewController.swift`: Recovery interface

### Modified Files
- `AutoDestructManager.swift`: Integration with recovery system
- `SceneDelegate.swift`: Recovery button on locked screen
- `SettingsViewController.swift`: Recovery settings access
- `Constants.swift`: New recovery-related constants

### Security Considerations
- Recovery key stored in secure keychain
- Recovery PIN stored as SHA256 hash
- Backup data encrypted with AES-GCM
- Time-limited recovery window
- Biometric authentication required

## Usage

### Enable Recovery
1. Go to Settings → Recovery Settings
2. Toggle "Enable Recovery" ON
3. Set recovery time window
4. Generate recovery key and/or PIN
5. Save recovery credentials securely

### Recover Data
1. If device is locked due to auto-destruct
2. Tap "Recover Data" button
3. Enter recovery key or PIN
4. Authenticate with biometrics
5. Data will be restored

## Configuration

### Recovery Time Window
- Default: 24 hours
- Range: 1 hour to 7 days
- Adjustable via slider in settings

### Recovery Key
- 256-bit symmetric key
- Base64 encoded for display
- Tap to copy to clipboard

### Recovery PIN
- 6-digit numeric code
- Easier to remember than key
- Stored as SHA256 hash

## Technical Details

### Encryption
- Uses CryptoKit AES.GCM encryption
- 256-bit symmetric keys
- Secure keychain storage

### Backup Format
- JSON serialization
- Encrypted with recovery key
- Includes timestamp and expiration

### Error Handling
- Comprehensive error types
- User-friendly error messages
- Fallback mechanisms

## Future Enhancements

1. Cloud backup integration
2. Multiple recovery methods
3. Partial data recovery
4. Recovery audit logs
5. Remote recovery triggers