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
import Storage
import Business

public class DocumentSearchTests: XCTestCase {
    public override func setUp() {
        try? FileManager.default.contentsOfDirectory(atPath: File.Folder.document("files").path).forEach {
            try? FileManager.default.removeItem(atPath: "\(File.Folder.document("files").path)/\($0)")
        }
    }
    
    func testFindAllFiles() throws { 
        let fm = FileManager.default
        for i in 0..<100 {
            try fm.createDirectory(at: URL.documentBaseURL.appendingPathComponent("\(i)"), withIntermediateDirectories: false, attributes: nil)
            try "\(i)".data(using: .utf8)?.write(to: URL(fileURLWithPath: "\(i).org", relativeTo: URL.documentBaseURL))
            try "\(i)".data(using: .utf8)?.write(to: URL(fileURLWithPath: "\(i).org", relativeTo: URL.documentBaseURL.appendingPathComponent("\(i)")))
        }
        
        let files = DocumentSearchManager().loadAllFiles()
        
        XCTAssertEqual(files.count, 200)
    }
    
    func testSearchContent() {
        let ex = expectation(description: "search content")
        let searchManager = DocumentSearchManager()
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

        let searchManager = DocumentSearchManager()
        
        searchManager.search(tags: ["iceland", "ar"], resultAdded: { searchResult in
            searchResult.forEach {
                print($0.context)
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
        let searchManager = DocumentSearchManager()
        searchManager.search(schedule: Date(), resultAdded: { searchResult in
            searchResult.forEach {
                print($0.context)
                print("--------")
            }
        }, complete: {
            ex.fulfill()
        }, failed: { error in
            print(error)
        })
        
        wait(for: [ex], timeout: 10)
    }
    
    func testSearchDue() {
        let ex = expectation(description: "search due")
        let searchManager = DocumentSearchManager()
        searchManager.search(due: Date(), resultAdded: { searchResult in
            searchResult.forEach {
                print($0.context)
                print("--------")
            }
        }, complete: {
            ex.fulfill()
        }, failed: { error in
            print(error)
        })
        
        wait(for: [ex], timeout: 10)
    }
    
    func testSearchPlanning() {
        let ex = expectation(description: "search planning")
        let searchManager = DocumentSearchManager()
        searchManager.search(plannings: ["TODO", "NEXT"], resultAdded: { searchResult in
            searchResult.forEach {
                print($0.context)
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
