//
//  LockWhisperTests.swift
//  LockWhisperTests
//
//  Created by x on 12/17/24.
//

import Testing
import Foundation
@testable import LockWhisper

struct LockWhisperTests {

    @Test func autoDestructConstants() throws {
        // Verify constants are defined correctly
        #expect(Constants.maxFailedAttempts == "maxFailedAttempts")
        #expect(Constants.defaultMaxFailedAttempts == 5)
        #expect(Constants.failedUnlockAttempts == "failedUnlockAttempts")
        #expect(Constants.autoDestructLocked == "autoDestructLocked")
    }
    
    @Test func biometricAuthManagerFailedAttempts() throws {
        // This is a basic test to ensure the implementation builds
        let manager = BiometricAuthManager.shared
        #expect(manager.shouldRequireAuthentication() == false) // Default case with no biometric enabled
    }
}
