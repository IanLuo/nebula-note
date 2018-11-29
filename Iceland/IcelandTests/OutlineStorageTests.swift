//
//  OutlineStorageTests.swift
//  IcelandTests
//
//  Created by ian luo on 2018/11/20.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import XCTest
@testable import Iceland

public class OutlineStorageTests: XCTestCase {
    func testExtendRange() {
        let text = """
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
    
        var extendedRange = NSRange(location: 10, length: 1).expand(string: text)
        
        XCTAssertEqual(0, extendedRange.location)
        XCTAssertEqual(17, extendedRange.length)
        
        extendedRange = NSRange(location: 31, length: 1).expand(string: text)
        XCTAssertEqual(17, extendedRange.location)
        XCTAssertEqual(23, extendedRange.length)
        
        extendedRange = NSRange(location: 16, length: 2).expand(string: text)
        XCTAssertEqual(0, extendedRange.location)
        XCTAssertEqual(40, extendedRange.length)
    }
    
    func testCurrentLocation() {
        let storage = OutlineTextStorage(parser: OutlineParser(delegate: nil))
        let textView = UITextView(frame: .zero, textContainer: storage.textContainer)
        textView.text = """
        * TODO fastlane design SCHEDULE:[2020-12-12] DEADLINE:[2022-12-11] :movie:entertainment:"
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
        XCTAssertEqual(2, storage.textStorage.savedDataHeadings.count)
        XCTAssertEqual(2, storage.textStorage.savedHeadings.count)
        XCTAssertEqual(storage.textStorage.currentHeading?.level, 1)
        XCTAssertEqual(storage.textStorage.currentHeading?.planning, "TODO")
        XCTAssertEqual(storage.textStorage.currentHeading?.schedule, "SCHEDULE:[2020-12-12]")
        XCTAssertEqual(storage.textStorage.currentHeading?.deadline, "DEADLINE:[2022-12-11]")
        XCTAssertEqual(storage.textStorage.currentHeading?.tags, ["movie", "entertainment"])
        
        storage.textStorage.currentLocation = 150
        storage.textStorage.updateCurrentInfo()
        XCTAssertEqual(storage.textStorage.currentHeading?.level, 3)
        XCTAssertEqual(storage.textStorage.currentHeading?.planning, "DONE")
        XCTAssertEqual(storage.textStorage.currentHeading?.schedule, nil)
        XCTAssertEqual(storage.textStorage.currentHeading?.deadline, nil)
        XCTAssertEqual(storage.textStorage.currentHeading?.tags, nil)
    }
    
    func testNewLoadItems() {
        let storage = OutlineTextStorage(parser: OutlineParser(delegate: nil))
        let textView = UITextView(frame: .zero, textContainer: storage.textContainer)
        textView.text = """
        * TODO fastlane design SCHEDULE:[2020-12-12] DEADLINE:[2022-12-11] :movie:entertainment:"
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
        XCTAssertEqual("* TODO fastlane design SCHEDULE:[2020-12-12] DEADLINE:[2022-12-11] :movie:entertainment:\"", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[0]))
        XCTAssertEqual("*", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[1]))
        XCTAssertEqual("TODO", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[2]))
        XCTAssertEqual("SCHEDULE:[2020-12-12]", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[3]))
        XCTAssertEqual("DEADLINE:[2022-12-11]", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[4]))
        XCTAssertEqual(":movie:entertainment:", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[5]))
        XCTAssertEqual("*** DONE iOS platform structure project", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[6]))
        XCTAssertEqual("***", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[7]))
        XCTAssertEqual("DONE", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[8]))
        XCTAssertEqual("1. list the structure", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[9]))
        XCTAssertEqual("1", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[10]))
        XCTAssertEqual("2. make a tool to do it", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[11]))
        XCTAssertEqual("2", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[12]))
    }
    
    func testEditItems() {
        let storage = OutlineTextStorage(parser: OutlineParser(delegate: nil))
        let textView = UITextView(frame: .zero, textContainer: storage.textContainer)
        textView.text = """
        * TODO fastlane design SCHEDULE:[2020-12-12] DEADLINE:[2022-12-11] :movie:entertainment:"
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
        XCTAssertEqual("* TODO fastlane design SCHEDULE:[2020-12-12] DEADLINE:[2022-12-11] :movie:entertainment:\"", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[0]))
        XCTAssertEqual("*", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[1]))
        XCTAssertEqual("TODO", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[2]))
        XCTAssertEqual("SCHEDULE:[2020-12-12]", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[3]))
        XCTAssertEqual("DEADLINE:[2022-12-11]", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[4]))
        XCTAssertEqual(":movie:entertainment:", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[5]))
        XCTAssertEqual("*** DONE iOS platform structure project", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[6]))
        XCTAssertEqual("***", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[7]))
        XCTAssertEqual("DONE", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[8]))
        XCTAssertEqual("1. list the structure", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[9]))
        XCTAssertEqual("1", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[10]))
        XCTAssertEqual("2. make a tool to do it", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[11]))
        XCTAssertEqual("2", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[12]))
        
        storage.textStorage.currentLocation = 150
        storage.textStorage.updateCurrentInfo()
        storage.textStorage.currentParseRange = NSRange(location: 150, length: 10).expand(string: textView.text!)
        storage.textStorage.updateItemIndexAndRange(delta: 0)
        storage.parser.parse(str: textView.text!, range: storage.textStorage.currentParseRange)
        
        XCTAssertEqual("* TODO fastlane design SCHEDULE:[2020-12-12] DEADLINE:[2022-12-11] :movie:entertainment:\"", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[0]))
        XCTAssertEqual("*", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[1]))
        XCTAssertEqual("TODO", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[2]))
        XCTAssertEqual("SCHEDULE:[2020-12-12]", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[3]))
        XCTAssertEqual("DEADLINE:[2022-12-11]", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[4]))
        XCTAssertEqual(":movie:entertainment:", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[5]))
        XCTAssertEqual("*** DONE iOS platform structure project", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[6]))
        XCTAssertEqual("***", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[7]))
        XCTAssertEqual("DONE", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[8]))
        XCTAssertEqual("1. list the structure", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[9]))
        XCTAssertEqual("1", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[10]))
        XCTAssertEqual("2. make a tool to do it", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[11]))
        XCTAssertEqual("2", (textView.text as NSString).substring(with: storage.textStorage.itemRanges[12]))
    }
}
