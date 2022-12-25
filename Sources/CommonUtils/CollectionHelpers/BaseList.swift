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

public enum SelectionResult {
    case deselect
    case select
}

open class BaseList<List: PlatformView, DelegateType, CellSize, ContainerCell>: StaticSetupObject {
    
    public let list: List
    
    public private(set) var objects: [AnyHashable] = []
    
    public var visible: Bool = true {
        didSet {
            if visible && (visible != oldValue) && deferredReload && !updatingData {
                reloadVisibleCells()
            }
        }
    }
    
    open var noObjectsView: NoObjectsView!
    
    private weak var weakDeleage: AnyObject?
    public var delegate: DelegateType? { weakDeleage as? DelegateType }
    
    public var setupViewContainer: ((ContainerCell)->())?
    
    public init(list: List, delegate: DelegateType) {
        self.list = list
        weakDeleage = delegate as AnyObject
        super.init()
    }
    
    public convenience init(view: PlatformView, delegate: DelegateType) {
        self.init(list: Self.createList(in: view), delegate: delegate)
    }
    
    private var deferredReload = false
    private var updatingData = false
    
    private var deferredObjects: [AnyHashable]?
    private var updateCompletion: (()->())?
    
    public func moveObject(from: IndexPath, to: IndexPath) {
        let object = objects[from.item]
        objects.remove(at: from.item)
        objects.insert(object, at: to.item)
    }
    
    open func set(_ objects: [AnyHashable], animated: Bool = false, completion: (()->())? = nil) {
        updateCompletion = { [weak self] in
            guard let wSelf = self else { return }
            
            if wSelf.shouldShowNoData(wSelf.objects) {
                wSelf.list.attach(wSelf.noObjectsView, type: .safeArea)
            } else {
                wSelf.noObjectsView.removeFromSuperview()
            }
            wSelf.updatingData = false
            wSelf.updateCompletion = nil
            completion?()
        }
    
        if updatingData {
            deferredObjects = objects
        } else {
            updatingData = true
            internalUpdateList(objects, animated: animated)
        }
    }
    
    private func internalUpdateList(_ objects: [AnyHashable], animated: Bool) {
        updateList(objects, animated: animated, updateObjects: {
            
            if visible {
                deferredReload = false
                reloadVisibleCells(excepting: $0)
            } else {
                deferredReload = true
            }
            $0.forEach {
                if let key = (self.objects[$0] as? CellSizeCachable)?.cacheKey {
                    cachedSizes[key] = nil
                }
            }
            self.objects = objects
        }) { [weak self] in
            guard let wSelf = self else { return }
            
            if let objects = wSelf.deferredObjects {
                wSelf.deferredObjects = nil
                wSelf.internalUpdateList(objects, animated: false)
            } else {
                wSelf.updateCompletion?()
            }
        }
    }
    
    private var cachedSizes: [String:CellSize] = [:]
    
    public func cachedSize(for object: AnyHashable) -> CellSize? {
        if let key = (object as? CellSizeCachable)?.cacheKey {
            return cachedSizes[key]
        }
        return nil
    }
    
    public func cache(size: CellSize?, for object: AnyHashable) {
        if let key = (object as? CellSizeCachable)?.cacheKey {
            cachedSizes[key] = size
        }
    }
    
    open override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) ? true : ((delegate as? NSObject)?.responds(to: aSelector) ?? false)
    }
    
    open override func forwardingTarget(for aSelector: Selector!) -> Any? {
        super.responds(to: aSelector) ? self : delegate
    }
    
    open class func createList(in view: PlatformView) -> List { fatalError("override in subclass") }
    
    open func reloadVisibleCells(excepting: Set<Int> = Set()) { fatalError("override in subclass") }
    
    open func updateList(_ objects: [AnyHashable],
                         animated: Bool,
                         updateObjects: (_ excepting: Set<Int>)->(),
                         completion: @escaping ()->()) { fatalError("override in subclass") }
    
    open func shouldShowNoData(_ objects: [AnyHashable]) -> Bool { fatalError("override in subclass") }
}
