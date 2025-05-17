# Auto-Destruct Security Feature

This document describes the auto-destruct mechanism implemented in LockWhisper that tracks failed unlock attempts.

## Overview

The auto-destruct feature enhances security by:
1. Tracking failed biometric authentication attempts
2. Showing warnings about remaining attempts
3. Automatically wiping all app data after 5 failed attempts
4. Can be enabled/disabled through settings with a 30-second security timer

## Implementation Details

### Configuration
- Maximum failed attempts: 5 (configurable in `Constants.swift`)
- Failed attempts are persisted across app launches
- Users see warnings when attempts remain (only when feature is enabled)
- Feature can be toggled on/off in Settings
- 30-second timer before toggle takes effect (security measure)

### Components Modified

1. **BiometricAuthManager.swift**
   - Added failed attempt tracking
   - Implemented auto-destruct mechanism
   - Added methods for handling failed attempts

2. **Constants.swift**
   - Added keys for tracking failed attempts
   - Added auto-destruct lock status
   - Configurable max attempts limit
   - Added auto-destruct enabled flag
   - Timer duration for toggle security

3. **SceneDelegate.swift**
   - Shows warning messages on security screen
   - Displays remaining attempts count (only when feature is enabled)

4. **SettingsViewController.swift**
   - Added toggle to enable/disable auto-destruct
   - Implemented 30-second timer with countdown
   - Added cancel button during countdown
   - Shows confirmation dialog for security

### How It Works

1. User must first enable auto-destruct in Settings
2. When enabling/disabling, a 30-second countdown starts for security
3. User can cancel the toggle during countdown
4. When enabled and biometric authentication fails, the `failedAttempts` counter increments
5. After each failed attempt, users see remaining attempts count
6. When reaching the maximum (5 attempts), the app:
   - Wipes all UserDefaults data
   - Clears all keychain items
   - Deletes CoreData stores
   - Removes encrypted files
   - Forces app termination
7. Feature only works when explicitly enabled by user

### Data Wiped

The following data is permanently deleted on auto-destruct:
- All UserDefaults (contacts, passwords, settings)
- All keychain items (encryption keys)
- CoreData stores (notes, TODO items)
- Encrypted files in documents directory

### Security Considerations

- Once triggered, data recovery is impossible
- The mechanism cannot be bypassed when enabled
- Failed attempts persist across app launches (when feature is enabled)
- Successful authentication resets the counter
- 30-second timer prevents accidental or malicious toggling
- Confirmation dialog ensures user intent
- Feature is disabled by default for safety

## Testing Considerations

To test without data loss:
1. Use a test device or simulator
2. Back up data before testing
3. Enable the feature in Settings (wait 30 seconds for it to activate)
4. Be aware that 5 failed attempts triggers immediate wipe
5. Feature can be disabled at any time (with 30-second timer)