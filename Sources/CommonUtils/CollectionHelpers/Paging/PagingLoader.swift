//
//  PagingLoader.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif
import Combine

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

public struct LoadedPage {
    public let items: [AnyHashable]
    public let offset: Any?
    
    public init(_ items: [AnyHashable], offset: Any?) {
        self.items = items
        self.offset = offset
    }
}

open class PagingLoader<List: BaseList<L>, L: ListView>: NSObject, ObservableObject {
    
    @Published public var page: LoadedPage?
    
    public let list: List
    
    public var load: (_ offset: Any?, _ showLoading: Bool)->Work<LoadedPage> = { _, _ in
        BlockWork { LoadedPage([], offset: nil) }
    }
    public var updateItems: (LoadedPage, FooterLoadingView?)->[AnyHashable] = { $0.items.appending($1) }
    
    public var shouldLoadMore: ()->Bool = { true }
    public var footerLoadingInset = CGSize.zero
    public var performOnRefresh: (()->())? = nil
    public var firstPageCache: (save: ([AnyHashable])->(), load: ()->[AnyHashable])? = nil {
        didSet {
            if page == nil, let items = firstPageCache?.load() {
                page = LoadedPage(items, offset: nil)
            }
        }
    }
    
    private let footer: FooterLoadingView
    private var isLoading = false
    
    public required init(_ list: List,
                         footer: FooterLoadingView = FooterLoadingView(),
                         hasRefreshControl: Bool = true) {
        
        self.list = list
        self.footer = footer
        super.init()
        
        list.delegate.add(self)
        
        footer.retry = { [unowned self] in
            self.loadMore()
        }
        #if os(iOS)
        let refreshControl = hasRefreshControl ? RefreshControl() : nil
        refreshControl?.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
        list.list.scrollView.refreshControl = refreshControl
        
        list.list.scrollView.observe(\.contentOffset) { [weak self] _, _ in
            self?.loadMoreIfNeeded()
        }.retained(by: self)
        #else
        NotificationCenter.default.publisher(for: NSView.boundsDidChangeNotification).sink { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.loadMoreIfNeeded()
            }
        }.retained(by: self)
        #endif
        
