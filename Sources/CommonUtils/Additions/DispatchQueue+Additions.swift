//
//  DispatchQueue+Additions.swift
//  
//
//  Created by Ilya Kuznetsov on 18/11/2022.
//

import Foundation

public extension DispatchQueue {
    
    static func onMain(_ closure: @escaping ()->()) {
        if Thread.isMainThread {
            closure()
        } else {
            main.async(execute: closure)
        }
    }
}
