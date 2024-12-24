import JavaScriptCore

class PGPWebView {
    static let shared = PGPWebView()
    private var context: JSContext?
    private var isScriptLoaded = false
    private var scriptLoadedContinuation: CheckedContinuation<Void, Error>?
    
    init() {
        setupJSContext()
    }
    
    private func setupJSContext() {
        context = JSContext()
        
        let baseWindowScript = "var window = this;"
            context?.evaluateScript(baseWindowScript)

        context?.setObject(unsafeBitCast({ (msg: String) -> Void in
            print("[JS]", msg)
        } as @convention(block) (String) -> Void, to: AnyObject.self), forKeyedSubscript: "nativeLog" as NSString)

        let consoleScript = """
        var window = this;
        window.encryptedResult = null;
        var console = {
            log: function(msg) { nativeLog(String(msg)); },
            error: function(msg) { nativeLog('[ERROR] ' + String(msg)); }
        };
        window.console = console;
        """
            context?.evaluateScript(consoleScript)
        
        // Add base64 support first
        let base64Script = """
        var window = this;
        window.btoa = function(input) {
            try {
                var keyStr = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
                var output = '';
                var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
                var i = 0;

                while (i < input.length) {
                    chr1 = input.charCodeAt(i++);
                    chr2 = input.charCodeAt(i++);
                    chr3 = input.charCodeAt(i++);

                    enc1 = chr1 >> 2;
                    enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
                    enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
                    enc4 = chr3 & 63;

                    if (isNaN(chr2)) {
                        enc3 = enc4 = 64;
                    } else if (isNaN(chr3)) {
                        enc4 = 64;
                    }

                    output += keyStr.charAt(enc1) + keyStr.charAt(enc2) + keyStr.charAt(enc3) + keyStr.charAt(enc4);
                }
                return output;
            } catch (e) {
                console.error('btoa error:', e);
                throw e;
            }
        };

        window.atob = function(input) {
            try {
                var keyStr = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
                var output = '';
                var chr1, chr2, chr3;
                var enc1, enc2, enc3, enc4;
                var i = 0;

                input = input.replace(/[^A-Za-z0-9\\+\\/\\=]/g, '');

                while (i < input.length) {
                    enc1 = keyStr.indexOf(input.charAt(i++));
                    enc2 = keyStr.indexOf(input.charAt(i++));
                    enc3 = keyStr.indexOf(input.charAt(i++));
                    enc4 = keyStr.indexOf(input.charAt(i++));

                    chr1 = (enc1 << 2) | (enc2 >> 4);
                    chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
                    chr3 = ((enc3 & 3) << 6) | enc4;

                    output = output + String.fromCharCode(chr1);

                    if (enc3 !== 64) {
                        output = output + String.fromCharCode(chr2);
                    }
                    if (enc4 !== 64) {
                        output = output + String.fromCharCode(chr3);
                    }
                }
                return output;
            } catch (e) {
                console.error('atob error:', e);
                throw e;
            }
        };
        """
            context?.evaluateScript(base64Script)
        
        // Add this after the base64Script and before loading openpgp.min.js
        let textEncoderScript = """
        var TextEncoder = function TextEncoder() {};
        TextEncoder.prototype.encode = function(str) {
            var arr = new Uint8Array(str.length);
            for (var i = 0; i < str.length; i++) {
                arr[i] = str.charCodeAt(i);
            }
            return arr;
        };

        var TextDecoder = function TextDecoder() {};
        TextDecoder.prototype.decode = function(arr) {
            return String.fromCharCode.apply(null, arr);
        };

        window.TextEncoder = TextEncoder;
        window.TextDecoder = TextDecoder;
        """
        context?.evaluateScript(textEncoderScript)
        
        let cryptoScript = """
        var crypto = {
            getRandomValues: function(array) {
                for (var i = 0; i < array.length; i++) {
                    array[i] = Math.floor(Math.random() * 256);
                }
                return array;
            }
        };
        window.crypto = crypto;
        """
        context?.evaluateScript(cryptoScript)
        
        context?.exceptionHandler = { _, exception in
            print("JS Error:", exception?.toString() ?? "unknown error")
        }
        
        if let jsPath = Bundle.main.path(forResource: "openpgp.min", ofType: "js"),
           let jsSource = try? String(contentsOfFile: jsPath, encoding: .utf8) {
            context?.evaluateScript(jsSource)
            setupEncryptionFunctions()
            setupKeyGenerationFunctions()
            isScriptLoaded = true
        }
    }
    
