import Foundation
import CryptoKit

/// Manages decoy password entries that appear when using a fake password
class DecoyPasswordManager {
    static let shared = DecoyPasswordManager()
    
    // Sample decoy categories with realistic-looking fake data
    private let decoyTemplates: [PasswordCategory] = [
        PasswordCategory(
            name: "Banking & Finance",
            entries: [
                DecoyPasswordEntry(
                    title: "Chase Bank",
                    password: "Ch@se2023!Secure",
                    username: "john.doe84",
                    url: "https://chase.com",
                    notes: "Checking account - Main"
                ),
                DecoyPasswordEntry(
                    title: "Wells Fargo",
                    password: "WF*Banking#2023",
                    username: "jdoe_savings",
                    url: "https://wellsfargo.com",
                    notes: "Savings account"
                ),
                DecoyPasswordEntry(
                    title: "Bank of America",
                    password: "BoA@Secure$24",
                    username: "johndoe.boa",
                    url: "https://bankofamerica.com",
                    notes: "Credit card account"
                ),
                DecoyPasswordEntry(
                    title: "PayPal",
                    password: "PP*Payment#Safe23",
                    username: "john.doe@email.com",
                    url: "https://paypal.com",
                    notes: "Primary payment method"
                )
            ]
        ),
        PasswordCategory(
            name: "Social Media",
            entries: [
                DecoyPasswordEntry(
                    title: "Facebook",
                    password: "Fb@Social#2023",
                    username: "john.doe.fb",
                    url: "https://facebook.com",
                    notes: "Personal account"
                ),
                DecoyPasswordEntry(
                    title: "Twitter/X",
                    password: "Tw!tter@X#24",
                    username: "@johndoe_real",
                    url: "https://x.com",
                    notes: "Professional account"
                ),
                DecoyPasswordEntry(
                    title: "Instagram",
                    password: "Insta*Gram#2023",
                    username: "johndoe_photos",
                    url: "https://instagram.com",
                    notes: "Photography account"
                ),
                DecoyPasswordEntry(
                    title: "LinkedIn",
                    password: "Link3d!n#Pro",
                    username: "john-doe-professional",
                    url: "https://linkedin.com",
                    notes: "Professional networking"
                )
            ]
        ),
        PasswordCategory(
            name: "Shopping",
            entries: [
                DecoyPasswordEntry(
                    title: "Amazon",
                    password: "Amz@Shop#Prime23",
                    username: "johndoe.prime",
                    url: "https://amazon.com",
                    notes: "Prime member account"
                ),
                DecoyPasswordEntry(
                    title: "eBay",
                    password: "eB@y*Auction#24",
                    username: "john_doe_seller",
                    url: "https://ebay.com",
                    notes: "Buyer/Seller account"
                ),
                DecoyPasswordEntry(
                    title: "Walmart",
                    password: "WM@rt#Shop2023",
                    username: "jdoe.walmart",
                    url: "https://walmart.com",
                    notes: "Grocery delivery"
                )
            ]
        ),
        PasswordCategory(
            name: "Email & Communication",
            entries: [
                DecoyPasswordEntry(
                    title: "Gmail - Personal",
                    password: "Gm@il#Personal23",
                    username: "john.doe.personal@gmail.com",
                    url: "https://gmail.com",
                    notes: "Primary email"
                ),
                DecoyPasswordEntry(
                    title: "Outlook - Work",
                    password: "0utl00k@Work#24",
                    username: "jdoe@company.com",
                    url: "https://outlook.com",
                    notes: "Work email account"
                ),
                DecoyPasswordEntry(
                    title: "ProtonMail",
                    password: "Pr0ton#Secure@23",
                    username: "johndoe.secure",
                    url: "https://protonmail.com",
                    notes: "Secure communications"
                )
            ]
        ),
        PasswordCategory(
            name: "Entertainment",
            entries: [
                DecoyPasswordEntry(
                    title: "Netflix",
                    password: "Netfl!x@Stream23",
                    username: "john.doe@email.com",
                    url: "https://netflix.com",
                    notes: "Family account"
                ),
                DecoyPasswordEntry(
                    title: "Spotify",
                    password: "Sp0t!fy#Music24",
                    username: "johndoe.music",
                    url: "https://spotify.com",
                    notes: "Premium subscription"
                ),
                DecoyPasswordEntry(
                    title: "Disney+",
                    password: "D!sney+Stream#23",
                    username: "john.family",
                    url: "https://disneyplus.com",
                    notes: "Kids account included"
                )
            ]
        ),
        PasswordCategory(
            name: "Work & Productivity",
            entries: [
                DecoyPasswordEntry(
                    title: "Slack",
                    password: "Sl@ck#Team2023",
                    username: "john.doe@company.slack.com",
                    url: "https://slack.com",
                    notes: "Company workspace"
                ),
                DecoyPasswordEntry(
                    title: "Microsoft 365",
                    password: "MS365@Office#24",
                    username: "jdoe@company.com",
                    url: "https://office365.com",
                    notes: "Corporate license"
                ),
                DecoyPasswordEntry(
                    title: "GitHub",
                    password: "G!tHub#Code2023",
                    username: "johndoe-dev",
                    url: "https://github.com",
                    notes: "Development projects"
                )
            ]
        )
    ]
    
