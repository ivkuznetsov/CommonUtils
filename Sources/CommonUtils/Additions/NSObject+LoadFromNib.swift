//
//  NSObject+LoadFromNib.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

public extension NSObject {
    
    static func loadFromNib(_ nib: String? = nil, owner: Any? = nil, bundle: Bundle = Bundle.main) -> Self {
        loadFrom(nib: nib ?? String(describing: self), owner: owner, type: self, bundle: bundle)
    }
    
    static func loadFrom<T: NSObject>(nib: String, owner: Any?, type: T.Type, bundle: Bundle = Bundle.main) -> T  {
        var resultBundle = Bundle.main
        if resultBundle.path(forResource: nib, ofType: "nib") == nil {
            resultBundle = Bundle(for: type)
        }
        if resultBundle.path(forResource: nib, ofType: "nib") == nil {
            resultBundle = bundle
        }
        #if os(iOS)
        let objects = resultBundle.loadNibNamed(nib, owner: owner, options: nil)
        return objects?.first(where: { $0 is T }) as! T // crash if didn't find
        #else
        var array: NSArray? = nil
        resultBundle.loadNibNamed(nib, owner: self, topLevelObjects: &array)
        return (array as! [Any]).first(where: { $0 is T }) as! T // crash if didn't find
        #endif
    }
}
