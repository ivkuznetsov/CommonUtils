//
//  Work+Chain.swift
//  Versions
//

import Foundation

final class ChainedWork<T>: AsyncWork<T> {
    
    private let dependency: WorkBase
    
    init(progress: ChainedProgress, work: WorkBase, block: @escaping ((AsyncWork<T>) -> ())) {
        dependency = work
        super.init(block: block, progress: progress)
        addDependency(work)
    }
    
    override func cancel() {
        super.cancel()
        dependency.cancel()
    }
}

extension Work {
    
    @discardableResult
    public func run(progress: ((Double)->())? = nil) -> Self {
        if let progress = progress {
            self.progress.add(progressBlock: {
                progress($0.absoluteValue)
            })
        }
        return on(WorkQueue.appQueue)
    }
    
    @discardableResult
    public func run(progress: ((Double)->())? = nil, _ block: @escaping (WorkResult<T>) -> ()) -> Work<T> {
        alwaysOnMain(block).run(progress: progress)
    }
    
    @discardableResult
    public func runWith(progress: ((Double)->())? = nil, _ block: @escaping (Error?)->()) -> Work<T> {
        alwaysOnMainWith(block).run(progress: progress)
    }
    
    public func chain<R>(progress: ChainedProgress.SubWeight = .weight(0.5), _ block: @escaping (T) throws -> Work<R>) -> Work<R> {
        
        ChainedWork<R>(progress: ChainedProgress(subWeight: progress, dependency: self.progress), work: self) { chainedWork in
            switch self.result! {
            case .success(let value):
                guard !chainedWork.isFinished else { return }
                
                let resultWork: Work<R>
                do {
                    resultWork = try block(value)
                } catch {
                    chainedWork.reject(error)
                    return
                }
                
                resultWork.addCompletion { [weak resultWork] in
                    if let result = resultWork?.result {
                        chainedWork.finish(result)
                    }
                }
                (chainedWork as! ChainedWork<R>).addCompletion { [weak resultWork] in
                    resultWork?.cancel()
                }
                
                if let result = resultWork.result {
                    chainedWork.finish(result)
                }
                resultWork.progress.reset(root: chainedWork.progress)
                resultWork.run()
            case .failure(let error):
                chainedWork.reject( error )
            }
        }
    }
    
    public func seize(_ block: @escaping (Error) throws -> Work<T>) -> Work<T> {
        ChainedWork<T>(progress: ChainedProgress(subWeight: .skip, dependency: progress),
                         work: self) { chainedWork in
            
            switch self.result! {
            case .success(let value):
                chainedWork.resolve(value)
            case .failure(let error):
                do {
                    let resultWork = try block(error)
                    
                    resultWork.addCompletion { [weak resultWork] in
                        if let result = resultWork?.result {
                            chainedWork.finish(result)
                        }
                    }
                    
                    if let result = resultWork.result {
                        chainedWork.finish(result)
                    }
                    resultWork.progress.reset(root: chainedWork.progress)
                    resultWork.run()
                } catch {
                    chainedWork.reject(error)
                }
            }
        }
    }
    
    public func fail(_ block: @escaping (Error) -> ()) -> Self {
        alwaysWith { error in
            if let error = error {
                block(error)
            }
        }
    }
    
    public func success(_ block: @escaping (T) -> ()) -> VoidWork {
        always {
            if let value = $0.value {
                block(value)
            }
        }.removeType()
    }
    
    public func successOnMain(_ block: @escaping (T) -> ()) -> VoidWork {
        success { result in
            DispatchQueue.main.async { block(result) }
        }
    }
    
    public func always(_ block: @escaping (WorkResult<T>) -> ()) -> Self {
        addCompletion { [unowned self] in
            block(self.result!)
        }
        return self
    }
    
    public func alwaysOnMain(_ block: @escaping (WorkResult<T>) -> ()) -> Self {
        always { result in
            DispatchQueue.main.async {
                block(result)
            }
        }
    }
    
    public func alwaysWith(_ block: @escaping (Error?) -> ()) -> Self {
        always { block($0.error) }
    }
    
