//
//  OutlineStorageTests.swift
//  IcelandTests
//
//  Created by ian luo on 2018/11/20.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import XCTest
@testable import Business

public class OutlineStorageTests: XCTestCase {
    func testExtendRange() {
        let text =
"""
* fastlane design
fastlane official site
fastlane docs
*** iOS platform structure project
1. list the structure
2. make a tool to do it
remember for random task
day plan
review the upcoming week
reschedule
priority of task
log state change
clear complete task
new task while a taks in progress, move to inbound queue
review and summary
use voice to record remember task is handy
"""
    
        var extendedRange = NSRange(location: 10, length: 1).expandFoward(string: text).expandBackward(string: text)
        
        XCTAssertEqual(0, extendedRange.location)
        XCTAssertEqual(18, extendedRange.length)
        
        extendedRange = NSRange(location: 31, length: 1).expandFoward(string: text).expandBackward(string: text)
        XCTAssertEqual(18, extendedRange.location)
        XCTAssertEqual(23, extendedRange.length)
        
        extendedRange = NSRange(location: 16, length: 2).expandFoward(string: text).expandBackward(string: text)
        XCTAssertEqual(0, extendedRange.location)
        XCTAssertEqual(41, extendedRange.length)
    }
    
    func testCurrentLocation() {
        let storage = EditorController(parser: OutlineParser())
        let textView = UITextView(frame: .zero, textContainer: storage.textContainer)
        textView.text =
        """
        * TODO fastlane design :movie:entertainment:
        SCHEDULED: <2018-12-05 Wed>
        DEADLINE: <2018-12-05 Wed>
        fastlane official site
        fastlane docs
        *** DONE iOS platform structure project
        1. list the structure
        2. make a tool to do it
        remember for random task
        day plan
        review the upcoming week
        reschedule
        priority of task
        log state change
        clear complete task
        new task while a taks in progress, move to inbound queue
        review and summary
        use voice to record remember task is handy
        """
        
        XCTAssertEqual(storage.textStorage.currentLocation, 0)
        XCTAssertEqual(2, storage.textStorage.savedHeadings.count)
        XCTAssertEqual(2, storage.textStorage.savedHeadings.count)
        XCTAssertEqual(storage.textStorage.currentHeading?.level, 1)
        XCTAssertEqual(textView.text.substring(storage.textStorage.currentHeading!.planning!), "TODO")
        XCTAssertEqual(textView.text.substring(storage.textStorage.currentHeading!.schedule!), "SCHEDULED: <2018-12-05 Wed>")
        XCTAssertEqual((textView.text as NSString).substring(with: storage.textStorage.currentHeading!.due!), "DEADLINE: <2018-12-05 Wed>")
        XCTAssertEqual((textView.text as NSString).substring(with: storage.textStorage.currentHeading!.tags!), ":movie:entertainment:")
        
        storage.textStorage.currentLocation = 150
        storage.textStorage.updateCurrentInfo()
        XCTAssertEqual(storage.textStorage.currentHeading?.level, 3)
        XCTAssertEqual((textView.text as NSString).substring(with: storage.textStorage.currentHeading!.planning!), "DONE")
        XCTAssertEqual(storage.textStorage.currentHeading?.schedule, nil)
        XCTAssertEqual(storage.textStorage.currentHeading?.due, nil)
        XCTAssertEqual(storage.textStorage.currentHeading?.tags, nil)
    }
    
