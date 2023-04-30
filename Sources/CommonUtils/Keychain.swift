//
//  Keychain.swift
//

import Foundation

public struct Keychain {
	
    private static func addQuery(service: String, password: Data) -> CFDictionary {
        [ kSecClass as String: kSecClassGenericPassword,
          kSecAttrService as String: service,
          kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
          kSecValueData as String: password ] as [String : Any] as CFDictionary
    }

	private static func retrieveQuery(service: String) -> CFDictionary {
		[ kSecClass as String: kSecClassGenericPassword,
          kSecAttrService as String: service,
          kSecReturnAttributes as String: true,
          kSecReturnData as String: true ] as [String : Any] as CFDictionary
	}

	private static func searchQuery(service: String) -> CFDictionary {
		[ kSecClass as String: kSecClassGenericPassword,
          kSecAttrService as String: service ] as [String : Any] as CFDictionary
	}

    private static func updateQuery(password: Data) -> CFDictionary {
        [ kSecValueData as String: password,
          kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly ] as [String : Any] as CFDictionary
    }

    private static func update(service: String, value: String) -> OSStatus {
        update(service: service, value: value.data(using: .utf8)!)
	}
    
    @discardableResult
    public static func update(service: String, value: Data) -> OSStatus {
        let status = SecItemAdd(addQuery(service: service, password: value), nil)

        if status == errSecDuplicateItem {
            return SecItemUpdate(searchQuery(service: service), updateQuery(password: value))
        }
        return status
    }
    
    @discardableResult
    public static func delete(service: String) -> OSStatus {
        SecItemDelete(searchQuery(service: service))
	}
    
    public static func set(data: Data?, service: String) {
        if let data = data {
            update(service: service, value: data)
        } else {
            delete(service: service)
        }
    }
    
    public static func set(string: String?, service: String) {
        set(data: string?.data(using: .utf8), service: service)
    }
    
    public static func get(_ service: String) -> Data? {
        var item: CFTypeRef?

        let status = SecItemCopyMatching(retrieveQuery(service: service), &item)
        
        if status == errSecSuccess,
           let item = item as? [String : Any],
           let data = item[kSecValueData as String] as? Data {
           return data
        }
        return nil
    }
    
    public static func getString(_ service: String) -> String? {
        if let data = get(service) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