    public func alwaysOnMainWith(_ block: @escaping (Error?) -> ()) -> Self {
        alwaysWith { error in
            DispatchQueue.main.async {
                block(error)
            }
        }
    }
    
    //Cancel after this function will not affect previous operation
    public func withDetachedCancel() -> Work<T> {
        AsyncWork { [weak self] work in
            if let wSelf = self {
                if let result = wSelf.result {
                    work.finish(result)
                } else {
                    _ = wSelf.success { work.resolve($0) }
                }
            } else {
                work.reject(RunError.cancelled)
            }
        }
    }
    
    public func then(progress: ChainedProgress.SubWeight = .weight(0.5), _ block: @escaping (T) throws -> VoidWork) -> VoidWork {
        chain(progress: progress) { try block($0).removeType() }
    }
    
    public func convert<R>(_ block: @escaping (T) throws -> R) -> Work<R> {
        chain(progress: .skip) { .value(try block($0)) }
    }
    
    public func removeType() -> VoidWork {
        convert() { _ in }
    }
    
    static public func value(_ value: T) -> Work<T> { Work(result: value) }
    
    static public func fail(_ error: Error) -> Work<T> { Work(error) }
    
    public func chainOrCancel<R>(progress: ChainedProgress.SubWeight = .weight(0.5), _ block: @escaping (T) throws -> Work<R>?) -> Work<R> {
        chain(progress: progress) {
            if let op = try block($0) {
                return op
            } else {
                throw RunError.cancelled
            }
        }
    }
    
    public func thenOrCancel(progress: ChainedProgress.SubWeight = .weight(0.5), _ block: @escaping (T) throws -> VoidWork?) -> VoidWork {
        then(progress: progress) {
            if let op = try block($0) {
                return op
            } else {
                throw RunError.cancelled
            }
        }
    }
}

extension VoidWork {
    
    static public func success() -> VoidWork { .value(()) }
}

public func with<T,V,R>(_ work1: Work<T>, _ work2: Work<V>, block: @escaping (T, V) throws -> R) -> Work<R> {
    GroupVoidWork(works: [work1, work2]).convert { _ -> R in
        try block(work1.result!.value!, work2.result!.value!)
    }
}

public func with<T,V,U,R>(_ work1: Work<T>, _ work2: Work<V>, _ work3: Work<U>, block: @escaping (T, V, U) throws -> R) -> Work<R> {
    GroupVoidWork(works: [work1, work2, work3]).convert { _ -> R in
        try block(work1.result!.value!, work2.result!.value!, work3.result!.value!)
    }
}

public func with<T,V,U,R,S>(_ work1: Work<T>, _ work2: Work<V>, _ work3: Work<U>, _ work4: Work<S>, block: @escaping (T, V, U, S) throws -> R) -> Work<R> {
    GroupVoidWork(works: [work1, work2, work3, work4]).convert { _ -> R in
        try block(work1.result!.value!, work2.result!.value!, work3.result!.value!, work4.result!.value!)
    }
}

public func with<T,V,R>(_ work1: Work<T>, _ work2: Work<V>, block: @escaping (T, V) throws -> Work<R>) -> Work<R> {
    GroupVoidWork(works: [work1, work2]).chain { _ -> Work<R> in
        try block(work1.result!.value!, work2.result!.value!)
    }
}

public func with<T,V,U,R>(_ work1: Work<T>, _ work2: Work<V>, _ work3: Work<U>, block: @escaping (T, V, U) throws -> Work<R>) -> Work<R> {
    GroupVoidWork(works: [work1, work2, work3]).chain { _ -> Work<R> in
        try block(work1.result!.value!, work2.result!.value!, work3.result!.value!)
    }
}

public func with<T,V,U,R,S>(_ work1: Work<T>, _ work2: Work<V>, _ work3: Work<U>, _ work4: Work<S>, block: @escaping (T, V, U, S) throws -> Work<R>) -> Work<R> {
    GroupVoidWork(works: [work1, work2, work3, work4]).chain { _ -> Work<R> in
        try block(work1.result!.value!, work2.result!.value!, work3.result!.value!, work4.result!.value!)
    }
}
