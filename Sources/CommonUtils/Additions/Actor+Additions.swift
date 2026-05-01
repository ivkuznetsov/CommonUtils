//
//  Actor+Additions.swift
//  CommonUtils
//
//  Created by Kuznetsov, Ilia on 01.05.26.
//

public extension Actor {
    
    func edit<T>(_ closure: (isolated Self) -> T) -> T {
        closure(self)
    }
}
