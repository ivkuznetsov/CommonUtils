//
//  WorkQueue.swift
//

import Foundation

public final class WorkQueue: OperationQueue {
    
    public static let appQueue = WorkQueue(name: "main.workqueue")
    private let queue: DispatchQueue
    
    public init(name: String) {
        queue = DispatchQueue(label: "\(name).queue", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit)
        super.init()
        self.name = name
        underlyingQueue = queue
    }
    
    public func add(_ work: WorkBase) {
        if work.addTo(self) {
            work.dependencies.forEach {
                if let dependency = $0 as? WorkBase {
                    WorkQueue.appQueue.add(dependency)
                }
            }
            super.addOperation(work)
        }
    }
    
    override public func addOperations(_ operations: [Operation], waitUntilFinished wait: Bool) {
        fatalError()
    }
}
