//
//  ProgressTests.swift
//  GoodProgress
//
//  Created by Thomas Visser on 23/01/15.
//  Copyright (c) 2015 Thomas Visser. All rights reserved.
//

import Foundation
import GoodProgress
import XCTest

class ProgressTests : GoodProgressTestCase {
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
    
    func testTotalUnitCount() {
        let source = ProgressSource(totalUnitCount: 10)
        XCTAssertEqual(source.progress.totalUnitCount, Int64(10))
        source.totalUnitCount = 8
        XCTAssertEqual(source.progress.totalUnitCount, Int64(8))
    }
    
    func testFractionCompleted() {
        let source = ProgressSource(totalUnitCount: 10)
        source.completeUnit()
        XCTAssertEqual(source.progress.fractionCompleted, 0.1)
        source.completeUnit()
        XCTAssertEqual(source.progress.fractionCompleted, 0.2)
    }
    
    func testLocalizedDescription() {
        let source = ProgressSource(totalUnitCount: 10)
        XCTAssertEqual(source.progress.localizedDescription, "0% completed")
        source.completeUnit()
        XCTAssertEqual(source.progress.localizedDescription, "10% completed")
    }
    
    func testLocalizedAdditionalDescription() {
        let source = ProgressSource(totalUnitCount: 10)
        XCTAssertEqual(source.progress.localizedAdditionalDescription, "0 of 10")
        source.completeUnit()
        XCTAssertEqual(source.progress.localizedAdditionalDescription, "1 of 10")
    }
    
    func testCancellable() {
        let source = ProgressSource(totalUnitCount: 10)
        XCTAssert(source.progress.cancellable)
        source.cancellable = false
        XCTAssertFalse(source.progress.cancellable)
    }
    
    func testCancel() {
        let source = ProgressSource(totalUnitCount: 10)
        XCTAssertFalse(source.progress.cancelled)
        source.progress.cancel()
        XCTAssert(source.progress.cancelled)
    }
    
    func testPausable() {
        let source = ProgressSource(totalUnitCount: 10)
        XCTAssertFalse(source.progress.pausable)
        source.pausable = true
        XCTAssert(source.progress.pausable)
    }
    
    func testPause() {
        let source = ProgressSource(totalUnitCount: 10)
        source.pausable = true
        XCTAssertFalse(source.progress.paused)
        source.progress.pause()
        XCTAssert(source.progress.paused)
    }
    
    func testAdaptTotalUnitCountWithProgress() {
        let source = ProgressSource(totalUnitCount: 10)
        source.completeUnit()
        XCTAssertEqual(source.progress.fractionCompleted, 0.1)
        source.totalUnitCount = 5
        XCTAssertEqual(source.progress.fractionCompleted, 0.2)
    }
}