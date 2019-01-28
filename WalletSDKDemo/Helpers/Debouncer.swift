//Copyright (c) 2019 Cybavo. All rights reserved.

import Foundation

class Debouncer {
    private let queue: DispatchQueue = DispatchQueue.global(qos: .background)
    
    private var job: DispatchWorkItem = DispatchWorkItem(block: {})
    private var interval: Double
    
    init(seconds: Double) {
        self.interval = seconds
    }
    
    func debounce(block: @escaping () -> ()) {
        job.cancel()
        job = DispatchWorkItem(){
            block()
        }
        queue.asyncAfter(deadline: .now() + interval, execute: job)
    }
}

private extension Date {
    static func second(from referenceDate: Date) -> Int {
        return Int(Date().timeIntervalSince(referenceDate).rounded())
    }
}

