//
//  SettingsTests.swift
//  IcelandTests
//
//  Created by ian luo on 2018/12/15.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import XCTest
@testable import Iceland
import Business

public class SettingsTests: XCTestCase {
    func testUnfinishedCustomizedPlannings() {
        XCTAssertEqual(SettingsAccessor.shared.customizedUnfinishedPlannings, ["Pending", "Waiting"])
    }
    
    
    func testFinishedCustomizedPlannings() {
        XCTAssertEqual(SettingsAccessor.shared.customizedFinishedPlannings, ["Rejected"])
    }
    
    func testGettingAllCustomizedPlannings() {
        XCTAssertEqual(SettingsAccessor.shared.customizedPlannings, [ "Rejected", "Pending", "waiting"])
    }
    
    func testGettingAllPlannings() {
        XCTAssertEqual(OutlineParser.Values.Heading.Planning.all, ["TODO", "CANCELED", "DONE","Pending", "waiting", "Rejected"])
    }
    
    func testGettingPlaningPattern() {
        XCTAssertEqual("TODO|CANCELED|DONE|Rejected|Pending|Waiting", OutlineParser.Values.Heading.Planning.pattern)
    }
}
