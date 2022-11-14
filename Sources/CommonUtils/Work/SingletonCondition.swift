//
//  SingletonCondition.swift
//

import Foundation

public extension Work {
    
    func singleton(_ category: String) -> Work<T> {
        SingletonCondition(category: category, owner: self).chainOrCancel { [weak self] in self }
    }
}

fileprivate class Singleton {
    
    static var lock = NSLock()
    static var works: [String: WorkBase] = [:]
}

public class SingletonCondition<T>: VoidWork {
    
    private let category: String
    private let owner: Work<T>
    
    init(category: String, owner: Work<T>) {
        self.category = category
        self.owner = owner
        super.init()
        owner.addDependency(self)
    }
    
    public override func execute() {
        let category = self.category + String(describing: T.self)
        
        Singleton.lock.locking {
            if let current = Singleton.works[category] as? Work<T> {
                current.addCompletion { [weak self, weak current] in
                    if let current = current, let wSelf = self {
                        wSelf.owner.finish(current.result!)
                        wSelf.resolve(())
                    }
                }
                if current.isFinished {
                    owner.finish(current.result!)
                    resolve(())
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
