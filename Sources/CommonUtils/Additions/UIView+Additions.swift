//
//  UIView+Additions.swift
//

#if os(iOS)

import UIKit

public extension UIView {
    
    enum AttachType {
        case constraints
        case layoutMargins
        case safeArea
        case autoresizing
    }
    
    func attach(_ view: UIView, type: AttachType = .constraints) {
        view.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        addSubview(view)
        
        switch type {
        case .constraints:
            view.translatesAutoresizingMaskIntoConstraints = false
            leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            let constraint = bottomAnchor.constraint(equalTo: view.bottomAnchor)
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
        case .layoutMargins:
            view.translatesAutoresizingMaskIntoConstraints = false
            layoutMarginsGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            layoutMarginsGuide.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            layoutMarginsGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        case .safeArea:
            view.translatesAutoresizingMaskIntoConstraints = false
            safeAreaLayoutGuide.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            safeAreaLayoutGuide.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            safeAreaLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        case .autoresizing:
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }
}

#endif
