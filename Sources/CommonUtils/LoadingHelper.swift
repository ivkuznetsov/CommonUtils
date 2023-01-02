//
//  LoadingHelper.swift
//  
//
//  Created by Ilya Kuznetsov on 27/12/2022.
//

import Combine

public class LoadingHelper: ObservableObject {

    public init() { }
    
    public enum Presentation {
        
        // fullscreen opaque overlay loading with fullscreen opaque error
        case opaque
        
        // fullscreen semitransparent overlay loading with alert error
        #if os(iOS)
        case translucent
        #else
        case modal(details: String, cancellable: Bool)
        #endif
        
        // doesn't show loading, error is shown in alert
        case alertOnFail
        
        // shows loading bar at the top of the screen without blocking the content, error is shown as label at the top for couple of seconds
        case nonblocking
        
        case none
    }
    
    public struct Fail {
        public let error: Error
        public let retry: (()->())?
        public let presentation: Presentation
    }
    
    private let failPublisher = PassthroughSubject<Fail, Never>()
    public var didFail: AnyPublisher<Fail, Never> { failPublisher.eraseToAnyPublisher() }
    
    private var keyedWorks: [String:WorkBase] = [:]
    @Published public private(set) var processing: [WorkBase:(progress: WorkProgress?, presentation: Presentation)] = [:]
    
    // progress indicator becomes visible on first Progress block performing
    // 'key' is needed to cancel previous launched operation with the same key
    public enum Options: Hashable {
        case showsProgress
        case prohibitRetry
    }
    
    @discardableResult
    public func run<T>(_ presentation: Presentation, reuseKey: String? = nil, options: Set<Options> = Set(), _ makeWork: @escaping ()->Work<T>?) -> Work<T> {
        
        guard let work = makeWork() else {
            return .fail(RunError.cancelled)
        }
        
        processing[work] = (options.contains(.showsProgress) ? work.progress : nil, presentation)
        
        if let key = reuseKey {
            keyedWorks[key]?.cancel()
            keyedWorks[key] = work
        }
        
        work.runWith { [weak self, weak work] error in
            guard let wSelf = self, let work = work else { return }
            
            if let key = reuseKey, wSelf.keyedWorks[key] == work {
                wSelf.keyedWorks[key] = nil
            }
            if let error = error {
                let retry = options.contains(.prohibitRetry) ? nil : { _ = self?.run(presentation,
                                                                                     reuseKey: reuseKey,
                                                                                     options: options,
                                                                                     makeWork) }
                
                wSelf.failPublisher.send(Fail(error: error, retry: retry, presentation: presentation))
            }
            wSelf.processing[work] = nil
        }
        return work
    }
    
    public func cancelOperations() {
        processing.forEach { $0.key.cancel() }
    }
    
    deinit {
        cancelOperations()
    }
}
