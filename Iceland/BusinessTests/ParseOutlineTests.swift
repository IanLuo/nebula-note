//
//  ParseOutlineTests.swift
//  IcelandTests
//
//  Created by ian luo on 2018/11/13.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import XCTest
@testable import Business

class TestDelegate: OutlineParserDelegate {
    func didStartParsing(text: String) {}
    
    var didHit = false
    func didFoundLink(text: String, urlRanges: [[String : NSRange]]) {}
    func didFoundAttachment(text: String, attachmentRanges: [[String : NSRange]]) {}
    func didFoundCheckbox(text: String, checkboxRanges: [[String : NSRange]]) {}
    func didFoundOrderedList(text: String, orderedListRnages: [[String : NSRange]]) {}
    func didFoundUnOrderedList(text: String, unOrderedListRnages: [[String : NSRange]]) {}
    func didFoundSeperator(text: String, seperatorRanges: [[String : NSRange]]) {}
    func didFoundCodeBlock(text: String, codeBlockRanges: [[String : NSRange]]) {}
    func didFoundHeadings(text: String, headingDataRanges: [[String : NSRange]]) {}
    func didFoundTextMark(text: String, markRanges: [[String: NSRange]]) {}
    func didCompleteParsing(text: String) {}
}

public class ParseOutlineTests: XCTestCase {
    
    func testParseHeading() throws {
        let delegate = TestDelegate_()
        let parser = OutlineParser()
        parser.delegate = delegate
        
        let text =
"""
*** TODO Demo heading
SCHEDULED: <2018-12-05 Wed>
DEADLINE: <2018-12-05 Wed>
        asdfsadasafdsaddfasfd
        asdfsadfsa
        fsafsadf
        safdsadfsadfsadfsadfsad
**** TODO Demo heading
DEADLINE: <2018-12-05 Wed 17:30>
SCHEDULED: <2018-12-05 Wed 03:10>
        sdfsafsafsafsadf
        sfsafsafasdfsadf
        sfsadfsasdfds

***** CANCELED Demo heading3 :tag1:tag2:tag3:
DEADLINE: <2018-12-05 Wed>
        sdfsafsafsafsadf
        sfsafsafasdfsadf
        sfsadfsasdfds * not a heading
"""
        
        class TestDelegate_: TestDelegate {
            override func didFoundHeadings(text: String, headingDataRanges: [[String : NSRange]]) {
                XCTAssertEqual(3, headingDataRanges.count)
                XCTAssertEqual("TODO", (text as NSString).substring(with: headingDataRanges[0][OutlineParser.Key.Element.Heading.planning]!))
                XCTAssertEqual("DEADLINE: <2018-12-05 Wed>", (text as NSString).substring(with: headingDataRanges[0][OutlineParser.Key.Element.Heading.due]!))
                XCTAssertEqual("SCHEDULED: <2018-12-05 Wed>", (text as NSString).substring(with: headingDataRanges[0][OutlineParser.Key.Element.Heading.schedule]!))
                XCTAssertEqual("*** TODO Demo heading\nSCHEDULED: <2018-12-05 Wed>\nDEADLINE: <2018-12-05 Wed>", (text as NSString).substring(with: headingDataRanges[0][OutlineParser.Key.Node.heading]!))
                XCTAssertEqual("***", (text as NSString).substring(with: headingDataRanges[0][OutlineParser.Key.Element.Heading.level]!))
                
                XCTAssertEqual("TODO", (text as NSString).substring(with: headingDataRanges[1][OutlineParser.Key.Element.Heading.planning]!))
                XCTAssertEqual("DEADLINE: <2018-12-05 Wed 17:30>", (text as NSString).substring(with: headingDataRanges[1][OutlineParser.Key.Element.Heading.due]!))
                XCTAssertEqual("SCHEDULED: <2018-12-05 Wed 03:10>", (text as NSString).substring(with: headingDataRanges[1][OutlineParser.Key.Element.Heading.schedule]!))
                XCTAssertEqual("**** TODO Demo heading\nDEADLINE: <2018-12-05 Wed 17:30>\nSCHEDULED: <2018-12-05 Wed 03:10>", (text as NSString).substring(with: headingDataRanges[1][OutlineParser.Key.Node.heading]!))
                XCTAssertEqual("****", (text as NSString).substring(with: headingDataRanges[1][OutlineParser.Key.Element.Heading.level]!))
                
                XCTAssertEqual("CANCELED", (text as NSString).substring(with: headingDataRanges[2][OutlineParser.Key.Element.Heading.planning]!))
                XCTAssertEqual("DEADLINE: <2018-12-05 Wed>", (text as NSString).substring(with: headingDataRanges[2][OutlineParser.Key.Element.Heading.due]!))
                XCTAssertEqual(nil, headingDataRanges[2][OutlineParser.Key.Element.Heading.schedule])
                XCTAssertEqual("***** CANCELED Demo heading3 :tag1:tag2:tag3:\nDEADLINE: <2018-12-05 Wed>", (text as NSString).substring(with: headingDataRanges[2][OutlineParser.Key.Node.heading]!))
                XCTAssertEqual("*****", (text as NSString).substring(with: headingDataRanges[2][OutlineParser.Key.Element.Heading.level]!))
                XCTAssertEqual(":tag1:tag2:tag3:", (text as NSString).substring(with: headingDataRanges[2][OutlineParser.Key.Element.Heading.tags]!))
                
                didHit = true
            }
        }
        
        parser.parse(str: text)
        
        XCTAssert(delegate.didHit)
    }
    
