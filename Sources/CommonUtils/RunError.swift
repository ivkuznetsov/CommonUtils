//
//  RunError.swift
//  
//
//  Created by Ilya Kuznetsov on 09/02/2023.
//

import Foundation

public enum RunError: Error, Equatable, LocalizedError {
    case cancelled
    case timeout
    case custom(String)
    
    public static func == (lhs: RunError, rhs: RunError) -> Bool {
        switch lhs {
        case .cancelled: if case .cancelled = rhs { return true }
        case .timeout: if case .timeout = rhs { return true }
        case .custom(let message): if case .custom(let message2) = rhs { return message == message2 }
        }
        return false
    }
    
    public var errorDescription: String? {
        switch self {
        case .cancelled: return "Cancelled"
        case .timeout: return "Timeout"
        case .custom(let string): return string
        }
    }
}