    private init() {}
    
    /// Generates a personalized set of decoy password entries
    func generateDecoyPasswords(count: Int = 15) -> [PasswordEntry] {
        var decoyPasswords: [PasswordEntry] = []
        var usedTitles = Set<String>()
        
        // Randomly select entries from different categories
        for category in decoyTemplates.shuffled() {
            for entry in category.entries.shuffled() {
                if !usedTitles.contains(entry.title) {
                    usedTitles.insert(entry.title)
                    
                    // Convert DecoyPasswordEntry to PasswordEntry
                    let passwordEntry = PasswordEntry(
                        title: entry.title,
                        password: entry.password
                    )
                    decoyPasswords.append(passwordEntry)
                    
                    if decoyPasswords.count >= count {
                        return decoyPasswords.shuffled() // Shuffle for randomness
                    }
                }
            }
        }
        
        return decoyPasswords.shuffled()
    }
    
    /// Saves decoy passwords to the fake password storage
    func saveDecoyPasswords() {
        let encoder = JSONEncoder()
        let decoyPasswords = generateDecoyPasswords()
        
        do {
            let encodedData = try encoder.encode(decoyPasswords)
            // Create a fake encryption manager instance
            let fakeKeychainManager = FakePasswordKeychainManager()
            let fakeEncryptionManager = SymmetricEncryptionManager(
                keychainManager: fakeKeychainManager,
                keychainId: FakePasswordManager.shared.getEncryptionKey(for: Constants.passwordsEncryptionKey)
            )
            
            // Encrypt with fake encryption key
            let encryptedData = try fakeEncryptionManager.encryptData(encodedData)
            
            // Save to fake UserDefaults key
            let fakePasswordsKey = FakePasswordManager.shared.getUserDefaultsKey(for: Constants.savedPasswords)
            UserDefaults.standard.set(encryptedData, forKey: fakePasswordsKey)
            
        } catch {
            print("Error saving decoy passwords: \(error.localizedDescription)")
        }
    }
    
    /// Checks if decoy passwords need to be initialized
    func initializeDecoyPasswordsIfNeeded() {
        let fakePasswordsKey = FakePasswordManager.shared.getUserDefaultsKey(for: Constants.savedPasswords)
        
        // If no fake passwords exist, create them
        if UserDefaults.standard.data(forKey: fakePasswordsKey) == nil {
            saveDecoyPasswords()
        }
    }
    
    /// Updates decoy passwords with fresh data
    func refreshDecoyPasswords() {
        saveDecoyPasswords()
    }
}

// MARK: - Supporting Models

struct PasswordCategory {
    let name: String
    let entries: [DecoyPasswordEntry]
}

struct DecoyPasswordEntry {
    let title: String
    let password: String
    let username: String
    let url: String
    let notes: String
}

// MARK: - Fake Password Keychain Manager

/// A keychain manager that uses the fake password service
struct FakePasswordKeychainManager: KeychainManager {
    private let service: String
    
    init() {
        self.service = FakePasswordManager.shared.getKeychainService(for: Constants.passwordsService)
    }
    
    func save(account: String, data: Data) throws {
        try? delete(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw PasswordKeychainError.unhandledError(status: status)
        }
    }
    
    func get(account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw PasswordKeychainError.unhandledError(status: status)
        }
        return result as? Data
    }
    
    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PasswordKeychainError.unhandledError(status: status)
        }
    }
    
    enum PasswordKeychainError: Error {
        case unhandledError(status: OSStatus)
    }
}