    func testCheckbox() {
        class TestDelegate_: TestDelegate {
            override func didFoundCheckbox(text: String, checkboxRanges: [[String : NSRange]]) {
                XCTAssertEqual(" [-]", (text as NSString).substring(with: checkboxRanges[0][OutlineParser.Key.Node.checkbox]!))
                XCTAssertEqual("-", (text as NSString).substring(with: checkboxRanges[0][OutlineParser.Key.Element.Checkbox.status]!))
                
                XCTAssertEqual(" [X]", (text as NSString).substring(with: checkboxRanges[1][OutlineParser.Key.Node.checkbox]!))
                XCTAssertEqual("X", (text as NSString).substring(with: checkboxRanges[1][OutlineParser.Key.Element.Checkbox.status]!))
                
                XCTAssertEqual(" [ ]", (text as NSString).substring(with: checkboxRanges[2][OutlineParser.Key.Node.checkbox]!))
                XCTAssertEqual(" ", (text as NSString).substring(with: checkboxRanges[2][OutlineParser.Key.Element.Checkbox.status]!))
                
                XCTAssertEqual(" [ ]", (text as NSString).substring(with: checkboxRanges[3][OutlineParser.Key.Node.checkbox]!))
                XCTAssertEqual(" ", (text as NSString).substring(with: checkboxRanges[3][OutlineParser.Key.Element.Checkbox.status]!))
                
                XCTAssertEqual(" [ ]", (text as NSString).substring(with: checkboxRanges[4][OutlineParser.Key.Node.checkbox]!))
                XCTAssertEqual(" ", (text as NSString).substring(with: checkboxRanges[4][OutlineParser.Key.Element.Checkbox.status]!))
                
                didHit = true
            }
        }
        
        let delegate = TestDelegate_()
        
        let parser = OutlineParser()
        parser.delegate = delegate
        
        let text = """
        *** header 1
        - [-] do something
            - [X] sub task 1
            - [ ] sub task 2
        - [ ] do another
        - [ ] lastly

        """
        
        parser.parse(str: text)
        XCTAssert(delegate.didHit)
    }
    
