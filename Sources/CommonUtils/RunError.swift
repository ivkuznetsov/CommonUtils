//
//  RunError.swift
//  
//
//  Created by Ilya Kuznetsov on 09/02/2023.
//

import Foundation

public enum RunError: Error, Equatable, LocalizedError, @unchecked Sendable {
    case timeout
    case custom(String.LocalizationValue)
    case customVerbatim(String)
    
    public static func == (lhs: RunError, rhs: RunError) -> Bool {
        switch lhs {
        case .timeout: if case .timeout = rhs { return true }
        case .custom(let message): if case .custom(let message2) = rhs { return message == message2 }
        case .customVerbatim(let message): if case .customVerbatim(let message2) = rhs { return message == message2 }
        }
        return false
    }
    
    public var errorDescription: String? {
        switch self {
        case .timeout: return "Timeout"
        case .custom(let string): return String(localized: string)
        case .customVerbatim(let string): return string
        }
    }
}
