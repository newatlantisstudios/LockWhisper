# LockWhisper Feature Roadmap

## Overview
This roadmap outlines planned features and improvements for LockWhisper, organized into phases. All features maintain the app's offline-only design principle.

## Phase 1: Core Security Enhancements
**Timeline: 1-2 months**

### TODO:
- [x] Implement periodic re-authentication
  - [x] Add biometric check timer in settings
  - [x] Force re-auth after configurable timeout
  - [x] Handle app background/foreground transitions
- [x] Add auto-destruct mechanism
  - [x] Track failed unlock attempts
  - [x] Configurable attempt limit (3-10)
  - [x] Secure data wipe implementation
  - [x] Optional recovery mechanism
- [x] Create fake password system
  - [x] Secondary password storage in keychain
  - [x] Decoy data structure
  - [x] Seamless UI switching between real/fake data

## Phase 2: Password Management Improvements
**Timeline: 1-2 months**

### TODO:
- [ ] Enhanced password generator
  - [ ] Pronounceable password option
  - [ ] Custom character sets
  - [ ] Pattern-based generation
  - [ ] Strength meter integration

- [ ] Quick actions
  - [ ] Copy password without opening detail
  - [ ] Long-press context menus
  - [ ] Swipe to delete
  - [ ] 3D Touch support (older devices)

- [ ] Import/Export functionality
  - [ ] CSV import parser
  - [ ] JSON format support
  - [ ] Batch import UI
  - [ ] Export with encryption

## Phase 3: Organization & Search
**Timeline: 1-2 months**

### TODO:
- [ ] Full-text search implementation
  - [ ] Encrypted index creation
  - [ ] Search across all modules
  - [ ] Search filters by type/date
  - [ ] Recent searches

- [ ] Custom categories/tags
  - [ ] Tag creation and management
  - [ ] Color coding system
  - [ ] Custom icons
  - [ ] Smart folders

- [ ] Favorites system
  - [ ] Pin frequently used items
  - [ ] Quick access dashboard widget
  - [ ] Favorite synchronization across modules

## Phase 4: Advanced Security Features
**Timeline: 2-3 months**

### TODO:
- [ ] Offline 2FA/TOTP generator
  - [ ] QR code scanner for setup
  - [ ] TOTP algorithm implementation
  - [ ] Counter-based HOTP support
  - [ ] Export/import of 2FA seeds

- [ ] Stealth mode
  - [ ] Hidden app icon option
  - [ ] Dial pad access code
  - [ ] Alternate app appearance
  - [ ] Quick toggle in settings

- [ ] Emergency features
  - [ ] Panic gesture configuration
  - [ ] Instant data wipe
  - [ ] Duress password (wipes data)
  - [ ] Recovery prevention

## Phase 5: UX Enhancements
**Timeline: 1-2 months**

### TODO:
- [ ] iPad optimization
  - [ ] Multi-column layouts
  - [ ] Keyboard shortcuts
  - [ ] Split-screen support
  - [ ] Drag and drop

- [ ] Accessibility improvements
  - [ ] Enhanced VoiceOver support
  - [ ] Dynamic type support
  - [ ] High contrast mode
  - [ ] Haptic feedback

- [ ] Custom themes
  - [ ] Theme creation interface
  - [ ] Color scheme editor
  - [ ] Icon pack support
  - [ ] Per-module themes

## Phase 6: Advanced Features
**Timeline: 2-3 months**

### TODO:
- [ ] Secure calculator vault
  - [ ] Calculator UI implementation
  - [ ] Hidden vault trigger
  - [ ] Separate data storage
  - [ ] Quick switch mechanism

- [ ] Local backup system
  - [ ] Automated backups
  - [ ] Version history
  - [ ] Backup encryption
  - [ ] Restore functionality

- [ ] Hardware key support
  - [ ] YubiKey integration
  - [ ] NFC authentication
  - [ ] USB key support
  - [ ] Multiple key pairing

## Phase 7: Data Management
**Timeline: 1-2 months**

### TODO:
- [ ] Batch operations
  - [ ] Multi-select UI
  - [ ] Bulk delete
  - [ ] Bulk export
  - [ ] Bulk categorization

- [ ] Templates system
  - [ ] Pre-defined password templates
  - [ ] Custom field templates
  - [ ] Template sharing
  - [ ] Quick fill from template

- [ ] Advanced sorting
  - [ ] Sort by creation date
  - [ ] Sort by last access
  - [ ] Sort by frequency
  - [ ] Custom sort orders

## Testing & Quality Assurance
**Ongoing throughout all phases**

### TODO:
- [ ] Comprehensive unit tests
- [ ] Integration testing
- [ ] Security audit
- [ ] Performance optimization
- [ ] Memory leak detection
- [ ] Accessibility testing
- [ ] Beta testing program

## Future Considerations
**Beyond Phase 7**

### Ideas to explore:
- Secure QR code generator
- Anti-screenshot protection
- Voice note transcription (offline)
- Secure clipboard manager
- Data shredder with military-grade wiping
- Custom encryption algorithms
- Honeypot data for security research

## Notes
- All features must work completely offline
- Security is the top priority
- User experience should remain simple despite added features
- Backward compatibility must be maintained
- Regular security audits are essential