    func testCodeBlock() {
        class TestDelegate_: TestDelegate {
            override func didFoundCodeBlock(text: String, codeBlockRanges: [[String : NSRange]]) {
                XCTAssertEqual(" swiftversion4.2", (text as NSString).substring(with: codeBlockRanges[0][OutlineParser.Key.Element.CodeBlock.language]!))
                XCTAssertEqual("what ever it is\nyeah", (text as NSString).substring(with: codeBlockRanges[0][OutlineParser.Key.Element.CodeBlock.content]!))
                
                XCTAssertEqual(nil, codeBlockRanges[1][OutlineParser.Key.Element.CodeBlock.language])
                XCTAssertEqual("", (text as NSString).substring(with: codeBlockRanges[1][OutlineParser.Key.Element.CodeBlock.content]!))
                didHit = true
            }
        }
        
        let delegate = TestDelegate_()
        let parser = OutlineParser()
        parser.delegate = delegate
        
        let text = """
        #+BEGIN_SRC swiftversion4.2
        what ever it is
        yeah
        #+END_SRC

        #+BEGIN_SRC

        #+END_SRC

        """
        
        parser.parse(str: text)
        
        XCTAssert(delegate.didHit)
    }
    
    func testOrderedList() {
        class TestDelegate_: TestDelegate {
            override func didFoundOrderedList(text: String, orderedListRnages: [[String : NSRange]]) {
                XCTAssertEqual("1. one", (text as NSString).substring(with: orderedListRnages[0][OutlineParser.Key.Node.ordedList]!))
                XCTAssertEqual("2. two", (text as NSString).substring(with: orderedListRnages[1][OutlineParser.Key.Node.ordedList]!))
                XCTAssertEqual("3. three", (text as NSString).substring(with: orderedListRnages[2][OutlineParser.Key.Node.ordedList]!))
                XCTAssertEqual("    1. three point one", (text as NSString).substring(with: orderedListRnages[3][OutlineParser.Key.Node.ordedList]!))
                XCTAssertEqual("    2. three point two", (text as NSString).substring(with: orderedListRnages[4][OutlineParser.Key.Node.ordedList]!))
                XCTAssertEqual("4. four", (text as NSString).substring(with: orderedListRnages[5][OutlineParser.Key.Node.ordedList]!))
                
                XCTAssertEqual("1.", (text as NSString).substring(with: orderedListRnages[0][OutlineParser.Key.Element.OrderedList.index]!))
                XCTAssertEqual("2.", (text as NSString).substring(with: orderedListRnages[1][OutlineParser.Key.Element.OrderedList.index]!))
                XCTAssertEqual("3.", (text as NSString).substring(with: orderedListRnages[2][OutlineParser.Key.Element.OrderedList.index]!))
                XCTAssertEqual("1.", (text as NSString).substring(with: orderedListRnages[3][OutlineParser.Key.Element.OrderedList.index]!))
                XCTAssertEqual("2.", (text as NSString).substring(with: orderedListRnages[4][OutlineParser.Key.Element.OrderedList.index]!))
                XCTAssertEqual("4.", (text as NSString).substring(with: orderedListRnages[5][OutlineParser.Key.Element.OrderedList.index]!))
                didHit = true
            }
        }
        
        let delegate = TestDelegate_()
        let parser = OutlineParser()
        parser.delegate = delegate
        
        let text = """
        1. one
        2. two
        3. three
            1. three point one
            2. three point two
        4. four

        """
        
        parser.parse(str: text)
        XCTAssert(delegate.didHit)
    }
    
