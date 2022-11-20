//
//  Work.swift
//

import Foundation

public typealias VoidWork = Work<Void>

public typealias WorkResult<T> = Result<T, Error>

public extension WorkResult {
    
    var error: Error? {
        switch self {
        case .success(_): return nil
        case .failure(let error): return error
        }
    }
    
    var value: Success? {
        switch self {
        case .success(let value): return value
        case .failure(_): return nil
        }
    }
}

public enum RunError: Error, Equatable, LocalizedError {
    case cancelled
    case notImplemented
    case timeout
    case custom(String)
    
    public static func == (lhs: RunError, rhs: RunError) -> Bool {
        switch lhs {
        case .cancelled: if case .cancelled = rhs { return true }
        case .notImplemented: if case .notImplemented = rhs { return true }
        case .timeout: if case .timeout = rhs { return true }
        case .custom(let message): if case .custom(let message2) = rhs { return message == message2 }
        }
        return false
    }
    
    public var errorDescription: String? {
        switch self {
        case .cancelled: return "Cancelled"
        case .notImplemented: return "Not Implemented"
        case .timeout: return "Timeout"
        case .custom(let string): return string
        }
    }
}

extension WorkBase: Cancellable {}

open class WorkBase: Operation {
    
    public let progress: WorkProgress
    
    public enum State: Int {
        case initial
        case pending
        case executing
        case finished
    }
    
    let stateLock = NSLock()
    fileprivate var state: State = .initial
    
    @RWAtomic public private(set) var queue: WorkQueue?
    @RWAtomic private var completionBlocks: [()->()] = []
    
    public var isEnqueued: Bool { stateLock.locking { state != .initial } }
    public override var isExecuting: Bool { stateLock.locking { state == .executing } }
    public override var isFinished: Bool { stateLock.locking { state == .finished } }
    
    public init(progress: WorkProgress = .init()) {
        self.progress = progress
        super.init()
        
        completionBlock = { [weak self] in
            self?.completionBlocks.forEach({ $0() })
        }
    }
    
    open func execute() {
        fatalError("\(type(of: self)) must override `execute()`.")
    }
    
    open func reject(_ error: Error) {
        fatalError("\(type(of: self)) must override `reject(_:)`.")
    }
    
    open var error: Error? { fatalError("\(type(of: self)) must override `var error`.") }
    
    public func addCompletion(_ block: @escaping ()->()) {
        _completionBlocks.mutate { $0.append(block) }
    }
    
    func addTo(_ queue: WorkQueue) -> Bool {
        stateLock.locking {
            if state == .initial {
                self.queue = queue
                state = .pending
                return true
            } else {
                return false
            }
        }
    }
}

open class Work<T>: WorkBase {
    
    private enum Key: String {
        case executing = "isExecuting"
        case finished = "isFinished"
    }
    
    @RWAtomic public private(set) var result: WorkResult<T>?
    @RWAtomic private var processingTimeout: DispatchWorkItem?
    
    public override init(progress: WorkProgress = .init()) {
        super.init(progress: progress)
    }
    
    public init(result: T) {
        super.init()
        self.result = .success(result)
    }
    
    public init(_ error: Error) {
        super.init()
        self.result = .failure(error)
    }
    
    public func finish(_ result: WorkResult<T>) {
        willChangeValue(forKey: Key.executing.rawValue)
        willChangeValue(forKey: Key.finished.rawValue)
        
        let shouldCancel: Bool = stateLock.locking {
            let finalResult: WorkResult<T> = self.result ?? result
            
            if self.result == nil {
                self.result = finalResult
            }
            
            if state != .executing { return false }
            
            processingTimeout?.cancel()
            
            if finalResult.error == nil {
                progress.update(1)
            }
            state = .finished
            
            return finalResult.error as? RunError == .cancelled
        }
        didChangeValue(forKey: Key.executing.rawValue)
        didChangeValue(forKey: Key.finished.rawValue)
        
        if shouldCancel {
            super.cancel()
        }
    }
    
    public override func start() {
        processingTimeout = DispatchWorkItem(block: { [weak self] in
            if let wSelf = self, !wSelf.isFinished {
                print("The operation has not been finished in 5min after start: \(wSelf)")
            }
        })
        DispatchQueue.global().asyncAfter(deadline: .now() + 60 * 5, execute: processingTimeout!)
        
        super.start()
    }
    
    open override func cancel() {
        reject(RunError.cancelled)
    }
    
    override public func main() {
        willChangeValue(forKey: Key.executing.rawValue)
        stateLock.locking { state = .executing }
        didChangeValue(forKey: Key.executing.rawValue)
        
        if let result = result {
            finish(result)
            return
        }
        
        do {
            resolve(try executeSync())
        } catch RunError.notImplemented {
            execute()
        } catch {
            reject(error)
        }
    }
    
    open func executeSync() throws -> T {
        throw RunError.notImplemented
    }
    
    override open func reject(_ error: Error) {
        finish(.failure(error))
    }
    
    public func resolve(_ value: T) {
        finish(.success(value))
    }
    
    public override var error: Error? { result?.error }
    
    deinit {
        processingTimeout?.cancel()
    }
}