    private func setupEncryptionFunctions() {
        let functions = """
            async function encryptMessage(message, publicKey) {
                        console.log("[encryptMessage] called with message.length:", message.length);
                        console.log("[encryptMessage] called with publicKey.length:", publicKey.length);
                        try {
                            console.log("[encryptMessage] reading public key...");
                            const publicKeyObj = await openpgp.readKey({ armoredKey: publicKey });
                            console.log("[encryptMessage] public key read successfully");

                            console.log("[encryptMessage] creating message...");
                            const pgpMessage = await openpgp.createMessage({ text: message });
                            console.log("[encryptMessage] created pgpMessage successfully");

                            console.log("[encryptMessage] encrypting...");
                            const encrypted = await openpgp.encrypt({
                                message: pgpMessage,
                                encryptionKeys: [publicKeyObj],
                                format: 'armored'
                            });
                            console.log("[encryptMessage] encryption complete. encrypted length:", encrypted.length);

                            // store result globally
                            window.lastEncryptedMessage = encrypted;
                            console.log("[encryptMessage] saved to window.lastEncryptedMessage");
                            return "success";
                        } catch (error) {
                            console.error("[encryptMessage] error:", error);
                            return "error: " + error;
                        }
                    }
            
            function getEncryptedMessage() {
                        const result = window.lastEncryptedMessage || '';
                        console.log("[getEncryptedMessage] returning:", result.length, "chars");
                        window.lastEncryptedMessage = null;
                        return result;
                    }
                    
            
            async function decryptMessage(encryptedText, privateKeyArmored, passphrase = '') {
                if (!encryptedText || !privateKeyArmored) {
                    throw new Error('Missing required parameters');
                }
                
                try {
                    const privateKey = await openpgp.readPrivateKey({ armoredKey: privateKeyArmored });
                    const decryptedPrivateKey = passphrase ? 
                        await openpgp.decryptKey({ privateKey, passphrase }) : privateKey;
                    
                    const message = await openpgp.readMessage({ armoredMessage: encryptedText });
                    const { data: decrypted } = await openpgp.decrypt({
                        message,
                        decryptionKeys: decryptedPrivateKey
                    });
                    
                    return JSON.stringify({ 
                        success: true, 
                        decrypted: decrypted.toString() 
                    });
                } catch (error) {
                    throw error;
                }
            }
            
            async function isKeyEncrypted(privateKeyArmored) {
                try {
                    const privateKey = await openpgp.readPrivateKey({ armoredKey: privateKeyArmored });
                    return JSON.stringify({
                        success: true,
                        isEncrypted: privateKey.isEncrypted
                    });
                } catch (error) {
                    return JSON.stringify({ success: false, error: error.toString() });
                }
            }
        """
        context?.evaluateScript(functions)
    }
    
    private func setupKeyGenerationFunctions() {
        let keyGenScript = """
        async function generatePGPKeyPair(name, email, passphrase) {
            try {
                console.log("[generatePGPKeyPair] Starting generation...");
                const keyOptions = {
                    type: 'ecc',
                    curve: 'ed25519',
                    userIDs: [{ name: name, email: email }],
                    passphrase: passphrase,
                    format: 'armored'
                };
                
                const { privateKey, publicKey } = await openpgp.generateKey(keyOptions);
                
                window.generatedKeyResult = JSON.stringify({
                    success: true,
                    privateKey: privateKey,
                    publicKey: publicKey
                });
                console.log("[generatePGPKeyPair] Key generation complete");
            } catch (error) {
                console.error("[generatePGPKeyPair] Error:", error);
                window.generatedKeyResult = JSON.stringify({
                    success: false,
                    error: error.toString()
                });
            }
        }
        """
        context?.evaluateScript(keyGenScript)
    }

    
    private func waitForScriptLoad() async throws {
        guard isScriptLoaded else {
            throw PGPError.encryptionFailed("JavaScript context not initialized")
        }
    }
    
