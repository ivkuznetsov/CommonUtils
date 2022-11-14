//
//  WorkProgress.swift
//

import Foundation

public class WorkProgress {
    
    @RWAtomic var weight: Double = 1
    @RWAtomic var start: Double = 0
    @RWAtomic private(set) var progressBlocks: [(WorkProgress)->()] = []
    
    @RWAtomic public private(set) var value: Double = 0
    public var absoluteValue: Double { start + value * weight }
    
    public init() {
        reset()
    }
    
    public func update(_ value: Double) {
        if self.value == value { return }
        
        self.value = value
        
        DispatchQueue.main.async { [weak self] in
            if let wSelf = self {
                wSelf.progressBlocks.forEach {
                    $0(wSelf)
                }
            }
        }
    }
    
    func updateStart(fullProgress: Double = 1) {
        start = fullProgress - weight
    }
    
    func updateWeight(_ weight: Double = 1) {
        self.weight = weight
    }
    
    public func add(progressBlock: @escaping (WorkProgress)->()) {
        _progressBlocks.mutate { $0.append(progressBlock) }
    }
    
    func reset(root: WorkProgress? = nil) {
        if let root = root {
            updateWeight(root.weight)
            updateStart(fullProgress: root.start + root.weight)
            root.progressBlocks.forEach { add(progressBlock: $0) }
        } else {
            updateWeight()
            updateStart()
        }
    }
}

public class ChainedProgress: WorkProgress {
    
    public enum SubWeight {
        case weight(Double)
        case skip
    }
    
    let subWeight: SubWeight
    private let dependency: WorkProgress
    
    init(subWeight: SubWeight, dependency: WorkProgress) {
        self.dependency = dependency
        self.subWeight = subWeight
        super.init()
        
        if case .skip = subWeight {
            weight = 0
        }
        reset()
    }
    
    public override func add(progressBlock: @escaping (WorkProgress) -> ()) {
        super.add(progressBlock: progressBlock)
        dependency.add(progressBlock: progressBlock)
    }
    
    override func updateStart(fullProgress: Double) {
        super.updateStart(fullProgress: fullProgress)
        dependency.updateStart(fullProgress: start)
    }
    
    private var nextNonSkippedDependency: WorkProgress? {
        if let dependency = dependency as? ChainedProgress, case .skip = dependency.subWeight {
            return dependency.nextNonSkippedDependency
        }
        return dependency
    }
    
    override func updateWeight(_ weight: Double) {
        if let dep = nextNonSkippedDependency {
            dep.updateWeight(weight)
            
            if case .weight(let value) = subWeight {
                self.weight = value * dep.weight
                dep.weight = (1.0 - value) * dep.weight
            }
        }
    }
}
