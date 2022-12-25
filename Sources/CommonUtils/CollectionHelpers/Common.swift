//
//  Common.swift
//

import Foundation

#if os(iOS)
import UIKit

public typealias PlatformView = UIView
public typealias PlatformButton = UIButton

public typealias PlatformTableView = UITableView
public typealias PlatformTableCell = UITableViewCell
public typealias PlatformTableViewAnimation = UITableView.RowAnimation
public typealias PlatformCollectionView = UICollectionView
public typealias PlatformCollectionCell = UICollectionViewCell
public typealias PlatformCollectionFlowLayout = UICollectionViewFlowLayout
public typealias PlatformLayoutAttribute = UICollectionViewLayoutAttributes
public typealias PlatformRect = CGRect
public typealias PlatformLayoutDelegate = UICollectionViewDelegateFlowLayout
public typealias PlatformInset = UIEdgeInsets
public typealias PlatformInvalidationContext = UICollectionViewLayoutInvalidationContext

#else
import AppKit

public typealias PlatformView = NSView
public typealias PlatformButton = NSButton

public typealias PlatformTableView = NSTableView
public typealias PlatformTableCell = NSTableRowView
public typealias PlatformTableViewAnimation = NSTableView.AnimationOptions
public typealias PlatformCollectionView = NSCollectionView
public typealias PlatformCollectionCell = NSCollectionViewItem
public typealias PlatformCollectionFlowLayout = NSCollectionViewFlowLayout
public typealias PlatformLayoutAttribute = NSCollectionViewLayoutAttributes
public typealias PlatformRect = NSRect
public typealias PlatformLayoutDelegate = NSCollectionViewDelegateFlowLayout
public typealias PlatformInset = NSEdgeInsets
public typealias PlatformInvalidationContext = NSCollectionViewLayoutInvalidationContext

#endif

public extension PlatformTableView {
    
    struct Cell {
        public let type: PlatformTableCell.Type
        public let fill: (PlatformTableCell)->()
        
        public init<T: PlatformTableCell>(_ type: T.Type, _ fill: ((T)->())? = nil) {
            self.type = type
            self.fill = { fill?($0 as! T) }
        }
    }
}

public extension PlatformCollectionView {
    
    struct Cell {
        public let type: PlatformCollectionCell.Type
        public let fill: (PlatformCollectionCell)->()
        
        public init<T: PlatformCollectionCell>(_ type: T.Type, _ fill: ((T)->())? = nil) {
            self.type = type
            self.fill = { fill?($0 as! T) }
        }
    }
}

