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

public class DocumentSearchTests: XCTestCase {
    public override func setUp() {
        try? FileManager.default.contentsOfDirectory(atPath: File.Folder.document("files").path).forEach {
            try? FileManager.default.removeItem(atPath: "\(File.Folder.document("files").path)/\($0)")
        }
    }
    
    func testFindAllFiles() throws {        
        let fm = FileManager.default
        for i in 0..<100 {
            try fm.createDirectory(at: URL.filesFolder.appendingPathComponent("\(i)"), withIntermediateDirectories: false, attributes: nil)
            try "\(i)".data(using: .utf8)?.write(to: URL(fileURLWithPath: "\(i).org", relativeTo: URL.filesFolder))
            try "\(i)".data(using: .utf8)?.write(to: URL(fileURLWithPath: "\(i).org", relativeTo: URL.filesFolder.appendingPathComponent("\(i)")))
        }
        
        let files = DocumentSearchManager().loadAllFiles()
        
        XCTAssertEqual(files.count, 200)
    }
    
    func testSearchContent() {
        let ex = expectation(description: "search content")
        let viewModel = DocumentSearchViewModel(documentSearchManager: DocumentSearchManager())
        viewModel.search(contain: "dribbble", resultAdded: { searchResult in
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
        let viewModel = DocumentSearchViewModel(documentSearchManager: DocumentSearchManager())
        viewModel.search(tags: ["iceland", "ar"], resultAdded: { searchResult in
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
        let viewModel = DocumentSearchViewModel(documentSearchManager: DocumentSearchManager())
        viewModel.search(schedule: Date(), resultAdded: { searchResult in
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
        let viewModel = DocumentSearchViewModel(documentSearchManager: DocumentSearchManager())
        viewModel.search(due: Date(), resultAdded: { searchResult in
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
        let viewModel = DocumentSearchViewModel(documentSearchManager: DocumentSearchManager())
        viewModel.search(plannings: ["TODO", "NEXT"], resultAdded: { searchResult in
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
