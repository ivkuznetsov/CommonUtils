//
//  View+Additions.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

public extension PlatformView {
    
    enum AttachType {
        case constraints
        case layoutMargins
        case safeArea
        case autoresizing
    }
    
    func attach(_ view: PlatformView, type: AttachType = .constraints) {
        view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        addSubview(view)
        
        switch type {
        case .safeArea:
            if #available(iOS 13, macOS 11, *) {
                view.translatesAutoresizingMaskIntoConstraints = false
                safeAreaLayoutGuide.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
                safeAreaLayoutGuide.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
                safeAreaLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
                safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            } else {
                fallthrough
            }
        case .layoutMargins:
            if #available(iOS 13, macOS 11, *) {
                view.translatesAutoresizingMaskIntoConstraints = false
                layoutMarginsGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
                layoutMarginsGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
                layoutMarginsGuide.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
                layoutMarginsGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            } else {
                fallthrough
            }
        case .constraints:
            view.translatesAutoresizingMaskIntoConstraints = false
            leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            let constraint = bottomAnchor.constraint(equalTo: view.bottomAnchor)
            
            #if os(iOS)
            constraint.priority = UILayoutPriority(999)
            #else
            constraint.priority = NSLayoutConstraint.Priority(999)
            #endif
            constraint.isActive = true
        
        case .autoresizing:
            #if os(iOS)
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            #else
            view.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
            #endif
        }
    }
}