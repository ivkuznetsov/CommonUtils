//
//  NoObjectsView.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

open class NoObjectsView: PlatformView {
    
    #if os(iOS)
    @IBOutlet public var image: UIImageView!
    @IBOutlet public var header: UILabel!
    @IBOutlet public var details: UILabel!
    #else
    @IBOutlet public var image: NSImageView!
    @IBOutlet public var header: NSTextField!
    @IBOutlet public var details: NSTextField!
    #endif
    
    @IBOutlet public var actionButton: PlatformButton!
    
    public var actionClosure: (()->())? {
        didSet { actionButton.isHidden = actionClosure == nil }
    }
    
    @objc public func action(_ sender: Any) {
        actionClosure?()
    }
    
    #if os(iOS)
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if actionButton?.frame.contains(point) == true {
            return super.hitTest(point, with: event)
        }
        return nil
    }
    #endif
}
