//
//  Work.swift
//

import Foundation

public typealias VoidWork = Work<Void>

public typealias WorkResult<T> = Result<T, Error>

extension WorkResult {
    
    public var error: Error? {
        switch self {
        case .success(_): return nil
        case .failure(let error): return error
        }
    }
    
    public var value: Success? {
        switch self {
        case .success(let value): return value
        case .failure(_): return nil
        }
    }
}

public enum RunError: Error, Equatable {
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
}

extension Operation: Cancellable {}

open class WorkBase: Operation {
    
    enum Key: String {
        case executing = "isExecuting"
        case finished = "isFinished"
    }
    
    let addToQueueLock = NSLock()
    
    public let progress: WorkProgress
    
    public enum State: Int {
        case initial
        case executing
        case finished
    }
    
    let stateLock = NSLock()
    fileprivate var state: State = .initial
    
    @RWAtomic public internal(set) var queue: WorkQueue?
    @RWAtomic private var processingTimeout: DispatchWorkItem?
    @RWAtomic private var completionBlocks: [()->()] = []
    
    public var isEnqueued: Bool { queue != nil }
    public override var isExecuting: Bool { stateLock.locking { state == .executing } }
    public override var isFinished: Bool { stateLock.locking { state == .finished } }
    
    public init(progress: WorkProgress = .init()) {
        self.progress = progress
        super.init()
        
        completionBlock = { [weak self] in
            self?.completionBlocks.forEach({ $0() })
        }
    }
    
    open override func addDependency(_ op: Operation) {
        fatalError()
    }
    
    func addDependency(_ work: WorkBase) {
        super.addDependency(work)
        WorkQueue.appQueue.add(work)
    }
    
    override public func start() {
        processingTimeout?.cancel()
        processingTimeout = DispatchWorkItem(block: { [weak self] in
            if let wSelf = self, !wSelf.isFinished {
                print("The operation has not been finished in 5min after start: \(wSelf)")
            }
        })
        DispatchQueue.global().asyncAfter(deadline: .now() + 60 * 5, execute: processingTimeout!)
        
        willChangeValue(forKey: Key.executing.rawValue)
        stateLock.locking { state = .executing }
        didChangeValue(forKey: Key.executing.rawValue)
        
        super.start()
        
        if isCancelled {
            print("\(self) isCancelled before main(): finishing")
            reject(RunError.cancelled)
        }
    }
    
    open override func cancel() {
        super.cancel()
        reject(RunError.cancelled)
    }
    
    open func execute() {
        fatalError("\(type(of: self)) must override `execute()`.")
    }
    
    open func reject(_ error: Error) {
        fatalError("\(type(of: self)) must override `reject(_:)`.")
    }
    
    open var error: Error? { fatalError("\(type(of: self)) must override `var error`.") }
    
    @discardableResult
    public func on(_ queue: WorkQueue) -> Self {
        queue.add(self)
        return self
    }
    
    public func addCompletion(_ block: @escaping ()->()) {
        _completionBlocks.mutate { $0.append(block) }
    }
}

public protocol Replicatable: AnyObject {
    func replicate() -> Self
}

open class Work<T>: WorkBase {
    public typealias ResultType = T
    
    @RWAtomic public private(set) var result: WorkResult<T>?
    
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
    
    private var processingTimeout: DispatchWorkItem?
    
    public func finish(_ result: WorkResult<T>) {
        willChangeValue(forKey: Key.executing.rawValue)
        willChangeValue(forKey: Key.finished.rawValue)
        stateLock.locking {
            if state == .finished { return }
            
            if result.error == nil {
                progress.update(1)
            }
            self.result = result
            state = .finished
        }
        didChangeValue(forKey: Key.executing.rawValue)
        didChangeValue(forKey: Key.finished.rawValue)
    }
    
    override public func main() {
        switch self.result {
        case .success(let value):
            finish(.success(value))
            return
        case .failure(let error):
            if !isCancelled {
                super.cancel()
            }
            finish(.failure(error))
            return
        default: break
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
        finish(.failure( error ))
    }
    
    public func resolve(_ value: T) {
        finish(.success(value))
    }
    
    public override var error: Error? { result?.error }
    
    deinit {
        processingTimeout?.cancel()
    }
}
