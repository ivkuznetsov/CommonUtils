//
//  NSObject+Additions.swift
//

import Foundation

public extension NSObject {
    
    static func classNameWithoutModule() -> String {
        String(describing: self).components(separatedBy: ".").last!
    }
    
    func classNameWithoutModule() -> String {
        type(of: self).classNameWithoutModule()
    }
}
