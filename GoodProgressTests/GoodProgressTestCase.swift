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

    var source10: ProgressSource!
    
    var progress10: Progress {
        get {
            return self.source10.progress
        }
    }
    
    var parentSource100: ProgressSource!
    var childSource30: ProgressSource!
    var childSource70: ProgressSource!
    
    var parentProgress100: Progress {
        get {
            return self.parentSource100.progress
        }
    }
    
    var childProgress30: Progress {
        get {
            return self.childSource30.progress
        }
    }
    
    var childProgress70: Progress {
        get {
            return self.childSource70.progress
        }
    }
    
    override func setUp() {
        self.source10 = ProgressSource(totalUnitCount: 10)

        self.parentSource100 = ProgressSource(totalUnitCount: 100)
        self.parentSource100.becomeCurrentWithPendingUnitCount(30)
        self.childSource30 = ProgressSource(totalUnitCount: 30)
        self.parentSource100.resignCurrent()
        
        self.parentSource100.becomeCurrentWithPendingUnitCount(30)
        self.childSource70 = ProgressSource(totalUnitCount: 70)
        self.parentSource100.resignCurrent()
    }
    
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
