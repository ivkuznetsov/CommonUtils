//
//  File.swift
//  
//
//  Created by Ilya Kuznetsov on 30/03/2023.
//

import SwiftUI

public extension Animation {
    
    static var shortEaseOut: Animation {
        .spring(response: 0.3)
    }
}

public func shortAnimation<Result>(_ body: () throws -> Result) rethrows -> Result {
    try withAnimation(.shortEaseOut, body)
}


