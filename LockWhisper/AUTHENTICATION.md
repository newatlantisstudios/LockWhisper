# LockWhisper Authentication System

This document describes the authentication system implemented in LockWhisper, including periodic re-authentication and background/foreground transition handling.

## Overview

LockWhisper uses biometric authentication (Face ID/Touch ID) to secure access to the app. The authentication system includes:

- Optional biometric authentication
- Configurable re-authentication intervals
- Automatic authentication checks on app foreground transitions
- Security view overlay when app is in background

## Components

### BiometricAuthManager

The `BiometricAuthManager` is a singleton class that handles all biometric authentication logic:

- Checks if authentication is required based on settings and elapsed time
- Performs biometric authentication using LocalAuthentication framework
- Updates last authentication timestamp
- Provides UI-friendly authentication with error handling

### SceneDelegate Integration

The `SceneDelegate` handles app lifecycle events and integrates with the authentication system:

- **Background Transition**: Shows a security overlay to hide sensitive content
- **Foreground Transition**: Removes security overlay and triggers authentication if needed
- **Authentication Flow**: Uses `BiometricAuthManager` to check and perform authentication

### Settings Configuration

Users can configure authentication behavior in the Settings view:

- **Enable/Disable Biometric Authentication**: Toggle biometric authentication on/off
- **Re-authentication Interval**: Choose from Never, 5 min, 10 min, 30 min, or 1 hour
- **Fallback Options**: Configure unencrypted fallback behavior (not recommended)

## Authentication Flow

1. **App Launch/Foreground**:
   - Scene becomes active
   - Check if biometric authentication is enabled
   - Check if re-authentication interval has elapsed
   - Show authentication prompt if needed
   - Update last authentication time on success

2. **App Background**:
   - Scene will resign active
   - Show security overlay to hide sensitive content
   - Security overlay remains until successful authentication

3. **Periodic Re-authentication**:
   - Configured intervals stored in UserDefaults
   - Last authentication time tracked
   - Automatic check when app becomes active
   - Force authentication if interval has elapsed

## Implementation Details

### Constants

All authentication-related constants are defined in `Constants.swift`:
- `biometricEnabled`: UserDefaults key for biometric toggle
- `biometricCheckInterval`: UserDefaults key for re-auth interval
- `lastBiometricAuthTime`: UserDefaults key for last auth timestamp

### Security Overlay

The security overlay is implemented in `SceneDelegate`:
- Full-screen view that covers all content
- Shows app icon centered on screen
- Prevents screenshot of sensitive data
- Removed only after successful authentication

### Error Handling

Authentication failures are handled gracefully:
- User-friendly error messages
- Alert dialogs for authentication failures
- Security overlay remains if authentication fails
- Fallback to device passcode if biometrics unavailable

## Security Best Practices

1. **No Authentication Bypass**: Users cannot access the app without authentication if enabled
2. **Secure by Default**: Biometric authentication recommended for all users
3. **Time-based Re-authentication**: Prevents unauthorized access after device unlock
4. **Background Protection**: Sensitive data hidden when app is not active
5. **Encrypted Storage**: All sensitive data encrypted with per-module keys

## Testing

To test the authentication system:

1. Enable biometric authentication in Settings
2. Set a re-authentication interval (e.g., 5 minutes)
3. Background the app and return - should see security overlay
4. Wait for interval to elapse and return - should require authentication
5. Test with Face ID/Touch ID disabled to verify fallback behavior

## Future Enhancements

Potential improvements to the authentication system:

1. Custom authentication UI/branding
2. Multiple authentication methods (PIN, pattern)
3. Remote wipe capabilities
4. Authentication attempt logging
5. Configurable lockout after failed attempts