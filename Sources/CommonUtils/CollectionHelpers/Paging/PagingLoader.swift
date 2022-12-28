//
//  PagingLoader.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

#if os(iOS)
class RefreshControl: UIRefreshControl {
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window != nil && isRefreshing, let scrollView = superview as? UIScrollView {
            let offset = scrollView.contentOffset
            UIView.performWithoutAnimation { endRefreshing() }
            beginRefreshing()
            scrollView.contentOffset = offset
        }
    }
}
#endif

public protocol PagingLoaderDelegate: AnyObject {
    
    func shouldLoadMore() -> Bool

    func pagingLoader() -> PagingLoader.Type
    
    func reloadView(_ animated: Bool)
    
    func load(offset: Any?, showLoading: Bool, completion: @escaping ([AnyHashable]?, Error?, _ offset: Any?)->())
    
    func performOnRefresh()
    
    #if os(iOS)
    func hasRefreshControl() -> Bool
    #endif
}

public extension PagingLoaderDelegate {
    
    func shouldLoadMore() -> Bool { true }
    
    func pagingLoader() -> PagingLoader.Type { PagingLoader.self }
    
    func performOnRefresh() { }
    
    #if os(iOS)
    func hasRefreshControl() -> Bool { true }
    #endif
}

public protocol PagingCachable: AnyObject {
 
    func saveFirstPageInCache(objects: [AnyHashable])
    
    func loadFirstPageFromCache() -> [AnyHashable]
}

open class PagingLoader: StaticSetupObject {
    
    public var footerLoadingInset = CGSize.zero
    
    public var footerLoadingView: FooterLoadingView! {
        didSet {
            footerLoadingView.retry = { [unowned self] in
                self.loadMore()
            }
        }
    }
    
    public private(set) var isLoading = false
    public private(set) weak var scrollView: PlatformScrollView?
    public private(set) weak var delegate: PagingLoaderDelegate?
    
    public var fetchedItems: [AnyHashable] = []
    public var offset: Any?
    
    private var currentOperationId: UUID?
    
    private var setFooterVisible: (Bool, FooterLoadingView)->()
    public var footerVisible: Bool = false {
        didSet {
            if oldValue != footerVisible {
                setFooterVisible(footerVisible, footerLoadingView)
            }
        }
    }

