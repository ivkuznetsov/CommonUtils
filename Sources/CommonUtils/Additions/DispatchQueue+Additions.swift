//
//  DispatchQueue+Additions.swift
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
