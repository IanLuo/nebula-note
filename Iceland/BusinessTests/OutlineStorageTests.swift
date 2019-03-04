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
        let storage = EditorController(parser: OutlineParser(), eventObserver: EventObserver())
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
        let storage = EditorController(parser: OutlineParser(), eventObserver: EventObserver())
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
        
        XCTAssertEqual(13, storage.textStorage.allTokens.count)
        XCTAssertEqual("* TODO fastlane design :movie:entertainment:\nSCHEDULED: <2018-12-05 Wed>\nDEADLINE: <2018-12-05 Wed>", textView.text.substring(storage.textStorage.allTokens[0].range))
        XCTAssertEqual("*", textView.text.substring(storage.textStorage.allTokens[1].range))
        XCTAssertEqual("TODO", textView.text.substring(storage.textStorage.allTokens[2].range))
        XCTAssertEqual(":movie:entertainment:", textView.text.substring(storage.textStorage.allTokens[3].range))
        XCTAssertEqual("SCHEDULED: <2018-12-05 Wed>", textView.text.substring(storage.textStorage.allTokens[4].range))
        XCTAssertEqual("DEADLINE: <2018-12-05 Wed>", textView.text.substring(storage.textStorage.allTokens[5].range))
        XCTAssertEqual("*** DONE iOS platform structure project", textView.text.substring(storage.textStorage.allTokens[6].range))
        XCTAssertEqual("***", textView.text.substring(storage.textStorage.allTokens[7].range))
        XCTAssertEqual("DONE", textView.text.substring(storage.textStorage.allTokens[8].range))
        XCTAssertEqual("1. list the structure", textView.text.substring(storage.textStorage.allTokens[9].range))
        XCTAssertEqual("1", textView.text.substring(storage.textStorage.allTokens[10].range))
        XCTAssertEqual("2. make a tool to do it", textView.text.substring(storage.textStorage.allTokens[11].range))
        XCTAssertEqual("2", textView.text.substring(storage.textStorage.allTokens[12].range))
    }
    
    func testEditItems() {
        let controller = EditorController(parser: OutlineParser(), eventObserver: EventObserver())
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
        XCTAssertEqual("* TODO fastlane design :movie:entertainment:\nSCHEDULED: <2018-12-05 Wed>\nDEADLINE: <2018-12-05 Wed>", textView.text.substring(controller.textStorage.allTokens[0].range))
        XCTAssertEqual("*", textView.text.substring(controller.textStorage.allTokens[1].range))
        XCTAssertEqual("TODO", textView.text.substring(controller.textStorage.allTokens[2].range))
        XCTAssertEqual(":movie:entertainment:", textView.text.substring(controller.textStorage.allTokens[3].range))
        XCTAssertEqual("SCHEDULED: <2018-12-05 Wed>", textView.text.substring(controller.textStorage.allTokens[4].range))
        XCTAssertEqual("DEADLINE: <2018-12-05 Wed>", textView.text.substring(controller.textStorage.allTokens[5].range))
        XCTAssertEqual("*** DONE iOS platform structure project", textView.text.substring(controller.textStorage.allTokens[6].range))
        XCTAssertEqual("***", textView.text.substring(controller.textStorage.allTokens[7].range))
        XCTAssertEqual("DONE", textView.text.substring(controller.textStorage.allTokens[8].range))
        XCTAssertEqual("1. list the structure", textView.text.substring(controller.textStorage.allTokens[9].range))
        XCTAssertEqual("1", textView.text.substring(controller.textStorage.allTokens[10].range))
        XCTAssertEqual("2. make a tool to do it", textView.text.substring(controller.textStorage.allTokens[11].range))
        XCTAssertEqual("2", textView.text.substring(controller.textStorage.allTokens[12].range))
        
        controller.textStorage.currentLocation = 150
        controller.textStorage.adjustParseRange(NSRange(location: 150, length: 10))
        controller.textStorage.updateItemIndexAndRange(delta: 0)
        controller.textStorage.parser.parse(str: textView.text!, range: controller.textStorage.currentParseRange)
        controller.textStorage.updateCurrentInfo()
        
        XCTAssertEqual("* TODO fastlane design :movie:entertainment:\nSCHEDULED: <2018-12-05 Wed>\nDEADLINE: <2018-12-05 Wed>", textView.text.substring(controller.textStorage.allTokens[0].range))
        XCTAssertEqual("*", textView.text.substring(controller.textStorage.allTokens[1].range))
        XCTAssertEqual("TODO", textView.text.substring(controller.textStorage.allTokens[2].range))
        XCTAssertEqual(":movie:entertainment:", textView.text.substring(controller.textStorage.allTokens[3].range))
        XCTAssertEqual("SCHEDULED: <2018-12-05 Wed>", textView.text.substring(controller.textStorage.allTokens[4].range))
        XCTAssertEqual("DEADLINE: <2018-12-05 Wed>", textView.text.substring(controller.textStorage.allTokens[5].range))
        XCTAssertEqual("*** DONE iOS platform structure project", textView.text.substring(controller.textStorage.allTokens[6].range))
        XCTAssertEqual("***", textView.text.substring(controller.textStorage.allTokens[7].range))
        XCTAssertEqual("DONE", textView.text.substring(controller.textStorage.allTokens[8].range))
        XCTAssertEqual("1. list the structure", textView.text.substring(controller.textStorage.allTokens[9].range))
        XCTAssertEqual("1", textView.text.substring(controller.textStorage.allTokens[10].range))
        XCTAssertEqual("2. make a tool to do it", textView.text.substring(controller.textStorage.allTokens[11].range))
        XCTAssertEqual("2", textView.text.substring(controller.textStorage.allTokens[12].range))
    }
}