    func makePGPKeyPair(name: String, email: String, passphrase: String) async throws -> (publicKey: String, privateKey: String) {
        try await waitForScriptLoad()
        
        // Clear any previous results
        context?.evaluateScript("window.generatedKeyResult = null")
        
        let generateScript = """
        (async () => {
            await generatePGPKeyPair('\(name.escapingJavaScript())', '\(email.escapingJavaScript())', '\(passphrase.escapingJavaScript())');
        })();
        """
        
        context?.evaluateScript(generateScript)
        
        // Poll for results with timeout
        for _ in 0..<30 { // 3 second timeout
            if let result = context?.evaluateScript("window.generatedKeyResult")?.toString() {
                context?.evaluateScript("window.generatedKeyResult = null")
                
                guard let data = result.data(using: .utf8),
                      let json = try? JSONDecoder().decode(PGPKeyGenerationResult.self, from: data)
                else {
                    throw PGPError.encryptionFailed("Failed to parse key generation result")
                }
                
                if !json.success {
                    throw PGPError.encryptionFailed(json.error ?? "Unknown error")
                }
                
                guard let publicKey = json.publicKey,
                      let privateKey = json.privateKey
                else {
                    throw PGPError.encryptionFailed("Missing generated keys")
                }
                
                return (publicKey: publicKey, privateKey: privateKey)
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        throw PGPError.encryptionFailed("Timeout during key generation")
    }
    
    func encrypt(_ message: String, withPublicKey key: String) async throws -> String {
        try await waitForScriptLoad()
        
        context?.evaluateScript("""
        async function runEncryption(message, publicKey) {
            try {
                const publicKeyObj = await openpgp.readKey({ armoredKey: publicKey });
                const pgpMessage = await openpgp.createMessage({ text: message });
                const encrypted = await openpgp.encrypt({
                    message: pgpMessage,
                    encryptionKeys: [publicKeyObj],
                    format: 'armored'
                });
                window.encryptedResult = encrypted;
            } catch (error) {
                window.encryptedResult = 'error:' + error.message;
            }
        }
        runEncryption('\(message.escapingJavaScript())', '\(key.escapingJavaScript())');
        """)
        
        // Wait for result with timeout
        for _ in 0..<20 {  // Increased timeout to 2 seconds total
            try await Task.sleep(nanoseconds: 100_000_000)  // 100ms
            if let result = context?.evaluateScript("window.encryptedResult")?.toString(),
               !result.isEmpty {
                context?.evaluateScript("window.encryptedResult = null")
                if result.starts(with: "error:") {
                    throw PGPError.encryptionFailed(result)
                }
                return result
            }
        }
        
        throw PGPError.encryptionFailed("Encryption timeout")
    }
    
    func decrypt(_ message: String, withPrivateKey key: String, passphrase: String? = nil) async throws -> String {
        // Validate inputs
        guard !message.isEmpty else { throw PGPError.decryptionFailed("Empty message") }
        //print(message)
        guard !key.isEmpty else { throw PGPError.invalidKey("Empty private key") }
        //print(key)
        
        try await waitForScriptLoad()
        context?.evaluateScript("console.log('Testing console log');")
        print("[decrypt] Starting decryption")
        
        // Clear any previous results
        context?.evaluateScript("window.decryptResult = null")
        
        let decryptScript = """
        (async () => {
             let stage = 'init';
                try {
                    const key = `\(key.escapingJavaScript())`;
                    console.log("[decrypt] Validating key format...");
                // Validate armored key format
                if (!key.includes('-----BEGIN PGP PRIVATE KEY BLOCK-----')) {
                    throw new Error('Invalid private key format');
                }
                
                stage = 'readPrivateKey';
                console.log("[decrypt] Reading private key...");
                const privateKey = await openpgp.readPrivateKey({ armoredKey: `\(key.escapingJavaScript())` });
                if (!privateKey) throw new Error('Failed to read private key');
                
                stage = 'decryptKey';
                console.log("[decrypt] Decrypting key with passphrase...");
                const decryptedKey = await openpgp.decryptKey({ 
                    privateKey,
                    passphrase: '\(passphrase?.escapingJavaScript() ?? "")'
                });
                if (!decryptedKey) throw new Error('Failed to decrypt key');
                
                stage = 'readMessage';
                console.log("[decrypt] Reading encrypted message...");
                const message = await openpgp.readMessage({ 
                    armoredMessage: `\(message.escapingJavaScript())` 
                });
                if (!message) throw new Error('Failed to read message');
                
                stage = 'decrypt';
                console.log("[decrypt] Decrypting message...");
                const { data: decrypted } = await openpgp.decrypt({
                    message,
                    decryptionKeys: decryptedKey,
                    format: 'utf8'
                });
                
                if (!decrypted) throw new Error('Decryption produced no data');
                
                window.decryptResult = JSON.stringify({ 
                    success: true, 
                    decrypted: decrypted.toString(),
                    stage: 'complete'
                });
                
                console.log("[decrypt] Success");
            } catch (error) {
                console.error(`[decrypt] Error at stage ${stage}:`, error);
                window.decryptResult = JSON.stringify({ 
                    success: false, 
                    error: error.toString(),
                    stage: stage,
                    needsPassphrase: error.message.includes('passphrase') || stage === 'decryptKey'
                });
            }
        })();
        """
        
        context?.evaluateScript(decryptScript)
        
        // Increased timeout for larger messages
        let timeout = message.count > 10000 ? 40 : 20
        
        // Poll for result with exponential backoff
        for attempt in 0..<timeout {
            if let result = context?.evaluateScript("window.decryptResult")?.toString() {
                context?.evaluateScript("window.decryptResult = null")
                return try processDecryptionResult(result)
            }
            try await Task.sleep(nanoseconds: UInt64(100_000_000 * (1 << min(attempt, 4))))
        }
        
        throw PGPError.decryptionFailed("Timeout waiting for decryption result")
    }

    private func processDecryptionResult(_ result: String) throws -> String {
        print("[decrypt] Processing result of length:", result.count)
        
        guard !result.isEmpty, result != "undefined", result != "null" else {
            throw PGPError.decryptionFailed("Invalid decryption result")
        }
        
        guard let jsonData = result.data(using: .utf8) else {
            throw PGPError.decryptionFailed("Failed to convert result to data")
        }
        
        do {
            let decoded = try JSONDecoder().decode(PGPResult.self, from: jsonData)
            
            if !decoded.success {
                if decoded.needsPassphrase == true {
                    throw PGPError.needsPassphrase
                }
                throw PGPError.decryptionFailed("\(decoded.error ?? "Unknown error") at stage: \(decoded.stage ?? "unknown")")
            }
            
            guard let decryptedText = decoded.decrypted, !decryptedText.isEmpty else {
                throw PGPError.decryptionFailed("No decrypted text in result")
            }
            
            return decryptedText
            
        } catch let error as PGPError {
            throw error
        } catch {
            print("[decrypt] JSON Decoding error:", error)
            throw PGPError.decryptionFailed("Failed to process decryption result: \(error)")
        }
    }
    
    func isKeyEncrypted(_ privateKey: String) async throws -> Bool {
        try await waitForScriptLoad()
        print("DEBUG: isKeyEncrypted start")
        
        let script = """
        (async function() {
            try {
                const privateKeyObj = await openpgp.readPrivateKey({ armoredKey: `\(privateKey.escapingJavaScript())` });
                // Attempt to decrypt a random message without passphrase to test if key needs one
                try {
                    await privateKeyObj.decrypt();
                    window.keyEncryptedResult = false;
                } catch (error) {
                    window.keyEncryptedResult = true;
                }
            } catch (error) {
                console.error("Error checking key:", error);
                window.keyEncryptedResult = null;
                throw error;
            }
        })();
        """
        
        context?.evaluateScript(script)
        
        for _ in 0..<20 {
            if let result = context?.evaluateScript("window.keyEncryptedResult")?.toBool() {
                print("isEncrypted:", result)
                context?.evaluateScript("window.keyEncryptedResult = null")
                return result
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        throw PGPError.invalidKey("Failed to determine key encryption status")
    }
    
}

// Supporting types
struct PGPResult: Codable {
    let success: Bool
    let error: String?
    let result: String?
    let text: String?
    let decrypted: String?
    let encrypted: String?
    let needsPassphrase: Bool?
    let isEncrypted: Bool?
    let stage: String?
}

struct PGPKeyGenerationResult: Codable {
    let success: Bool
    let error: String?
    let publicKey: String?
    let privateKey: String?
}

enum PGPError: LocalizedError {
    case needsPassphrase
    case decryptionFailed(String)
    case encryptionFailed(String)
    case invalidKey(String)
    
    var errorDescription: String? {
        switch self {
        case .needsPassphrase:
            return "Key requires passphrase"
        case .decryptionFailed(let error):
            return "Decryption failed: \(error)"
        case .encryptionFailed(let error):
            return "Encryption failed2: \(error)"
        case .invalidKey(let error):
            return "Invalid key: \(error)"
        }
    }
}

extension String {
    // In PGPWebView.swift, add better escaping for newlines and special characters
    func escapingJavaScript() -> String {
        return self.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
    }
}
