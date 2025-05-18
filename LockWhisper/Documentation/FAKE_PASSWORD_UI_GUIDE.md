# Fake Password UI Switching Feature

## Overview
The LockWhisper password manager now includes a seamless UI switching capability between real and fake (decoy) data. This feature enhances security by allowing users to display decoy passwords when under duress.

## Feature Highlights

### 1. Mode Indicator
- **Secure Mode**: 🔒 Green indicator shows you're viewing real passwords
- **Decoy Mode**: 🔓 Orange indicator shows you're viewing fake passwords

### 2. Quick Toggle
- Toggle button (⇄) in the navigation bar allows instant switching
- Confirmation dialog prevents accidental mode switches
- Smooth cross-fade animation during transition

### 3. Visual Differentiation
- Subtle orange tint to table background in decoy mode
- Orange navigation bar tint in decoy mode
- Orange delete swipe actions in decoy mode

### 4. Decoy Data Management
- Refresh button (↻) in decoy mode to regenerate fake passwords
- Realistic-looking decoy entries from various categories:
  - Banking & Finance
  - Social Media
  - Shopping
  - Email & Communication
  - Entertainment
  - Work & Productivity

### 5. Feedback System
- Success banners confirm mode switches
- "✓ Switched to Decoy Mode" or "✓ Switched to Secure Mode"
- "✓ Decoy passwords refreshed" when regenerating fake data

## User Experience Flow

1. **Initial State**: User opens password manager in secure mode
2. **Switching Modes**: Tap toggle button → Confirm switch → Animated transition
3. **Visual Feedback**: Mode indicator updates, UI colors change, success banner appears
4. **Data Display**: Appropriate password list loads based on current mode
5. **Actions**: Add, edit, delete operations work seamlessly in both modes

## Security Benefits

- **Plausible Deniability**: Show convincing fake passwords when forced
- **Quick Access**: Instant switching without complicated processes
- **Visual Clarity**: Always know which mode you're in
- **Data Separation**: Real and fake data stored separately with different encryption

## Implementation Details

### Code Architecture
- `FakePasswordManager`: Handles mode switching and data routing
- `DecoyPasswordManager`: Generates and manages fake password data
- `PasswordViewController`: UI implementation with mode awareness
- Separate encryption managers for real and fake data

### Key Files Modified
- `/Password/PasswordViewController.swift`: Added UI switching logic
- `/Other/FakePasswordManager.swift`: Enhanced with public mode property
- `/Password/DecoyPasswordManager.swift`: Already implemented decoy data generation

### UI Components
- Mode indicator label with dynamic text/color
- Toggle button with arrow icon
- Refresh button for decoy data
- Success banner notifications
- Subtle background tinting

## Testing the Feature

1. Enable fake password in settings
2. Open Password module
3. Toggle between modes using the ⇄ button
4. Observe UI changes and data switching
5. Try refresh button in decoy mode
6. Test CRUD operations in both modes

## Notes

- Feature only appears when fake password system is enabled
- All operations (add/edit/delete) work independently in each mode
- Data persistence is maintained separately for each mode
- Encryption keys are different for real and fake data