//
//  SingletonCondition.swift
//

import Foundation

fileprivate class Singleton {
    
    static var lock = NSLock()
    static var works: [String: WorkBase] = [:]
}

public class SingletonCondition<T>: VoidWork {
    
    private let category: String
    private weak var owner: Work<T>?
    
    init(category: String, owner: Work<T>) {
        self.category = category
        self.owner = owner
        super.init()
        owner.addDependency(self)
    }
    
    public override func execute() {
        guard let owner = owner else {
            reject(RunError.cancelled)
            return
        }
        
        let category = self.category + String(describing: T.self)
        
        Singleton.lock.locking {
            if let current = Singleton.works[category] as? Work<T> {
                current.addCompletion { [weak self, weak current] in
                    if let current = current, let wSelf = self {
                        wSelf.owner?.finish(current.result!)
                        
                        if let error = current.result?.error {
                            wSelf.reject(error)
                        } else {
                            wSelf.resolve(())
                        }
                    }
                }
                if current.isFinished {
                    owner.finish(current.result!)
                    
                    if let error = current.result?.error {
                        reject(error)
                    } else {
                        resolve(())
                    }
                }
            } else {
                Singleton.works[category] = owner
                owner.addCompletion {
                    Singleton.lock.locking {
                        Singleton.works[category] = nil
                    }
                }
                resolve(())
            }
        }
    }
}
