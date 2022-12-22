//
//  StaticSetup.swift
//

import Foundation

open class StaticSetupObject: NSObject {
    
    private static var setupClosure: ((StaticSetupObject)->())?
    
    public static func setupInstances(_ closure: @escaping (Self)->()) {
        setupClosure = { closure($0 as! Self) }
    }
    
    public override init() {
        super.init()
        type(of: self).setupClosure?(self)
    }
}
