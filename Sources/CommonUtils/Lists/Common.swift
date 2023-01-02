//
//  Common.swift
//

import Foundation

#if os(iOS)
import UIKit

public typealias PlatformView = UIView
public typealias PlatformViewController = UIViewController
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
public typealias PlatformScrollView = UIScrollView
public typealias PlatformTableDelegate = UITableViewDelegate
public typealias PlatformTableDataSource = UITableViewDataSource
public typealias PlatformCollectionDelegate = UICollectionViewDelegate
public typealias PlatformCollectionDataSource = UICollectionViewDataSource

#else
import AppKit

public typealias PlatformView = NSView
public typealias PlatformViewController = NSViewController
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
public typealias PlatformScrollView = NSScrollView
public typealias PlatformTableDelegate = NSTableViewDelegate
public typealias PlatformTableDataSource = NSTableViewDataSource
public typealias PlatformCollectionDelegate = NSCollectionViewDelegate
public typealias PlatformCollectionDataSource = NSCollectionViewDataSource
#endif
