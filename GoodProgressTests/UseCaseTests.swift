//
//  UseCaseTests.swift
//  GoodProgress
//
//  Created by Thomas Visser on 21/01/15.
//  Copyright (c) 2015 Thomas Visser. All rights reserved.
//

import XCTest
import GoodProgress

class UseCaseTests: GoodProgressTestCase {

    func testSimpleProgress() {
        let p = progress(self.asynchronousTaskWithProgress(3))
        let e = self.expectation()
        p.onProgress { fraction in
            if fraction == 1.0 {
                e.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testProgressCapturing() {
        let e = self.expectation()
        
        progress(100) { p in
            p.captureProgress(80) {
                self.asynchronousTaskWithProgress(12)
            }
            
            p.captureProgress(20) {
                self.asynchronousTaskWithProgress(3)
            }
        }.onProgress { fraction in
                println(fraction)
                if (fraction == 1.0) {
                    e.fulfill()
                }
        }
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

}
