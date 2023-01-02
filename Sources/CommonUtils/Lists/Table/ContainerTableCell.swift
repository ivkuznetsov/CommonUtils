//
//  ContainerTableCell.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

public class ContainerTableCell: BaseTableViewCell {
    
    fileprivate var attachedView: PlatformView? {
        #if os(iOS)
        contentView.subviews.last
        #else
        subviews.last
        #endif
    }
    
    public func attach(viewToAttach: PlatformView, type: PlatformView.AttachType) {
        if viewToAttach == attachedView { return }
        
        #if os(iOS)
        backgroundColor = .clear
        #endif
        attachedView?.removeFromSuperview()
        attach(viewToAttach, type: type)
    }
}
