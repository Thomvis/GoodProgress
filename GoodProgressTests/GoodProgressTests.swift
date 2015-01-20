//
//  GoodProgressTests.swift
//  GoodProgressTests
//
//  Created by Thomas Visser on 19/01/15.
//  Copyright (c) 2015 Thomas Visser. All rights reserved.
//

import UIKit
import XCTest
import GoodProgress

class GoodProgressTests: XCTestCase {
    
    func testExample() {
        let e = self.expectationWithDescription("")
        
        progress(100) { p in
            p.captureProgress(80) {
                self.loadImage()
            }
            
            p.captureProgress(20) {
                self.loadInfo()
            }
        }.onProgress { fraction in
            println(fraction)
            if (fraction == 1.0) {
                e.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func fakeLoad(work: Int) {
        let p = MutableProgress(totalUnitCount: Int64(work))
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            dispatch_apply(UInt(work), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { _ in
                let random = 2 + 2 * (-0.5 + NSTimeInterval(Float(arc4random()) / Float(UINT32_MAX)))
                NSThread.sleepForTimeInterval(random)
                p.completedUnitCount++
            }
        }
    }
    
    func loadImage() {
        fakeLoad(10)
    }
    
    func loadInfo() {
        fakeLoad(5)
    }
}