    func testUnOrderedList() {
        class TestDelegate_: TestDelegate {
            override func didFoundUnOrderedList(text: String, unOrderedListRnages: [[String : NSRange]]) {
                XCTAssertEqual("- one", (text as NSString).substring(with: unOrderedListRnages[0][OutlineParser.Key.Node.unordedList]!))
                XCTAssertEqual("- three", (text as NSString).substring(with: unOrderedListRnages[1][OutlineParser.Key.Node.unordedList]!))
                XCTAssertEqual("    - three point one", (text as NSString).substring(with: unOrderedListRnages[2][OutlineParser.Key.Node.unordedList]!))
                XCTAssertEqual("    - three point two", (text as NSString).substring(with: unOrderedListRnages[3][OutlineParser.Key.Node.unordedList]!))
                XCTAssertEqual("- four", (text as NSString).substring(with: unOrderedListRnages[4][OutlineParser.Key.Node.unordedList]!))
                didHit = true
            }
        }
        
        let delegate = TestDelegate_()
        let parser = OutlineParser()
        parser.delegate = delegate
        
        let text = """
        - one
        - three
            - three point one
            - three point two
        - four

        """
        
        parser.parse(str: text)
        XCTAssert(delegate.didHit)
    }
    
    func testSeperator() {
        class TestDelegate_: TestDelegate {
            override func didFoundSeperator(text: String, seperatorRanges: [[String: NSRange]]) {
                XCTAssertEqual("-----", (text as NSString).substring(with: seperatorRanges[0][OutlineParser.Key.Node.seperator]!))
                XCTAssertEqual("------", (text as NSString).substring(with: seperatorRanges[1][OutlineParser.Key.Node.seperator]!))
                didHit = true
            }
        }
        
        let delegate = TestDelegate_()
        let parser = OutlineParser()
        parser.delegate = delegate
        
        let text = """
        sldjflsajdf
        -----
        lsjfdsafjsa;ldfj
        ---
        o;lsjf;lasjflasjdf
        ------

        """
        
        parser.parse(str: text)
        XCTAssert(delegate.didHit)
    }
    
    func testAttachment() {
        class TestDelegate_: TestDelegate {
            override func didFoundAttachment(text: String, attachmentRanges: [[String : NSRange]]) {
                XCTAssertEqual("image", (text as NSString).substring(with: attachmentRanges[0][OutlineParser.Key.Element.Attachment.type]!))
                XCTAssertEqual("LKJSL-DFJL-SDJF-LKDSD234234", (text as NSString).substring(with: attachmentRanges[0][OutlineParser.Key.Element.Attachment.value]!))
                didHit = true
            }
        }
        
        let delegate = TestDelegate_()
        let parser = OutlineParser()
        parser.delegate = delegate

        let text = """
        *** some title
        some paragraph
        #+ATTACHMENT:image=LKJSL-DFJL-SDJF-LKDSD234234
        """
        
        parser.parse(str: text)
        XCTAssert(delegate.didHit)
    }
    
    public func testLink() {
        class TestDelegate_: TestDelegate {
            override func didFoundLink(text: String, urlRanges: [[String: NSRange]]) {
                XCTAssertEqual("[[http://some.domain.com][the title]]", (text as NSString).substring(with: urlRanges[0][OutlineParser.Key.Element.link]!))
                XCTAssertEqual("the title", (text as NSString).substring(with: urlRanges[0][OutlineParser.Key.Element.Link.title]!))
                XCTAssertEqual("http://some.domain.com", (text as NSString).substring(with: urlRanges[0][OutlineParser.Key.Element.Link.url]!))
                XCTAssertEqual("[[https://another.domain.cn][second link title]]", (text as NSString).substring(with: urlRanges[1][OutlineParser.Key.Element.link]!))
                XCTAssertEqual("second link title", (text as NSString).substring(with: urlRanges[1][OutlineParser.Key.Element.Link.title]!))
                XCTAssertEqual("https://another.domain.cn", (text as NSString).substring(with: urlRanges[1][OutlineParser.Key.Element.Link.url]!))
                didHit = true
            }
        }
        
        let delegate = TestDelegate_()
        let parser = OutlineParser()
        parser.delegate = delegate
        
        let text = """
        *** some title
        some paragraph
        [[http://some.domain.com][the title]]
        hahah
        [[https://another.domain.cn][second link title]]
        """
        
        parser.parse(str: text)
        XCTAssert(delegate.didHit)
    }
    
