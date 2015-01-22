//
//  ProgressSourceTests.swift
//  GoodProgress
//
//  Created by Thomas Visser on 21/01/15.
//  Copyright (c) 2015 Thomas Visser. All rights reserved.
//

import XCTest
import GoodProgress
class ProgressSourceTests: GoodProgressTestCase {


    func testSourceInitDefaultTotalUnit() {
        let source = ProgressSource()
        XCTAssertEqual(source.totalUnitCount, Int64(100))
    }

}
