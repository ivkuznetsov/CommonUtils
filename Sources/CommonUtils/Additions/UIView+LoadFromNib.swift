//
//  UIView+LoadFromNib.swift
//

#if os(iOS)
import UIKit

public typealias View = UIView

#else
import AppKit

public typealias View = NSView

#endif

public extension View {
    
    static func loadFromNib() -> Self {
        loadFrom(nib: String(describing: self))
    }
    
    static func loadFrom(nib: String, owner: Any? = nil) -> Self {
        loadFrom(nib: nib, owner: owner, type: self)
    }
    
    static func loadFrom<T: View>(nib: String, owner: Any?, type: T.Type) -> T  {
        var bundle = Bundle.main
        if bundle.path(forResource: nib, ofType: "nib") == nil {
            bundle = Bundle(for: type)
        }
        
        var objects: [Any] = []
        
        #if os(iOS)
        objects = bundle.loadNibNamed(nib, owner: owner, options: nil) ?? []
        #else
        var array: NSArray? = nil
        Bundle.main.loadNibNamed(nib, owner: self, topLevelObjects: &array)
        objects = (array ?? []) as! [Any]
        #endif
        
        return objects.first(where: { $0 is T }) as! T // crash if didn't find
    }
}