    func testNewLoadItems() {
        let storage = EditorController(parser: OutlineParser())
        let textView = UITextView(frame: .zero, textContainer: storage.textContainer)
        textView.text = """
        * TODO fastlane design :movie:entertainment:
        SCHEDULED: <2018-12-05 Wed>
        DEADLINE: <2018-12-05 Wed>
        fastlane official site
        fastlane docs
        *** DONE iOS platform structure project
        1. list the structure
        2. make a tool to do it
        remember for random task
        day plan
        review the upcoming week
        reschedule
        priority of task
        log state change
        clear complete task
        new task while a taks in progress, move to inbound queue
        review and summary
        use voice to record remember task is handy
        """
        
        XCTAssertEqual(13, storage.textStorage.itemRanges.count)
        XCTAssertEqual(13, storage.textStorage.itemRangeDataMapping.count)
        XCTAssertEqual("* TODO fastlane design :movie:entertainment:\nSCHEDULED: <2018-12-05 Wed>\nDEADLINE: <2018-12-05 Wed>", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[0]))
        XCTAssertEqual("*", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[1]))
        XCTAssertEqual("TODO", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[2]))
        XCTAssertEqual(":movie:entertainment:", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[3]))
        XCTAssertEqual("SCHEDULED: <2018-12-05 Wed>", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[4]))
        XCTAssertEqual("DEADLINE: <2018-12-05 Wed>", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[5]))
        XCTAssertEqual("*** DONE iOS platform structure project", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[6]))
        XCTAssertEqual("***", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[7]))
        XCTAssertEqual("DONE", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[8]))
        XCTAssertEqual("1. list the structure", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[9]))
        XCTAssertEqual("1", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[10]))
        XCTAssertEqual("2. make a tool to do it", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[11]))
        XCTAssertEqual("2", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[12]))
    }
    
    func testEditItems() {
        let controller = EditorController(parser: OutlineParser())
        let textView = UITextView(frame: .zero, textContainer: controller.textContainer)
        textView.text = """
        * TODO fastlane design :movie:entertainment:
        SCHEDULED: <2018-12-05 Wed>
        DEADLINE: <2018-12-05 Wed>
        fastlane official site
        fastlane docs
        *** DONE iOS platform structure project
        1. list the structure
        2. make a tool to do it
        remember for random task
        day plan
        review the upcoming week
        reschedule
        priority of task
        log state +change+
        clear complete task
        new task while a taks in ~progress~, move to inbound queue
        review and summary
        use voice to record remember *task* is handy
        
        - list 1 item
        - list 2 item
        
        - [ ] check item
            - [x] done
        - [ ] do some
        
        
        """
        XCTAssertEqual("* TODO fastlane design :movie:entertainment:\nSCHEDULED: <2018-12-05 Wed>\nDEADLINE: <2018-12-05 Wed>", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[0]))
        XCTAssertEqual("*", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[1]))
        XCTAssertEqual("TODO", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[2]))
        XCTAssertEqual(":movie:entertainment:", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[3]))
        XCTAssertEqual("SCHEDULED: <2018-12-05 Wed>", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[4]))
        XCTAssertEqual("DEADLINE: <2018-12-05 Wed>", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[5]))
        XCTAssertEqual("*** DONE iOS platform structure project", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[6]))
        XCTAssertEqual("***", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[7]))
        XCTAssertEqual("DONE", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[8]))
        XCTAssertEqual("1. list the structure", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[9]))
        XCTAssertEqual("1", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[10]))
        XCTAssertEqual("2. make a tool to do it", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[11]))
        XCTAssertEqual("2", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[12]))
        
        controller.textStorage.currentLocation = 150
        controller.textStorage.adjustParseRange(NSRange(location: 150, length: 10))
        controller.textStorage.updateItemIndexAndRange(delta: 0)
        controller.textStorage.parser.parse(str: textView.text!, range: controller.textStorage.currentParseRange)
        controller.textStorage.updateCurrentInfo()
        
        XCTAssertEqual("* TODO fastlane design :movie:entertainment:\nSCHEDULED: <2018-12-05 Wed>\nDEADLINE: <2018-12-05 Wed>", textView.text.substring(controller.textStorage.itemRanges[0]))
        XCTAssertEqual("*", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[1]))
        XCTAssertEqual("TODO", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[2]))
        XCTAssertEqual(":movie:entertainment:", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[3]))
        XCTAssertEqual("SCHEDULED: <2018-12-05 Wed>", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[4]))
        XCTAssertEqual("DEADLINE: <2018-12-05 Wed>", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[5]))
        XCTAssertEqual("*** DONE iOS platform structure project", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[6]))
        XCTAssertEqual("***", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[7]))
        XCTAssertEqual("DONE", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[8]))
        XCTAssertEqual("1. list the structure", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[9]))
        XCTAssertEqual("1", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[10]))
        XCTAssertEqual("2. make a tool to do it", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[11]))
        XCTAssertEqual("2", (textView.text as NSString).substring(with: controller.textStorage.itemRanges[12]))
    }
}