    public func testTextMark() {
        class TestDelegate_: TestDelegate {
            override func didFoundTextMark(text: String, markRanges: [[String: NSRange]]) {
                XCTAssertEqual(3, markRanges.filter { $0.keys.first == OutlineParser.Key.Element.TextMark.bold }.count)
                XCTAssertEqual(2, markRanges.filter { $0.keys.first == OutlineParser.Key.Element.TextMark.italic }.count)
                XCTAssertEqual(2, markRanges.filter { $0.keys.first == OutlineParser.Key.Element.TextMark.underscore }.count)
                XCTAssertEqual(1, markRanges.filter { $0.keys.first == OutlineParser.Key.Element.TextMark.strikeThough }.count)
                XCTAssertEqual(4, markRanges.filter { $0.keys.first == OutlineParser.Key.Element.TextMark.code }.count)
                XCTAssertEqual(3, markRanges.filter { $0.keys.first == OutlineParser.Key.Element.TextMark.verbatim }.count)
                
                didHit = true
            }
        }
        
        let delegate = TestDelegate_()
        let parser = OutlineParser()
        parser.delegate = delegate
        
        let text = """
        *** some title
        some paragraph
        **** sub title of the content
        Regular expressions consist of *constants*, which *denote*,*sets* =of= ~strings~, ~and operator~ =symbols=, _which_ denote operations over these sets. The following definition is standard, and found as such in most textbooks on formal language theory.[19][20] Given =a= ~finite alphabet~ Σ, /the/ _following constants_ are /defined as regular/ +expressions+:
        [[the title][http://some.domain.com]]
        ~hahah~
        [[second link title][https://another.domain.cn]]
        """
        
        parser.parse(str: text)
        XCTAssert(delegate.didHit)
    }
    
