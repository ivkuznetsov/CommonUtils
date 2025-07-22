//
//  UserDefaults.swift
//  CommonUtils
//
//  Created by Ilya Kuznetsov on 14/10/2024.
//

import Foundation

public extension UserDefaults {
    
    static func load<T: Codable>(key: String, storage: UserDefaults = .standard) -> T? {
        if let result = storage.object(forKey: key) {
            if let result = result as? T {
                return result
            } else if let result = result as? Data, let value = try? T.decode(result) {
                return value
            }
        }
        return nil
    }
    
    static func store<T: Codable>(_ value: T, key: String, storage: UserDefaults = .standard) {
        if let value = value as? OptionalProtocol, value.isNil {
            storage.removeObject(forKey: key)
        } else {
            if let value = value as? NSCoding, isPropertyList(value) {
                storage.set(value, forKey: key)
            } else if let value = try? value.toData() {
                storage.set(value, forKey: key)
            }
        }
    }
    
    static func isPropertyList(_ object: Any) -> Bool {
        switch object {
        case is String, is Data, is Date, is NSNumber: true
        case let array as [Any]: array.allSatisfy { isPropertyList($0) }
        case let dict as [AnyHashable: Any]: dict.values.allSatisfy { isPropertyList($0) }
        default: false
        }
    }
}
