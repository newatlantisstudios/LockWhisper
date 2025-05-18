# Fake Password System Feature

## Overview
This feature adds a dual password system to LockWhisper, allowing users to set up both a real password and a fake "decoy" password. When the fake password is entered, the app shows different, decoy data instead of the real encrypted data.

## Implementation Details

### Key Components

1. **FakePasswordManager.swift**
   - Manages authentication modes (real vs fake)
   - Handles password storage in keychain
   - Provides data separation logic

2. **PasswordAuthenticationViewController.swift**
   - New authentication screen that accepts password input
   - Replaces biometric-only authentication when passwords are set
   - Routes users to appropriate data based on password entered

3. **FakePasswordSettingsViewController.swift**
   - Settings screen for configuring real and fake passwords
   - Accessible from Settings → Fake Password Settings
   - Allows enabling/disabling fake password system

4. **Modified CoreDataManager.swift**
   - Now supports dual data stores
   - Automatically switches between real and fake SQLite databases
   - Maintains data separation between modes

### How It Works

1. **Authentication Flow**
   - When app launches, it checks if passwords are configured
   - If configured, presents password screen instead of biometric
   - Password verification determines which data set to load

2. **Data Separation**
   - Real password: Shows actual encrypted data
   - Fake password: Shows separate decoy data
   - Each mode has its own:
     - CoreData store (NotepadModel.sqlite vs NotepadModelFake.sqlite)
     - Keychain entries (with ".fake" suffix)
     - UserDefaults entries (with ".fake" suffix)

3. **Security**
   - Passwords are hashed using SHA256 before storage
   - Each data set has its own encryption keys
   - Fake data can be completely wiped independently

### Usage

1. **Setup**
   - Go to Settings → Fake Password Settings
   - Set your real password first
   - Enable fake password and set it
   - Both passwords must be different

2. **Using Fake Mode**
   - Launch app and enter fake password
   - All data shown will be from fake dataset
   - Create decoy entries as needed

3. **Using Real Mode**
   - Launch app and enter real password
   - Access your actual encrypted data

### Security Considerations

- Remember both passwords - there's no recovery for forgotten passwords
- Fake data is completely separate from real data
- Disabling fake password will delete all fake data
- Auto-destruct feature works with both passwords

### Technical Notes

- Uses `FakePasswordManager.shared.isInFakeMode` to check current mode
- All encryption managers automatically use appropriate keys
- CoreData automatically loads correct database
- Feature integrates with existing biometric authentication