        $page.sink { [weak self] page in
            if let wSelf = self, let page = page {
                list.set(wSelf.updateItems(page, page.offset == nil ? nil : footer))
            }
        }.retained(by: self)
    }
    
    // manually reload starts from the first page, usualy you should run this method in viewDidLoad or viewWillAppear
    open func refresh(showLoading: Bool = false) {
        #if os(iOS)
        if list.list.scrollView.refreshControl != nil, showLoading {
            DispatchQueue.main.async { [weak self] in
                self?.internalRefresh(showLoading: true)
            }
            scrollOnRefreshing()
        } else {
            internalRefresh(showLoading: false)
        }
        #else
        internalRefresh(showLoading: showLoading)
        #endif
    }
    
    private func internalRefresh(showLoading: Bool) {
        performOnRefresh?()
        load(offset: nil, showLoading: showLoading).successOnMain { [weak self] page in
            guard let wSelf = self else { return }
            
            if let currentFirst = wSelf.page?.items.first,
               page.items.reversed().contains(currentFirst),
               wSelf.page?.offset != nil {
                wSelf.append(page: page, appending: .toHead)
            } else {
                wSelf.append(page: page, appending: .replace)
            }
            wSelf.firstPageCache?.save(page.items)
        }
    }
    
    open func loadMore() {
        #if os(iOS)
        performedLoading = true
        #endif
        load(offset: page?.offset, showLoading: false).successOnMain { [weak self] page in
            #if os(iOS)
            if page.items.count > 0 && page.offset != nil {
                self?.performedLoading = false
            }
            #endif
            self?.append(page: page, appending: .toTail)
        }
    }
    
    private weak var operation: WorkBase?
    
    private func load(offset: Any?, showLoading: Bool) -> Work<LoadedPage> {
        isLoading = true
        
        #if os(iOS)
        if showLoading, let refreshControl = list.list.scrollView.refreshControl {
            if !refreshControl.isRefreshing {
                refreshControl.beginRefreshing()
                scrollOnRefreshing()
            }
            footer.state = .stop
        } else {
            footer.state = .loading
        }
        #else
        footer.state = .loading
        #endif
        
        let operation = load(offset, showLoading)
        operation.completionOnMain { [weak self] in
            guard let wSelf = self, wSelf.operation == operation else { return }
            
            wSelf.isLoading = false
            
            switch $0 {
            case .success(let page):
                wSelf.footer.state = .stop
                
                if page.offset != nil {
                    DispatchQueue.main.async {
                        self?.loadMoreIfNeeded()
                    }
                }
            case .failure(let error):
                if error as? RunError == .cancelled || (error as NSError).code == NSURLErrorCancelled {
                    wSelf.footer.state = .stop
                } else {
                    wSelf.footer.state = .failed
                    
                    #if os(iOS)
                    if showLoading {
                        wSelf.processPullToRefreshError(wSelf, error)
                    }
                    #endif
                }
            }
            #if os(iOS)
            wSelf.endRefreshing()
            #endif
        }
        self.operation = operation
        return operation
    }
    
    public enum PageAppending {
        case toHead
        case toTail
        case replace
    }
    
    open func append(page: LoadedPage, appending: PageAppending) {
        if appending == .replace {
            self.page = page
        } else {
            var array = self.page?.items ?? []
            var set = Set(array)
            
            let itemsToAdd = appending == .toHead ? page.items.reversed() : page.items
            
            itemsToAdd.forEach {
                if !set.contains($0) {
                    set.insert($0)
                    
                    if appending == .toHead {
                        array.insert($0, at: 0)
                    } else {
                        array.append($0)
                    }
                }
            }
            self.page = LoadedPage(array, offset: page.offset)
        }
    }
    
    private func checkFooterVisibiliry() -> Bool {
        if page?.offset != nil {
            let inset = footerLoadingInset
            let scrollView = list.list.scrollView
            
            let frame = scrollView.convert(footer.bounds, from: footer).insetBy(dx: -inset.width, dy: -inset.height)
            
            return footer.isDescendant(of: scrollView) &&
                   (scrollView.contentSize.height > scrollView.height ||
                    scrollView.contentSize.width > scrollView.width ||
                    scrollView.contentSize.height > 0) &&
                   scrollView.bounds.intersects(frame)
        }
        return false
    }
    
    private func loadMoreIfNeeded() {
        guard shouldLoadMore() else { return }
        
        let footerVisisble = checkFooterVisibiliry()
        
        if footer.state == .failed && !footerVisisble {
            footer.state = .stop
        }
        #if os(iOS)
        let allow = !performedLoading
        #else
        let allow = true
        #endif
        
        if allow && footer.state == .stop && !isLoading && footerVisisble && page != nil {
            loadMore()
        }
    }
    
    #if os(iOS)
    public var processPullToRefreshError: (PagingLoader, Error)->() = { _, error in
        if let vc = UIViewController.topViewController {
            Alert.present(message: error.localizedDescription, on: vc)
        }
    }
    
    private var performedLoading = false
    private var shouldEndRefreshing = false
    private var shouldBeginRefreshing = false

    @objc private func refreshAction() {
        shouldBeginRefreshing = true
    }

    private func scrollOnRefreshing() {
        if let refreshControl = list.list.scrollView.refreshControl {
            list.list.scrollView.contentOffset = CGPoint(x: 0, y: -refreshControl.bounds.size.height)
        }
    }
    
    @objc func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        endDecelerating()
        
        list.delegate.without(self) {
            (list.delegate as? UIScrollViewDelegate)?.scrollViewDidEndDecelerating?(scrollView)
        }
    }
    
    @objc func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { endDecelerating() }
        
        list.delegate.without(self) {
            (list.delegate as? UIScrollViewDelegate)?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
        }
    }
    
    func endDecelerating() {
        performedLoading = false
        let scrollView = list.list.scrollView
        
        if shouldEndRefreshing && !scrollView.isDecelerating && !scrollView.isDragging {
            shouldEndRefreshing = false
            DispatchQueue.main.async { [weak self] in
                self?.list.list.scrollView.refreshControl?.endRefreshing()
            }
        }
        if shouldBeginRefreshing {
            shouldBeginRefreshing = false
            internalRefresh(showLoading: true)
        }
    }

    private func endRefreshing() {
        let scrollView = list.list.scrollView
        guard let refreshControl = scrollView.refreshControl else { return }
        
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
    #endif
}
