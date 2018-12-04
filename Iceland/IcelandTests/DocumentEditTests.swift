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

public class DocumentEditTests: XCTestCase {
    public override func tearDown() {
        try? FileManager.default.contentsOfDirectory(atPath: File.Folder.document("files").path).forEach {
            try? FileManager.default.removeItem(atPath: "\(File.Folder.document("files").path)/\($0)")
        }
    }
    
    func testCreateDocument() throws {
        let document = Document(fileURL: URL(fileURLWithPath: "new file", relativeTo: File.Folder.document("files").url))
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                              document: document)
        
        let ex = expectation(description: "save")
        viewModel.editorController.string = "123"
        
        viewModel.save { _ in
            ex.fulfill()
            XCTAssertTrue(FileManager.default.fileExists(atPath: File(File.Folder.document("files"), fileName: "new file.org").filePath))
            XCTAssertEqual(try! String(contentsOfFile: File(File.Folder.document("files"), fileName: "new file.org").filePath,
                                      encoding: .utf8), "123")
        }
        
        wait(for: [ex], timeout: 1)
    }
    
    func testLoadDocument() {
        let ex = expectation(description: "load")
        let document = Document(fileURL: URL(fileURLWithPath: "load test", relativeTo: File.Folder.document("files").url))
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                              document: document)
        
        viewModel.editorController.string = "testLoadDocument"
        
        viewModel.save { _ in
            
            viewModel.close { _ in
                let viewModel2 = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                                       document: Document(fileURL: URL(fileURLWithPath: "load test", relativeTo: File.Folder.document("files").url)))
                
                viewModel2.open { [viewModel2] _ in
                    ex.fulfill()
                    XCTAssertEqual(viewModel2.editorController.string, "testLoadDocument")
                }
            }
            
        }
        
        wait(for: [ex], timeout: 1)
    }
    
    func testRenameDocument() {
        let document = Document(fileURL: URL(fileURLWithPath: "rename test", relativeTo: File.Folder.document("files").url))
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                              document: document)
        viewModel.editorController.string = "testRenameDocument"
        
        let ex = expectation(description: "load")
        viewModel.save { [weak viewModel] _ in
            viewModel?.rename(newTitle: "changed test") { _ in
                
                let document = Document(fileURL: URL(fileURLWithPath: "changed test", relativeTo: File.Folder.document("files").url))
                let viewModel2 = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                                       document: document)
                viewModel2.open { [viewModel2] _ in
                    XCTAssertEqual(viewModel2.editorController.string, "testRenameDocument")
                    ex.fulfill()
                }
            }
        }
        
        wait(for: [ex], timeout: 3)
    }
    
    func testDeleteDocument() {
        let document = Document(fileURL: URL(fileURLWithPath: "delete test", relativeTo: File.Folder.document("files").url))
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                              document: document)
        
        viewModel.editorController.string = "testDeleteDocument"
        viewModel.save { _ in
            
            XCTAssertEqual(FileManager.default.fileExists(atPath: File(File.Folder.document("files"), fileName: "delete test.org").filePath), true)
            viewModel.delete { _ in
                
                XCTAssertEqual(FileManager.default.fileExists(atPath: File(File.Folder.document("files"), fileName: "delete test.org").filePath), false)
            }
        }
    }
    
}
