//
//  DocumentBrowserTests.swift
//  IcelandTests
//
//  Created by ian luo on 2018/12/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import XCTest
@testable import Iceland
import Business

public class DocumentBrowserTests: XCTestCase {
    public override func tearDown() {
        let url = URL.directory(location: URLLocation.document, relativePath: "files")
        try? FileManager.default.contentsOfDirectory(atPath: url.path).forEach {
            try? FileManager.default.removeItem(atPath: "\(url.path)/\($0)")
        }
    }
    
//    func testCreateDocument() {
//        let viewModel = DocumentBrowserViewModel(documentManager: DocumentManager())
//        let ex = expectation(description: "create")
//        viewModel.createDocument(title: "test create document") { document in
//            let fm = FileManager.default
//
//            XCTAssertTrue(fm.fileExists(atPath: File(File.Folder.document("files"), fileName: "test create document.org").filePath))
//
//            ex.fulfill()
//        }
//
//        wait(for: [ex], timeout: 5)
//    }
//
//    func testRenameFileBelowAnotherDocument() {
//        let viewModel = DocumentBrowserViewModel(documentManager: DocumentManager())
//        let ex = expectation(description: "testRenameFileBelowAnotherDocument")
//        viewModel.createDocument(title: "test create document") { url in
//            let fm = FileManager.default
//
//            XCTAssertTrue(fm.fileExists(atPath: File(File.Folder.document("files"), fileName: "test create document.org").filePath))
//
//            viewModel.createDocument(title: "test add document below the first one", below: url) { _ in
//                let path = File(File.Folder.document("files/test create document__"), fileName: "test add document below the first one.org").filePath
//                print(path)
//                XCTAssertTrue(fm.fileExists(atPath: path))
//
//                ex.fulfill()
//            }
//        }
//
//        wait(for: [ex], timeout: 5)
//    }
//
//    func testFindDocuments() throws {
//        let viewModel = DocumentBrowserViewModel(documentManager: DocumentManager())
//        let ex = expectation(description: "testFindDocuments")
//        viewModel.createDocument(title: "my jorney") { url in
//
//            viewModel.createDocument(title: "monday", below: url) { _ in
//
//                viewModel.createDocument(title: "tuesday", below: url) { _ in
//
//                    XCTAssertEqual(try! viewModel.findDocuments(under: nil).count, 1)
//                    XCTAssertEqual(try! viewModel.findDocuments(under: url).count, 2)
//
//                    ex.fulfill()
//                }
//            }
//        }
//
//        wait(for: [ex], timeout: 5)
//    }
}
