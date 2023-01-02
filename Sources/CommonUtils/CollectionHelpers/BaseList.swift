//
//  BaseList.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

public protocol CellSizeCachable {
    var cacheKey: String { get }
}

public enum CellSource {
    case nib
    case code
}

public enum SelectionResult {
    case deselect
    case select
}

struct CellInfo<CellView, Size> {
    let itemType: any Hashable.Type
    let type: CellView.Type
    let fill: (AnyHashable, CellView)->()
    let identifier: String
    let source: CellSource
    let size: (AnyHashable)->Size
    let action: (AnyHashable)->SelectionResult
}

public protocol ListCell {
    var itemType: any Hashable.Type { get }
}

public protocol ListView: PlatformView {
    associatedtype Cell: ListCell
    associatedtype CellSize
    associatedtype ContainerCell
    
    var scrollView: PlatformScrollView { get }
}

open class BaseList<List: ListView>: NSObject {
    
    public let list: List
    
    public var showNoData: ([AnyHashable]) -> Bool = { $0.isEmpty }
    
    public func set(cellsInfo: [List.Cell]) {
        self.cells = cellsInfo.reduce(into: [:], { result, cell in
            result[String(describing: cell.itemType)] = cell
        })
    }
    
    public private(set) var items: [AnyHashable] = []
    
    public var visible: Bool = true {
        didSet {
            if visible && (visible != oldValue) && deferredReload && !updatingData {
                reloadVisibleCells()
            }
        }
    }
    
    public let emptyStateView: PlatformView
    
    public let delegate = DelegateForwarder()
    
    public var setupViewContainer: ((List.ContainerCell)->())?
    
    public required init(list: List? = nil, emptyStateView: PlatformView) {
        self.list = list ?? Self.createDefaultList()
        self.emptyStateView = emptyStateView
        super.init()
    }
    
    private var deferredReload = false
    private var updatingData = false
    var cells: [String:List.Cell] = [:]
    
    private var deferredItems: [AnyHashable]?
    private var updateCompletion: (()->())?
    
    open func set(_ items: [AnyHashable], animated: Bool = false, completion: (()->())? = nil) {
        updateCompletion = { [weak self] in
            guard let wSelf = self else { return }
            
            if wSelf.showNoData(wSelf.items) {
                wSelf.list.attach(wSelf.emptyStateView, type: .safeArea)
            } else {
                wSelf.emptyStateView.removeFromSuperview()
            }
            wSelf.updatingData = false
            wSelf.updateCompletion = nil
            completion?()
        }
    
        if updatingData {
            deferredItems = items
        } else {
            updatingData = true
            internalUpdate(items, animated: animated)
        }
    }
    
    private func internalUpdate(_ items: [AnyHashable], animated: Bool) {
        update(items, animated: animated, reloadCells: {
            
            if visible {
                deferredReload = false
                reloadVisibleCells(excepting: $0)
            } else {
                deferredReload = true
            }
            $0.forEach {
                if let key = (self.items[$0] as? CellSizeCachable)?.cacheKey {
                    cachedSizes[key] = nil
                }
            }
            self.items = items
        }) { [weak self] in
            guard let wSelf = self else { return }
            
            if let items = wSelf.deferredItems {
                wSelf.deferredItems = nil
                wSelf.internalUpdate(items, animated: false)
            } else {
                wSelf.updateCompletion?()
            }
        }
    }
    
    func cell(_ item: AnyHashable) -> List.Cell? { cells[String(describing: type(of: item.base))] }
    
    private var cachedSizes: [String:List.CellSize] = [:]
    
    public func cachedSize(for item: AnyHashable) -> List.CellSize? {
        if let key = (item as? CellSizeCachable)?.cacheKey {
            return cachedSizes[key]
        }
        return nil
    }
    
    public func cache(size: List.CellSize?, for item: AnyHashable) {
        if let key = (item as? CellSizeCachable)?.cacheKey {
            cachedSizes[key] = size
        }
    }
    
    public func attachTo(_ view: PlatformView) {
        view.attach(list.scrollView)
    }
    
    open class func createDefaultList() -> List { fatalError("override in subclass") }
    
    open func reloadVisibleCells(excepting: Set<Int> = Set()) { fatalError("override in subclass") }
    
    open func update(_ item: [AnyHashable],
                     animated: Bool,
                     reloadCells: (_ excepting: Set<Int>)->(),
                     completion: @escaping ()->()) { fatalError("override in subclass") }
}
