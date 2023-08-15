//
//  File.swift
//  
//
//  Created by Ilya Kuznetsov on 07/01/2023.
//

import Foundation

public extension Error {
    
    var isCancelled: Bool {
        self as? RunError == .cancelled || (self as NSError).code == NSURLErrorCancelled || self is CancellationError
    }
}
