//
//  GoodProgressTestCase.swift
//  GoodProgress
//
//  Created by Thomas Visser on 21/01/15.
//  Copyright (c) 2015 Thomas Visser. All rights reserved.
//

import XCTest
import GoodProgress

class GoodProgressTestCase: XCTestCase {

    func asynchronousTaskWithProgress(totalUnitCount: Int64, unitDuration: NSTimeInterval = 0.1) {
        let p = ProgressSource(totalUnitCount: totalUnitCount)
        println("executing async task with \(totalUnitCount) units, unit duration \(unitDuration)")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            for _ in 1...totalUnitCount {
                let random = unitDuration + unitDuration * 0.3 * (-0.5 + NSTimeInterval(Float(arc4random()) / Float(UINT32_MAX)))
                NSThread.sleepForTimeInterval(random)
                p.completeUnit()
            }
            println("finished executing task")
        }
    }
    
    func expectation() -> XCTestExpectation {
        return self.expectationWithDescription("no description")
    }

}
