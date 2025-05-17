import Testing
@testable import LockWhisper
import Foundation

struct RecoveryManagerTests {
    @Test func testRecoveryKeyGeneration() async throws {
        // Given
        let recoveryManager = RecoveryManager.shared
        
        // When
        let recoveryKey = try recoveryManager.generateRecoveryKey()
        
        // Then
        #expect(!recoveryKey.isEmpty)
        #expect(recoveryKey.count > 40) // Base64-encoded 256-bit key should be at least 43 chars
    }
    
    @Test func testRecoveryPINGeneration() async throws {
        // Given
        let recoveryManager = RecoveryManager.shared
        
        // When
        let pin = recoveryManager.generateRecoveryPIN()
        
        // Then
        #expect(pin.count == 6)
        #expect(Int(pin) != nil) // Should be numeric
    }
    
    @Test func testRecoveryPINVerification() async throws {
        // Given
        let recoveryManager = RecoveryManager.shared
        let pin = recoveryManager.generateRecoveryPIN()
        
        // When
        let isValid = recoveryManager.verifyRecoveryPIN(pin)
        let isInvalid = recoveryManager.verifyRecoveryPIN("000000")
        
        // Then
        #expect(isValid == true)
        #expect(isInvalid == false)
    }
    
    @Test func testRecoveryEnabledState() async throws {
        // Given
        let recoveryManager = RecoveryManager.shared
        
        // When
        recoveryManager.isRecoveryEnabled = true
        let isEnabled = recoveryManager.isRecoveryEnabled
        
        recoveryManager.isRecoveryEnabled = false
        let isDisabled = recoveryManager.isRecoveryEnabled
        
        // Then
        #expect(isEnabled == true)
        #expect(isDisabled == false)
    }
    
    @Test func testRecoveryTimeWindow() async throws {
        // Given
        let recoveryManager = RecoveryManager.shared
        let defaultWindow = recoveryManager.recoveryTimeWindow
        
        // When
        recoveryManager.recoveryTimeWindow = 3600 // 1 hour
        let updatedWindow = recoveryManager.recoveryTimeWindow
        
        // Then
        #expect(defaultWindow == 86400) // 24 hours default
        #expect(updatedWindow == 3600)
    }
}