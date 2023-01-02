//
//  List+SwiftUI.swift
//  
//
//  Created by Ilya Kuznetsov on 31/12/2022.
//

import SwiftUI

#if os(iOS)
public typealias GridLayout = Layout<Collection, CollectionView>

public typealias ListLayout = Layout<Table, PlatformTableView>

public typealias PagingGridLayout = PagingLayout<Collection, CollectionView>

public typealias PagingListLayout = PagingLayout<Table, PlatformTableView>

public class ListViewController<List: BaseList<R>, R>: PlatformViewController {
    
    fileprivate let list: List
    
    init(list: List? = nil) {
        self.list = list ?? List(emptyStateView: PlatformView())
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        list.attachTo(view)
    }
}

public struct Layout<List: BaseList<R>, R>: UIViewControllerRepresentable {
    public typealias UIViewControllerType = ListViewController<List, R>
    
    private let items: [AnyHashable]
    private let cells: [R.Cell]
    private let setup: ((List)->())?
    
    public init(_ items: [AnyHashable], cells: [R.Cell] = [], setup: ((List)->())? = nil) {
        self.items = items
        self.cells = cells
        self.setup = setup
    }
    
    public func makeUIViewController(context: Context) -> UIViewControllerType {
        let vc = UIViewControllerType()
        vc.list.set(cellsInfo: cells)
        setup?(vc.list)
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        uiViewController.list.set(items, animated: true)
    }
}

public struct PagingLayout<List: BaseList<R>, R>: UIViewControllerRepresentable {
    public typealias UIViewControllerType = ListViewController<List, R>
    
    private let loader: PagingLoader<List, R>
    private let cells: [R.Cell]
    private let setup: ((PagingLoader<List, R>)->())?
    
    public init(_ loader: PagingLoader<List, R>, cells: [R.Cell] = [], setup: ((PagingLoader<List, R>)->())? = nil) {
        self.loader = loader
        self.cells = cells
        self.setup = setup
    }
    
    public func makeUIViewController(context: Context) -> UIViewControllerType {
        loader.list.set(cellsInfo: cells)
        setup?(loader)
        return UIViewControllerType(list: loader.list)
    }
    
    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}

class DataCollectionCell: PlatformCollectionCell { }
class DataTableCell: BaseTableViewCell { }

@available(iOS 16, *)
extension CollectionCell {
    
    public init<R: Hashable>(_ item: R.Type,
                             _ fill: @escaping (R)-> any View,
                             size: @escaping (R)->CGSize,
                             action: @escaping (R)->SelectionResult = { _ in .deselect }) {
        
        self.init(item,
                  DataCollectionCell.self,
                  { item, cell in
                    cell.contentConfiguration = UIHostingConfiguration { fill(item).asAny }
                  },
                  identifier: String(describing: item),
                  source: .code,
                  size: size,
                  action: action)
    }
}

@available(iOS 16, *)
extension TableCell {
    
    public init<R: Hashable>(_ item: R.Type,
                             _ fill: @escaping (R)-> any View,
                             estimatedHeight: @escaping (R)->CGFloat = { _ in 150 },
                             height: @escaping (R)->CGFloat = { _ in -1 },
                             action: @escaping (R)->SelectionResult = { _ in .deselect },
                             editor: ((R)->TableCell.Editor)? = nil,
                             prefetch: ((R)->Table.Cancel)? = nil) {
        
        self.init(item,
                  DataTableCell.self,
                  { item, cell in
                    cell.contentConfiguration = UIHostingConfiguration { fill(item).asAny }
                  },
                  identifier: String(describing: item),
                  source: .code,
                  estimatedHeight: estimatedHeight,
                  height: height,
                  action: action,
                  editor: editor,
                  prefetch: prefetch)
    }
}

#endif
