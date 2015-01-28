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

class GoodProgressTests: GoodProgressTestCase {
    
    func testInitWithNSProgress() {
        let nsprogress = NSProgress(totalUnitCount: 11)
        let progress = Progress(progress: nsprogress)
        XCTAssertEqual(progress.totalUnitCount, Int64(11))
        XCTAssertEqual(progress.completedUnitCount, Int64(0))
        XCTAssertEqual(progress.fractionCompleted, 0)
    }
    
    func testInitWithTotalUnitCount() {
        let progress = Progress(totalUnitCount: 10)
        XCTAssertEqual(progress.totalUnitCount, Int64(10))
        XCTAssertEqual(progress.completedUnitCount, Int64(0))
        XCTAssertEqual(progress.fractionCompleted, 0)
    }
    
    func testFractionCompleted() {
        self.source10.completeUnit()
        XCTAssertEqual(self.progress10.fractionCompleted, 0.1)
        self.source10.completeUnit()
        XCTAssertEqual(self.progress10.fractionCompleted, 0.2)
    }
    
    func testLocalizedDescription() {
        XCTAssertEqual(self.progress10.localizedDescription, "0% completed")
        self.source10.completeUnit()
        XCTAssertEqual(self.progress10.localizedDescription, "10% completed")
    }
    
    func testLocalizedAdditionalDescription() {
        XCTAssertEqual(self.progress10.localizedAdditionalDescription, "0 of 10")
        self.source10.completeUnit()
        XCTAssertEqual(self.progress10.localizedAdditionalDescription, "1 of 10")
    }
    
    func testKind() {
        XCTAssertNil(self.progress10.kind)
    }
    
    func testCancellable() {
        XCTAssert(self.progress10.cancellable)
        self.source10.cancellable = false
        XCTAssertFalse(self.progress10.cancellable)
    }
    
    func testCancel() {
        XCTAssertFalse(self.progress10.cancelled)
        self.progress10.cancel()
        XCTAssert(self.progress10.cancelled)
    }
    
    func testPausable() {
        XCTAssertFalse(self.progress10.pausable)
        self.source10.pausable = true
        XCTAssert(self.progress10.pausable)
    }
    
    func testPause() {
        self.source10.pausable = true
        
        XCTAssertFalse(self.progress10.paused)
        self.progress10.pause()
        XCTAssert(self.progress10.paused)
    }
    
    func testRecursiveCancellable() {
        self.childSource30.cancellable = false
        self.childSource70.cancellable = false
        XCTAssert(self.parentProgress100.cancellable, "cancellable does not bubble up")
    }
    
    func testRecursivePausable() {
        self.childSource30.pausable = true
        self.childSource70.pausable = true
        XCTAssertFalse(self.parentProgress100.pausable, "pausable does not bubble up")
    }
    
