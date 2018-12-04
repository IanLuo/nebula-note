//
//  DocumentTests.swift
//  IcelandTests
//
//  Created by ian luo on 2018/12/3.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import XCTest
@testable import Iceland
import Storage

public class DocumentTests: XCTestCase {
    public override func tearDown() {
        try? FileManager.default.contentsOfDirectory(atPath: File.Folder.document("files").path).forEach {
            try? FileManager.default.removeItem(atPath: "\(File.Folder.document("files").path)/\($0)")
        }
    }
    
    class DocumentDelegate: DocumentEditDelegate {
        let ex: XCTestExpectation
        init(ex: XCTestExpectation) { self.ex = ex }
        func didCloseDocument() {}
        func didFailedToCloseDocument() {}
        func didDeleteDocument(url: URL) {}
        func didFailedToDeleteDocument(error: Error) {}
        func didOpenDocument(text: String) {}
        func didFailedToOpenDocument(with error: Error) {}
        func didSaveDocument() {}
        func didFailedToSaveDocument(with error: Error) {}
        func didChangeFileTitle() {}
        func didFailToChangeFileTitle(with error: Error) {}
    }
    
    func testCreateDocument() throws {
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                              title: "new file")
        
        let ex = expectation(description: "save")
        class TextDelegate: DocumentDelegate {
            override func didSaveDocument() {
                ex.fulfill()
            }
        }
        
        let delegate = TextDelegate(ex: ex)
        viewModel.delegate = delegate
        viewModel.editorController.string = "123"
        
        viewModel.save { _ in
            XCTAssertTrue(FileManager.default.fileExists(atPath: File(File.Folder.document("files"), fileName: "new file").filePath))
            XCTAssertEqual(try! String(contentsOfFile: File(File.Folder.document("files"), fileName: "new file").filePath,
                                      encoding: .utf8), "123")
        }
        
        wait(for: [ex], timeout: 1)
    }
    
    func testLoadDocument() {
        let ex = expectation(description: "load")
        
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                              title: "load test")
        
        viewModel.editorController.string = "testLoadDocument"
        
        viewModel.save { _ in
            
            viewModel.close { _ in
                let viewModel2 = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                                       url: URL(fileURLWithPath: File(File.Folder.document("files"), fileName: "load test").filePath))
                
                viewModel2.open { [viewModel2] _ in
                    ex.fulfill()
                    XCTAssertEqual(viewModel2.editorController.string, "testLoadDocument")
                }
            }
            
        }
        
        wait(for: [ex], timeout: 1)
    }
    
    func testRenameDocument() {
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                              title: "rename test")
        viewModel.editorController.string = "testRenameDocument"
        
        let ex = expectation(description: "load")
        viewModel.save { [weak viewModel] _ in
            viewModel?.changeFileTitle(newTitle: "changed test") { _ in
                viewModel?.close { _ in
                    let viewModel2 = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                                           url: URL(fileURLWithPath: File(File.Folder.document("files"), fileName: "changed test").filePath))
                    viewModel2.open { [viewModel2] _ in
                        XCTAssertEqual(viewModel2.editorController.string, "testRenameDocument")
                        ex.fulfill()
                    }
                }
            }
        }
        
        wait(for: [ex], timeout: 3)
    }
    
    func testDeleteDocument() {
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                              title: "delete test")
        
        viewModel.editorController.string = "testDeleteDocument"
        viewModel.save { _ in
            
            XCTAssertEqual(FileManager.default.fileExists(atPath: File(File.Folder.document("files"), fileName: "delete test").filePath), true)
            viewModel.delete { _ in
                
                XCTAssertEqual(FileManager.default.fileExists(atPath: File(File.Folder.document("files"), fileName: "delete test").filePath), false)
            }
        }
        
        
    }
    
}
