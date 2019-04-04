//
//  DocumentSearchTests.swift
//  IcelandTests
//
//  Created by ian luo on 2018/12/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import XCTest
@testable import Iceland
import Business

public class DocumentSearchTests: XCTestCase {
    public override func setUp() {
        let url = URL.directory(location: URLLocation.document, relativePath: "files")
        try? FileManager.default.contentsOfDirectory(atPath: url.path).forEach {
            try? FileManager.default.removeItem(atPath: "\(url.path)/\($0)")
        }
    }
    
    func testFindAllFiles() throws { 
        let fm = FileManager.default
        for i in 0..<100 {
            try fm.createDirectory(at: URL.documentBaseURL.appendingPathComponent("\(i)"), withIntermediateDirectories: false, attributes: nil)
            try "\(i)".data(using: .utf8)?.write(to: URL(fileURLWithPath: "\(i).org", relativeTo: URL.documentBaseURL))
            try "\(i)".data(using: .utf8)?.write(to: URL(fileURLWithPath: "\(i).org", relativeTo: URL.documentBaseURL.appendingPathComponent("\(i)")))
        }
        
        let files = DocumentSearchManager(eventObserver: EventObserver(), editorContext: EditorContext(eventObserver: EventObserver())).loadAllFiles()
        
        XCTAssertEqual(files.count, 200)
    }
    
    func testSearchContent() {
        let ex = expectation(description: "search content")
        let searchManager = DocumentSearchManager(eventObserver: EventObserver(), editorContext: EditorContext(eventObserver: EventObserver()))
        searchManager.search(contain: "dribbble", resultAdded: { searchResult in
            searchResult.forEach {
                print($0.context)
            }
        }, complete: {
            ex.fulfill()
        }, failed: { error in
            print(error)
        })
        
        wait(for: [ex], timeout: 10)
    }
    
    func testSearchTag() {
        let ex = expectation(description: "search tags")

        let searchManager = DocumentSearchManager(eventObserver: EventObserver(), editorContext: EditorContext(eventObserver: EventObserver()))
        
        let tags: [String] = ["iceland", "ar"]
        searchManager.searchHeading(options: [.tag], filter: { (heading: DocumentHeading) -> Bool in
            for t in heading.tags! {
                return tags.contains(t)
            }
            
            return false
        }, resultAdded: { (results: [DocumentHeading]) in
            results.forEach {
                print($0.text)
                print("--------")
            }
        }, complete: {
            ex.fulfill()
        }, failed: { error in
            print(error)
        })
        
        wait(for: [ex], timeout: 10)
    }
    
    func testSearchSchedule() {
        let ex = expectation(description: "search schedule")
        let searchManager = DocumentSearchManager(eventObserver: EventObserver(), editorContext: EditorContext(eventObserver: EventObserver()))
        let today: Date = Date()
        
//        searchManager.searchHeading(options: [.schedule], filter: { (heading: DocumentHeading) -> Bool in
//            return heading.schedule!.date <= today
//        }, resultAdded: { (results: [DocumentHeading]) in
//            results.forEach {
//                print($0.text)
//                print("--------")
//            }
//        }, complete: {
//            ex.fulfill()
//        }, failed: { error in
//            print(error)
//        })
        
        wait(for: [ex], timeout: 10)
    }
    
    func testSearchDue() {
        let ex = expectation(description: "search due")
        let searchManager = DocumentSearchManager(eventObserver: EventObserver(), editorContext: EditorContext(eventObserver: EventObserver()))
        let today: Date = Date()
//        
//        searchManager.searchHeading(options: [.due], filter: { (heading: DocumentHeading) -> Bool in
//            return heading.due!.date <= today
//        }, resultAdded: { (results: [DocumentHeading]) in
//            results.forEach {
//                print($0.text)
//                print("--------")
//            }
//        }, complete: {
//            ex.fulfill()
//        }, failed: { error in
//            print(error)
//        })
        
        wait(for: [ex], timeout: 10)
    }
    
    func testSearchPlanning() {
        let ex = expectation(description: "search planning")
        let searchManager = DocumentSearchManager(eventObserver: EventObserver(), editorContext: EditorContext(eventObserver: EventObserver()))
        let plannings: [String] = ["TODO", "NEXT"]
        
        searchManager.searchHeading(options: [.planning], filter: { (heading: DocumentHeading) -> Bool in
            return plannings.contains(heading.planning!)
        }, resultAdded: { (results: [DocumentHeading]) in
            results.forEach {
                print($0.text)
                print("--------")
            }
        }, complete: {
            ex.fulfill()
        }, failed: { error in
            print(error)
        })
        
        wait(for: [ex], timeout: 10)
    }
}