    public required init(scrollView: PlatformScrollView,
                         delegate: PagingLoaderDelegate,
                         setFooterVisible: @escaping (_ visible: Bool, _ footer: PlatformView)->()) {
        self.scrollView = scrollView
        self.delegate = delegate
        self.setFooterVisible = setFooterVisible
        super.init()
        
        fetchedItems = (delegate as? PagingCachable)?.loadFirstPageFromCache() ?? []
        
        #if os(iOS)
        if delegate.hasRefreshControl() {
            let refreshControl = RefreshControl()
            refreshControl.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
            scrollView.refreshControl = refreshControl
            self.refreshControl = refreshControl
        }
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
        #else
        NotificationCenter.default.publisher(for: NSView.boundsDidChangeNotification).sink { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.loadMoreIfNeeded()
            }
        }.retained(by: self)
        #endif
    }
    
    open func set(fetchedItems: [AnyHashable], offset: Any?) {
        self.fetchedItems = fetchedItems
        self.offset = offset
        footerVisible = offset != nil
    }
    
    // manually reload starts from the first page, usualy you should run this method in viewDidLoad or viewWillAppear
    open func refresh(showLoading: Bool) {
        #if os(iOS)
        if let refreshControl = refreshControl, showLoading {
            DispatchQueue.main.async { [weak self] in
                self?.internalRefresh(showLoading: true)
            }
            scrollOnRefreshing(refreshControl)
        } else {
            internalRefresh(showLoading: false)
        }
        #else
        internalRefresh(showLoading: showLoading)
        #endif
    }
    
    private func internalRefresh(showLoading: Bool) {
        delegate?.performOnRefresh()
        load(offset: nil, showLoading: showLoading) { [weak self] objects, newOffset in
            guard let wSelf = self else { return }
            
            if let currentFirst = wSelf.fetchedItems.first,
                objects.reversed().contains(currentFirst),
                wSelf.offset != nil {
                wSelf.append(items: objects, fromBeginning: true)
            } else {
                wSelf.offset = newOffset
                wSelf.fetchedItems = []
                wSelf.append(items: objects)
            }
            (wSelf.delegate as? PagingCachable)?.saveFirstPageInCache(objects: objects)
        }
    }
    
    open func loadMore() {
        #if os(iOS)
        performedLoading = true
        #endif
        load(offset: offset, showLoading: false) { [weak self] objects, newOffset in
            #if os(iOS)
            if objects.count > 0 && newOffset != nil {
                self?.performedLoading = false
            }
            #endif
            self?.offset = newOffset
            self?.append(items: objects)
        }
    }
    
    private func load(offset: Any?, showLoading: Bool, success: @escaping ([AnyHashable], _ newOffset: Any?)->()) {
        isLoading = true
        
        #if os(iOS)
        if showLoading, let refreshControl = refreshControl {
            if !refreshControl.isRefreshing {
                refreshControl.beginRefreshing()
                scrollOnRefreshing(refreshControl)
            }
            footerLoadingView.state = .stop
        } else {
            footerLoadingView.state = .loading
        }
        #else
        footerLoadingView.state = .loading
        #endif
        
        let operationId = UUID()
        currentOperationId = operationId
        
        delegate?.load(offset: offset, showLoading: showLoading, completion: { [weak self] (objects, error, newOffset) in
            guard let wSelf = self, wSelf.delegate != nil, wSelf.currentOperationId == operationId else { return }
            
            wSelf.isLoading = false
            if let error = error {
                
                if error as? RunError == .cancelled || (error as NSError).code == NSURLErrorCancelled {
                    wSelf.footerLoadingView.state = .stop
                } else {
                    wSelf.footerLoadingView.state = .failed
                    
                    #if os(iOS)
                    if showLoading {
                        wSelf.processPullToRefreshError(wSelf, error)
                    }
                    #endif
                }
                wSelf.footerLoadingView.state = ((error as? RunError) == .cancelled || (error as NSError).code == NSURLErrorCancelled) ? .stop : .failed
            } else {
                success(objects ?? [], newOffset)
                
                wSelf.footerVisible = wSelf.offset != nil
                wSelf.footerLoadingView.state = .stop
                
                if wSelf.offset != nil {
                    DispatchQueue.main.async {
                        self?.loadMoreIfNeeded()
                    }
                }
            }
            #if os(iOS)
            wSelf.endRefreshing()
            #endif
        })
    }
    
    open func append(items: [AnyHashable], fromBeginning: Bool = false) {
        guard let delegate = delegate else { return }
        
        var array = fetchedItems
        var set = Set(array)
        
        let itemsToAdd = fromBeginning ? items.reversed() : items
        
        itemsToAdd.forEach {
            if !set.contains($0) {
                set.insert($0)
                
                if fromBeginning {
                    array.insert($0, at: 0)
                } else {
                    array.append($0)
                }
            }
        }
        fetchedItems = array
        delegate.reloadView(false)
    }
    
    open func filterFetchedItems(_ closure: (AnyHashable)->Bool) {
        let oldCount = fetchedItems.count
        fetchedItems = fetchedItems.compactMap { closure($0) ? $0 : nil }
        if oldCount != fetchedItems.count {
            delegate?.reloadView(false)
        }
    }
    
    private func isFooterVisible() -> Bool {
        if let scrollView = scrollView, footerVisible {
            let frame = scrollView.convert(footerLoadingView.bounds, from: footerLoadingView).insetBy(dx: -footerLoadingInset.width, dy: -footerLoadingInset.height)
            return footerLoadingView.isDescendant(of: scrollView) &&
                   (scrollView.contentSize.height > scrollView.height ||
                    scrollView.contentSize.width > scrollView.width ||
                    scrollView.contentSize.height > 0) &&
                   scrollView.bounds.intersects(frame)
        }
        return false
    }
    
    private func loadMoreIfNeeded() {
        if let delegate = delegate, delegate.shouldLoadMore() {
            let footerVisisble = isFooterVisible()
            
            if footerLoadingView.state == .failed && !footerVisisble {
                footerLoadingView.state = .stop
            }
            #if os(iOS)
            let allow = !performedLoading
            #else
            let allow = true
            #endif
            
            if allow && footerLoadingView.state == .stop && !isLoading && footerVisisble && fetchedItems.count != 0 {
                loadMore()
            }
        }
    }
    
    #if os(iOS)
    open var processPullToRefreshError: ((PagingLoader, Error)->())!

    open private(set) var refreshControl: UIRefreshControl?

    public var scrollOnRefreshing: ((UIRefreshControl)->())!

    private var performedLoading = false
    private var shouldEndRefreshing = false
    private var shouldBeginRefreshing = false

    @objc private func refreshAction() {
        shouldBeginRefreshing = true
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if delegate != nil && keyPath == "contentOffset" {
            loadMoreIfNeeded()
        }
    }

    public func endDecelerating() {
        performedLoading = false
        if shouldEndRefreshing && scrollView?.isDecelerating == false && scrollView?.isDragging == false {
            shouldEndRefreshing = false
            DispatchQueue.main.async { [weak self] in
                self?.refreshControl?.endRefreshing()
            }
        }
        if shouldBeginRefreshing {
            shouldBeginRefreshing = false
            internalRefresh(showLoading: true)
        }
    }

    private func endRefreshing() {
        guard let refreshControl = refreshControl, let scrollView = scrollView else { return }
        
        if scrollView.isDecelerating || scrollView.isDragging {
            shouldEndRefreshing = true
        } else if scrollView.window != nil && refreshControl.isRefreshing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                refreshControl.endRefreshing()
            })
        } else {
            refreshControl.endRefreshing()
        }
    }
    
    deinit {
        scrollView?.removeObserver(self, forKeyPath: "contentOffset")
    }
    #endif
}
