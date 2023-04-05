//
//  LoadingHelper.swift
//

import Foundation
import Combine

#if os(iOS)
import UIKit
#endif

@MainActor
public final class LoadingHelper: ObservableObject {
    
    public init() {}
    
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
    
    @Published public private(set) var processing: [String:TaskWrapper] = [:]
    @Published public private(set) var opaqueFail: Fail?
    
    public enum Options: Hashable {
        case showsProgress
    }
    
    public class TaskWrapper: Hashable, ObservableObject {
        
        @MainActor @Published public var progress: Double = 0
        public let presentation: Presentation
        
        private let id: String
        #if os(iOS)
        private var backgroundTaskId: UIBackgroundTaskIdentifier?
        #endif
        public var cancel: (()->())!
        
        @MainActor init(id: String, presentation: Presentation) {
            self.id = id
            self.presentation = presentation
            
            #if os(iOS)
            backgroundTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
                self?.endTask()
            }
            #endif
        }
        
        #if os(iOS)
        private func endTask() {
            if let task = backgroundTaskId {
                Task { @MainActor in
                    UIApplication.shared.endBackgroundTask(task)
                }
            }
        }
        #endif
        
        fileprivate func update(progress: Double) {
            Task { @MainActor in
                self.progress = progress
            }
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        public static func == (lhs: LoadingHelper.TaskWrapper, rhs: LoadingHelper.TaskWrapper) -> Bool { lhs.hashValue == rhs.hashValue }
        
        deinit {
            cancel()
            #if os(iOS)
            endTask()
            #endif
        }
    }
    
    public func run(_ presentation: Presentation,
                    id: String? = nil,
                    _ action: @escaping (_ progress: @escaping (Double)->()) async throws -> ()) {
        
        let id = id ?? UUID().uuidString
        
        let wrapper = TaskWrapper(id: id, presentation: presentation)
        
        let task = Task.detached { [weak self, weak wrapper] in
            do {
                try await action {
                    wrapper?.update(progress: $0)
                }
            } catch {
                if !error.isCancelled, let wSelf = self {
                    DispatchQueue.main.async {
                        let fail = Fail(error: error,
                                        retry: { [weak wSelf] in _ = wSelf?.run(presentation, id: id, action) },
                                        presentation: presentation)
                        
                        if case .opaque = presentation {
                            wSelf.opaqueFail = fail
                        }
                        wSelf.failPublisher.send(fail)
                    }
                }
            }
            await self?.removeProcessing(id: id)
        }
        wrapper.cancel = { task.cancel() }
        
        processing[id]?.cancel()
        processing[id] = wrapper
        
        if opaqueFail != nil {
            if case .opaque = presentation {
                opaqueFail = nil
            }
            #if os(iOS)
            if case .translucent = presentation {
               opaqueFail = nil
            }
            #endif
        }
        
        if task.isCancelled {
            processing[id] = nil
        }
    }
    
    private func removeProcessing(id: String) {
        processing[id] = nil
    }
    
    public func cancelOperations() {
        opaqueFail = nil
        processing.forEach { $0.value.cancel() }
    }
}
