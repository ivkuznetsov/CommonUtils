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

public struct PagedContent {
    public let items: [AnyHashable]
    public let next: Any?
    
    public init(_ items: [AnyHashable], next: Any?) {
        self.items = items
        self.next = next
    }
}

open class PagingLoader<List: BaseList<L>, L: ListView>: NSObject, ObservableObject {
    
    @Published public var content: PagedContent?
    
    public let list: List
    
    public var loadPage: (_ offset: Any?, _ showLoading: Bool, _ completion: @escaping (WorkResult<PagedContent>)->()) -> () = { _, _, completion in
        completion(.success(PagedContent([], next: nil)))
    }
    public var updateItems: (PagedContent, FooterLoadingView?)->[AnyHashable] = { $0.items.appending($1) }
    
    public var shouldLoadMore: ()->Bool = { true }
    public var footerLoadingInset = CGSize.zero
    public var performOnRefresh: (()->())? = nil
    public var firstPageCache: (save: ([AnyHashable])->(), load: ()->[AnyHashable])? = nil {
        didSet {
            if content == nil, let items = firstPageCache?.load() {
                content = PagedContent(items, next: nil)
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
        list.view.scrollView.refreshControl = refreshControl
        
        list.view.scrollView.observe(\.contentOffset) { [weak self] _, _ in
            self?.loadMoreIfNeeded()
        }.retained(by: self)
        #else
        NotificationCenter.default.publisher(for: NSView.boundsDidChangeNotification).sink { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.loadMoreIfNeeded()
            }
        }.retained(by: self)
        #endif
        
        $content.sink { [weak self] content in
            if let wSelf = self, let content = content {
                list.set(wSelf.updateItems(content, content.next == nil ? nil : footer))
            }
        }.retained(by: self)
    }
    
    // manually reload starts from the first page, usualy you should run this method in viewDidLoad or viewWillAppear
    open func refresh(showLoading: Bool = false) {
        #if os(iOS)
        if list.view.scrollView.refreshControl != nil, showLoading {
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
        load(offset: nil, showLoading: showLoading, success: { [weak self] content in
            guard let wSelf = self else { return }
            
            if let currentFirst = wSelf.content?.items.first,
               content.items.reversed().contains(currentFirst),
               wSelf.content?.next != nil {
                wSelf.append(content, position: .toHead)
            } else {
                wSelf.append(content, position: .replace)
            }
            wSelf.firstPageCache?.save(content.items)
        })
    }
    
    open func loadMore() {
        #if os(iOS)
        performedLoading = true
        #endif
        load(offset: content?.next, showLoading: false, success: { [weak self] content in
            #if os(iOS)
            if content.items.count > 0 && content.next != nil {
                self?.performedLoading = false
            }
            #endif
            self?.append(content, position: .toTail)
        })
    }
    
    private var operationId: UUID?
    
    private func load(offset: Any?, showLoading: Bool, success: @escaping (PagedContent)->()) {
        isLoading = true
        
        #if os(iOS)
        if showLoading, let refreshControl = list.view.scrollView.refreshControl {
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
        
        let id = UUID()
        operationId = id
        
        loadPage(offset, showLoading, { [weak self] in
            guard let wSelf = self, wSelf.operationId == id else { return }
            
            wSelf.isLoading = false
            
            switch $0 {
            case .success(let content):
                wSelf.footer.state = .stop
                success(content)
                
                if content.next != nil {
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
        })
    }
    
    public enum AppendingPosition {
        case toHead
        case toTail
        case replace
    }
    
    open func append(_ content: PagedContent, position: AppendingPosition) {
        if position == .replace {
            self.content = content
        } else {
            var array = self.content?.items ?? []
            var set = Set(array)
            
            let itemsToAdd = position == .toHead ? content.items.reversed() : content.items
            
            itemsToAdd.forEach {
                if !set.contains($0) {
                    set.insert($0)
                    
                    if position == .toHead {
                        array.insert($0, at: 0)
                    } else {
                        array.append($0)
                    }
                }
            }
            self.content = PagedContent(array, next: content.next)
        }
    }
    
    private func checkFooterVisibiliry() -> Bool {
        if content?.next != nil {
            let inset = footerLoadingInset
            let scrollView = list.view.scrollView
            
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
        
        if allow && footer.state == .stop && !isLoading && footerVisisble && content != nil {
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
        if let refreshControl = list.view.scrollView.refreshControl {
            list.view.scrollView.contentOffset = CGPoint(x: 0, y: -refreshControl.bounds.size.height)
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
        let scrollView = list.view.scrollView
        
        if shouldEndRefreshing && !scrollView.isDecelerating && !scrollView.isDragging {
            shouldEndRefreshing = false
            DispatchQueue.main.async { [weak self] in
                self?.list.view.scrollView.refreshControl?.endRefreshing()
            }
        }
        if shouldBeginRefreshing {
            shouldBeginRefreshing = false
            internalRefresh(showLoading: true)
        }
    }

    private func endRefreshing() {
        let scrollView = list.view.scrollView
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
