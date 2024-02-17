import Foundation

class KeychainManager {
    
    static func setOrUpdatePassword(_ password: String, forUsername username: String) -> OSStatus {
        let passwordData = password.data(using: .utf8)!
                
        // First, try to update the password if it already exists
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: passwordData
        ]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        // If the item was not found, add it as a new entry
        if updateStatus == errSecItemNotFound {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: username,
                kSecValueData as String: passwordData
            ]
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            return addStatus
        }
        
        return updateStatus
    }
    
    // Function to update an existing password in the keychain
    static func updatePassword(_ password: String, forUsername username: String) -> OSStatus {
        let passwordData = password.data(using: .utf8)!
        
        // Attributes to identify the item to update
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username
        ]
        
        // Attributes to update
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: passwordData
        ]
        
        // Update the item in the keychain
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        return status
    }
    
    static func getPassword(username: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        if let passwordData = item as? Data {
            return String(data: passwordData, encoding: .utf8)
        }

        return nil
    }
}