    func testParseSchedule() {
        var string = "**** TODO Demo heading SCHEDULED: <2018-12-05 Wed>"
        if let date = DateAndTimeType.createFromSchedule(string)?.date {
            XCTAssertEqual(Calendar.current.component(.year, from: date), 2018)
            XCTAssertEqual(Calendar.current.component(.month, from: date), 12)
            XCTAssertEqual(Calendar.current.component(.day, from: date), 5)
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
        
        string = "** TODO Design                                                     :iceland:\nSCHEDULED: <2018-09-21 Fri 17:30>"
        if let date = DateAndTimeType.createFromSchedule(string)?.date {
            XCTAssertEqual(Calendar.current.component(.year, from: date), 2018)
            XCTAssertEqual(Calendar.current.component(.month, from: date), 9)
            XCTAssertEqual(Calendar.current.component(.day, from: date), 21)
            XCTAssertEqual(Calendar.current.component(.hour, from: date), 17)
            XCTAssertEqual(Calendar.current.component(.minute, from: date), 30)
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }
    
    func testParseDue() {
        var string = "**** TODO Demo heading                         \nDEADLINE: <2018-12-05 Wed>\nSCHEDULED: <2018-12-05 Wed>"
        if let date = DateAndTimeType.createFromDue(string)?.date {
            XCTAssertEqual(Calendar.current.component(.year, from: date), 2018)
            XCTAssertEqual(Calendar.current.component(.month, from: date), 12)
            XCTAssertEqual(Calendar.current.component(.day, from: date), 5)
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
        
        string = "**** TODO 接口\nDEADLINE: <2018-11-23 Fri>"
        if let date = DateAndTimeType.createFromDue(string)?.date {
            XCTAssertEqual(Calendar.current.component(.year, from: date), 2018)
            XCTAssertEqual(Calendar.current.component(.month, from: date), 11)
            XCTAssertEqual(Calendar.current.component(.day, from: date), 23)
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }
    
    func testRepeat() {
        let string = "**** TODO Demo heading                         \n<2018-12-05 Wed 9:00-21:00 +1d>"
        if let dateAndTime = DateAndTimeType.createFromDue(string) {
            XCTAssertEqual(Calendar.current.component(.year, from: dateAndTime.date), 2018)
            XCTAssertEqual(Calendar.current.component(.month, from: dateAndTime.date), 12)
            XCTAssertEqual(Calendar.current.component(.day, from: dateAndTime.date), 5)
            switch dateAndTime.repeateMode {
            case .day(let d)?: XCTAssertEqual(d, 1)
            default: XCTAssert(false)
            }
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }
    
    func testTimeRange() {
        var string = "**** TODO Demo heading                         \n<2018-12-05 Wed 9:00-21:00>"
        if let dateAndTime = DateAndTimeType.createFromTimeRange(string) {
            XCTAssertEqual(Calendar.current.component(.year, from: dateAndTime.date), 2018)
            XCTAssertEqual(Calendar.current.component(.month, from: dateAndTime.date), 12)
            XCTAssertEqual(Calendar.current.component(.day, from: dateAndTime.date), 5)
            XCTAssertEqual(dateAndTime.duration, 12 * 60 * 60)
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
        
        string = "**** TODO Demo heading                         \n<2018-12-05 9:00-21:00>"
        if let dateAndTime = DateAndTimeType.createFromTimeRange(string) {
            XCTAssertEqual(Calendar.current.component(.year, from: dateAndTime.date), 2018)
            XCTAssertEqual(Calendar.current.component(.month, from: dateAndTime.date), 12)
            XCTAssertEqual(Calendar.current.component(.day, from: dateAndTime.date), 5)
            XCTAssertEqual(dateAndTime.duration, 12 * 60 * 60)
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }
    
    func testDateRange() {
        var string = "**** TODO Demo heading                         \n<2018-12-05 Wed 9:00>--<2018-12-06 Thu 21:00>"
        if let dateAndTime = DateAndTimeType.createFromDateRange(string) {
            XCTAssertEqual(Calendar.current.component(.year, from: dateAndTime.date), 2018)
            XCTAssertEqual(Calendar.current.component(.month, from: dateAndTime.date), 12)
            XCTAssertEqual(Calendar.current.component(.day, from: dateAndTime.date), 5)
            XCTAssertEqual(dateAndTime.duration, 36 * 60 * 60)
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
        
        string = "**** TODO Demo heading                         \n<2018-12-05 9:00>--<2018-12-06 21:00>"
        if let dateAndTime = DateAndTimeType.createFromDateRange(string) {
            XCTAssertEqual(Calendar.current.component(.year, from: dateAndTime.date), 2018)
            XCTAssertEqual(Calendar.current.component(.month, from: dateAndTime.date), 12)
            XCTAssertEqual(Calendar.current.component(.day, from: dateAndTime.date), 5)
            XCTAssertEqual(dateAndTime.duration, 36 * 60 * 60)
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
        
        string = "**** TODO Demo heading                         \n<2018-12-05 Wed>--<2018-12-06 Thu>"
        if let dateAndTime = DateAndTimeType.createFromDateRange(string) {
            XCTAssertEqual(Calendar.current.component(.year, from: dateAndTime.date), 2018)
            XCTAssertEqual(Calendar.current.component(.month, from: dateAndTime.date), 12)
            XCTAssertEqual(Calendar.current.component(.day, from: dateAndTime.date), 5)
            XCTAssertEqual(dateAndTime.duration, 24 * 60 * 60)
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
        
        string = "**** TODO Demo heading                         \n<2018-12-05>--<2018-12-06>"
        if let dateAndTime = DateAndTimeType.createFromDateRange(string) {
            XCTAssertEqual(Calendar.current.component(.year, from: dateAndTime.date), 2018)
            XCTAssertEqual(Calendar.current.component(.month, from: dateAndTime.date), 12)
            XCTAssertEqual(Calendar.current.component(.day, from: dateAndTime.date), 5)
            XCTAssertEqual(dateAndTime.duration, 24 * 60 * 60)
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }
}
