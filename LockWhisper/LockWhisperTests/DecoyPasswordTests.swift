import Testing
import Foundation
@testable import LockWhisper

@Test
func testDecoyPasswordManager() {
    // Test decoy password generation
    let decoyPasswords = DecoyPasswordManager.shared.generateDecoyPasswords(count: 10)
    #expect(decoyPasswords.count == 10)
    
    // Test that all passwords have unique titles
    let titles = Set(decoyPasswords.map { $0.title })
    #expect(titles.count == decoyPasswords.count)
    
    // Test that each password has a non-empty password field
    for password in decoyPasswords {
        #expect(!password.title.isEmpty)
        #expect(!password.password.isEmpty)
    }
}

@Test
func testFakePasswordModeActivation() async throws {
    // Save current mode
    let originalMode = FakePasswordManager.shared.isInFakeMode
    
    // Test real password setup
    try FakePasswordManager.shared.setupRealPassword("realPassword123")
    
    // Test fake password setup
    try FakePasswordManager.shared.setupFakePassword("fakePassword456")
    
    // Test correct password verification
    #expect(FakePasswordManager.shared.verifyPassword("realPassword123") == .real)
    #expect(FakePasswordManager.shared.verifyPassword("fakePassword456") == .fake)
    #expect(FakePasswordManager.shared.verifyPassword("wrongPassword") == nil)
    
    // Test mode status
    _ = FakePasswordManager.shared.verifyPassword("fakePassword456")
    #expect(FakePasswordManager.shared.isInFakeMode == true)
    
    _ = FakePasswordManager.shared.verifyPassword("realPassword123")
    #expect(FakePasswordManager.shared.isInFakeMode == false)
    
    // Cleanup
    FakePasswordManager.shared.removeFakePassword()
}

@Test
func testDecoyDataInitialization() {
    // Initialize decoy passwords
    DecoyPasswordManager.shared.initializeDecoyPasswordsIfNeeded()
    
    // Check that fake password data exists
    let fakePasswordsKey = FakePasswordManager.shared.getUserDefaultsKey(for: Constants.savedPasswords)
    let fakeData = UserDefaults.standard.data(forKey: fakePasswordsKey)
    
    #expect(fakeData != nil)
}

@Test
func testFakePasswordKeychainManager() throws {
    let fakeKeychainManager = FakePasswordKeychainManager()
    let testData = "test".data(using: .utf8)!
    let account = "testAccount"
    
    // Save data
    try fakeKeychainManager.save(account: account, data: testData)
    
    // Retrieve data
    let retrievedData = try fakeKeychainManager.get(account: account)
    #expect(retrievedData == testData)
    
    // Delete data
    try fakeKeychainManager.delete(account: account)
    
    // Verify deletion
    let deletedData = try fakeKeychainManager.get(account: account)
    #expect(deletedData == nil)
}

@Test
func testEncryptionManagerProtocol() throws {
    // Test with real encryption manager
    let realManager = PasswordEncryptionManager.shared
    let testData = "real test data".data(using: .utf8)!
    
    let encrypted = try realManager.encryptData(testData)
    #expect(realManager.isEncryptedData(encrypted))
    
    let decrypted = try realManager.decryptData(encrypted)
    #expect(decrypted == testData)
    
    // Test with fake encryption manager
    let fakeKeychainManager = FakePasswordKeychainManager()
    let fakeManager = SymmetricEncryptionManager(
        keychainManager: fakeKeychainManager,
        keychainId: FakePasswordManager.shared.getEncryptionKey(for: Constants.passwordsEncryptionKey)
    )
    
    let fakeTestData = "fake test data".data(using: .utf8)!
    let fakeEncrypted = try fakeManager.encryptData(fakeTestData)
    #expect(fakeManager.isEncryptedData(fakeEncrypted))
    
    let fakeDecrypted = try fakeManager.decryptData(fakeEncrypted)
    #expect(fakeDecrypted == fakeTestData)
}