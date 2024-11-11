//
//  RunError.swift
//  
//
//  Created by Ilya Kuznetsov on 09/02/2023.
//

import Foundation

public enum RunError: Error, Equatable, LocalizedError, @unchecked Sendable {
    case timeout
    case custom(String)
    case localized(String.LocalizationValue, Bundle? = nil)
    
    public static func == (lhs: RunError, rhs: RunError) -> Bool {
        switch lhs {
        case .timeout: if case .timeout = rhs { return true }
        case .custom(let message): if case .custom(let message2) = rhs { return message == message2 }
        case .localized(let message, _): if case .localized(let message2, _) = rhs { return message == message2 }
        }
        return false
    }
    
    public var errorDescription: String? {
        switch self {
        case .timeout: return "Timeout"
        case .custom(let string): return string
        case .localized(let string, let bundle): return  String(localized: string, bundle: bundle)
        }
    }
}
