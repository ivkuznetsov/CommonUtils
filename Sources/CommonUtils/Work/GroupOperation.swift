//
//  GroupWork.swift
//

import Foundation

open class GroupWork<T>: Work<T> {
    
    private class WrappingWork: AsyncWork<Void> {
        
        fileprivate let work: WorkBase
        
        init(work: WorkBase) {
            self.work = work
            super.init { wrapper in
                work.addCompletion { [weak wrapper, weak work] in
                    if let error = work?.error {
                        wrapper?.reject(error)
                    } else {
                        wrapper?.resolve(())
                    }
                }
                if work.isFinished {
                    if let error = work.error {
                        wrapper.reject(error)
                    } else {
                        wrapper.resolve(())
                    }
                    return
                }
                WorkQueue.appQueue.add(work)
            }
        }
        
        override func cancel() { work.cancel() }
    }
    
    private let internalQueue: WorkQueue = WorkQueue(name: "group.internalQueue")
    @RWAtomic public private(set) var errors: [Error] = []
    @RWAtomic public private(set) var works = Set<WorkBase>()
    @RWAtomic private var finishingWork: BlockWork<Void>!
    @RWAtomic private var progresses: [WorkBase:Double] = [:]
    
    public init(works: [WorkBase], maxConcurrent: Int = OperationQueue.defaultMaxConcurrentOperationCount) {
        
        super.init()
        internalQueue.isSuspended = true
        internalQueue.maxConcurrentOperationCount = maxConcurrent
        
        works.forEach { add($0) }
        
        finishingWork = BlockWork({ [weak self] in
            self?.finishGroup()
        })
    }
    
    override open func cancel() {
        internalQueue.cancelAllOperations()
        works.forEach { $0.cancel() }
        super.cancel()
    }
    
    override open func execute() {
        works.forEach {
            let work = WrappingWork(work: $0)
            finishingWork.addDependency(work)
            internalQueue.add(work)
        }
        internalQueue.add(finishingWork)
        internalQueue.isSuspended = false
    }
    
    public func add(_ work: WorkBase) {
        if isExecuting || isFinished {
            work.cancel()
            return
        }
        
        works.insert(work)
        
        progresses[work] = 0
        work.progress.add(progressBlock: { [weak self, weak work] progress in
            guard let wSelf = self, let work = work else { return }
            
            wSelf.progresses[work] = progress.absoluteValue
            
            if wSelf.progresses.count > 0 {
                var progress: Double = 0
                wSelf.progresses.forEach { _, partialProgress in
                    progress += partialProgress
                }
                wSelf.progress.update(progress / Double(wSelf.progresses.count))
            }
        })
    }
    
    public func groupFinished() throws -> T { fatalError() }
    
    fileprivate func finishGroup() {
        errors = works.compactMap { $0.error }
        finishingWork = nil
        
        do {
            try resolve(groupFinished())
        } catch {
            reject(error)
        }
    }
}

open class GroupVoidWork: GroupWork<Void> {
    
    override open func groupFinished() throws -> Void {
        if errors.count > 0 {
            throw errors[0]
        }
    }
}
