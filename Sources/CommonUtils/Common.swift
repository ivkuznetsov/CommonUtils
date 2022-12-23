//
//  Common.swift
//

import Foundation

#if os(iOS)
import UIKit

public typealias PlatformView = UIView
public typealias PlatformTableView = UITableView
public typealias PlatformTableCell = UITableViewCell
public typealias PlatformTableViewAnimation = UITableView.RowAnimation
public typealias PlatformCollectionView = UICollectionView
public typealias PlatformCollectionCell = UICollectionViewCell

#else
import AppKit

public typealias PlatformView = NSView
public typealias PlatformTableView = NSTableView
public typealias PlatformTableCell = NSTableRowView
public typealias PlatformTableViewAnimation = NSTableView.AnimationOptions
public typealias PlatformCollectionView = NSCollectionView
public typealias PlatformCollectionCell = NSCollectionViewItem

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

public protocol CellSizeCachable {
    var cacheKey: String { get }
}

public extension AnyHashable {
    
    var cachedHeightKey: NSValue {
        if let object = self as? CellSizeCachable {
            return NSNumber(integerLiteral: object.cacheKey.hash)
        }
        return NSValue(nonretainedObject: self)
    }
}

public enum SelectionResult {
    case deselect
    case select
}

