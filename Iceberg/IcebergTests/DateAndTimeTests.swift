//
//  DateAndTimeTests.swift
//  x3NoteTests
//
//  Created by ian luo on 2021/1/2.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation
@testable import Core
import XCTest

class DateAndTimeTests: XCTestCase {
    func testRepeat() {
        let originnal = DateAndTimeType("<2010-9-1 +1y>")
        let destination = Date()
                
        let df = DateFormatter()
        df.timeZone = TimeZone(secondsFromGMT: 3600 * 8)
        df.dateStyle = .medium
        df.timeStyle = .long
        let string = df.string(from: originnal!.closestDate(to: destination, after: false))
        print(">>> " + string)
    }
}
