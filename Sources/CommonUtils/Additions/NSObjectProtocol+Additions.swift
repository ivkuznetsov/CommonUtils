//
//  NSObjectProtocol.swift
//  
//
//  Created by Ilya Kuznetsov on 24/12/2022.
//

import Foundation

public extension NSObjectProtocol {
    
    func retained(by object: AnyObject) {
        var key = UUID().uuidString
        objc_setAssociatedObject(object, &key, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
