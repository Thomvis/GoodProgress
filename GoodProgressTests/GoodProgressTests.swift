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
    

}