    func testOnProgress() {
        let e = self.expectation()
        var updateCount = 0
        self.progress10.onProgress { fraction in
            updateCount++
            if fraction == 1.0 && updateCount == 10 {
                e.fulfill()
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            for _ in 1...10 {
                self.source10.completeUnit()
            }
        }
        
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testMultipleProgressBlocks() {
        let e1 = self.expectation()
        let e2 = self.expectation()
        
        self.progress10.onProgress {
            if $0 == 1.0 {
                e1.fulfill()
            }
        }
        
        self.progress10.onProgress {
            if $0 == 1.0 {
                e2.fulfill()
            }
        }
        
        for _ in 1...10 {
            self.source10.completeUnit()
        }
        
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testProgressAfterPause() {
        self.source10.completeUnit()
        XCTAssertEqual(self.progress10.fractionCompleted, 0.1)
        self.progress10.pause()
        XCTAssertEqual(self.progress10.fractionCompleted, 0.1)
    }
    
    func testProgressAfterCancel() {
        self.source10.completeUnit()
        XCTAssertEqual(self.progress10.fractionCompleted, 0.1)
        self.progress10.cancel()
        XCTAssertEqual(self.progress10.fractionCompleted, 0.1)
    }
    
    func testCurrentProgress() {
        XCTAssertNil(Progress.currentProgress())
        self.source10.becomeCurrentWithPendingUnitCount(1)
        XCTAssertEqual(Progress.currentProgress()!, self.progress10)
        self.source10.resignCurrent()
    }
    
    func testRecursiveCurrentProgress() {
        self.source10.becomeCurrentWithPendingUnitCount(1)
        self.parentSource100.becomeCurrentWithPendingUnitCount(1)
        XCTAssertEqual(Progress.currentProgress()!, self.parentProgress100)
        self.parentSource100.resignCurrent()
        XCTAssertEqual(Progress.currentProgress()!, self.progress10)
        self.source10.resignCurrent()
    }
    
    func testCurrentProgressThreadBound() {
        XCTAssertNil(Progress.currentProgress())
        self.source10.becomeCurrentWithPendingUnitCount(1)
        let e = self.expectation()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            XCTAssertNil(Progress.currentProgress())
            e.fulfill()
        }
        XCTAssertEqual(Progress.currentProgress()!, self.progress10)
        self.waitForExpectationsWithTimeout(2, handler: nil)
        XCTAssertEqual(Progress.currentProgress()!, self.progress10)
        self.source10.resignCurrent()
    }
    
    // ProgressSource
    
    func testSourceInitDefaultTotalUnit() {
        let source = ProgressSource()
        XCTAssertEqual(source.totalUnitCount, Int64(100))
    }
    
    func testTotalUnitCount() {
        XCTAssertEqual(self.progress10.totalUnitCount, Int64(10))
        self.source10.totalUnitCount = 8
        XCTAssertEqual(self.progress10.totalUnitCount, Int64(8))
    }
    
    func testCompleteUnit() {
        self.source10.completeUnit()
        XCTAssertEqual(self.progress10.fractionCompleted, 0.1)
    }
    
    func testAdaptTotalUnitCountWithProgress() {
        self.source10.completeUnit()
        XCTAssertEqual(self.progress10.fractionCompleted, 0.1)
        self.source10.totalUnitCount = 5
        XCTAssertEqual(self.progress10.fractionCompleted, 0.2)
    }
    
    func testIndeterminate() {
        XCTAssertFalse(self.source10.progress.indeterminate)
        self.source10.totalUnitCount = -1
        XCTAssert(self.source10.progress.indeterminate)
    }
    
    func testOnCancel() {
        let e = self.expectation()
        self.source10.onCancel {
            e.fulfill()
        }
        
        self.progress10.cancel()
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testMultipleCancelBlocks() {
        let e1 = self.expectation()
        let e2 = self.expectation()
        
        self.source10.onCancel {
            e1.fulfill()
        }
        
        self.source10.onCancel {
            e2.fulfill()
        }
        
        self.progress10.cancel()
        
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testOnPause() {
        let e = self.expectation()
        self.source10.pausable = true
        self.source10.onPause {
            e.fulfill()
        }
        
        self.progress10.pause()
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testMultiplePauseBlocks() {
        let e1 = self.expectation()
        let e2 = self.expectation()
        
        self.source10.onPause {
            e1.fulfill()
        }
        
        self.source10.onPause {
            e2.fulfill()
        }
        
        self.progress10.pause()
        
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testRecursiveCancel() {
        let e1 = self.expectation()
        let e2 = self.expectation()
        
        self.childSource70.onCancel {
            e1.fulfill()
        }
        
        self.childSource30.onCancel {
            e2.fulfill()
        }
        
        self.parentProgress100.cancel()
        
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testRecursivePause() {
        let e1 = self.expectation()
        let e2 = self.expectation()
        
        self.childSource70.onPause {
            e1.fulfill()
        }
        
        self.childSource30.onPause {
            e2.fulfill()
        }
        
        self.parentProgress100.pause()
        
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testRepeatedPause() {
        let e = self.expectation()
        self.source10.onPause {
            e.fulfill()
        }
        
        self.progress10.pause()
        self.progress10.pause()
        
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testRepeatedCancel() {
        let e = self.expectation()
        self.source10.onCancel {
            e.fulfill()
        }
        
        self.progress10.cancel()
        self.progress10.cancel()
        
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
}
