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
    class DocumentDelegate: DocumentEditDelegate {
        let ex: XCTestExpectation
        init(ex: XCTestExpectation) { self.ex = ex }
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
        
        viewModel.save()
        
        wait(for: [ex], timeout: 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: File(File.Folder.document("files"), fileName: "new file").filePath))
        XCTAssertEqual(try String(contentsOfFile: File(File.Folder.document("files"), fileName: "new file").filePath,
                                  encoding: .utf8), "123")
    }
    
    func testLoadDocument() {
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                              title: "new file")
        
        viewModel.editorController.string = "1111111111"
        viewModel.save()
        
        let viewModel2 = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                              url: URL(fileURLWithPath: File(File.Folder.document("files"), fileName: "new file").filePath))
        
        let ex = expectation(description: "load")
        class TextDelegate: DocumentDelegate {
            override func didOpenDocument(text: String) {
                ex.fulfill()
            }
        }
        
        let delegate = TextDelegate(ex: ex)
        viewModel2.delegate = delegate
        viewModel2.loadDocument()
        
        wait(for: [ex], timeout: 1)
        XCTAssertEqual(viewModel2.editorController.string, "1111111111")
    }
    
    func testRenameDocument() {
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                              title: "new file")
        
        viewModel.editorController.string = "1111111111"
        viewModel.save()
        viewModel.changeFileTitle(newTitle: "changed")
        
        let viewModel2 = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                               url: URL(fileURLWithPath: File(File.Folder.document("files"), fileName: "changed").filePath))
        
        let ex = expectation(description: "load")
        class TextDelegate: DocumentDelegate {
            override func didOpenDocument(text: String) {
                ex.fulfill()
            }
            
            override func didFailedToOpenDocument(with error: Error) {
                print(error)
            }
        }
        
        let delegate = TextDelegate(ex: ex)
        viewModel2.delegate = delegate
        viewModel2.loadDocument()
        
        wait(for: [ex], timeout: 1)
        XCTAssertEqual(viewModel2.editorController.string, "1111111111")
    }
    
    func testDeleteDocument() {
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                              title: "new file")
        
        viewModel.editorController.string = "1111111111"
        viewModel.save()
        
        XCTAssertEqual(FileManager.default.fileExists(atPath: File(File.Folder.document("files"), fileName: "new file").filePath), true)
        viewModel.delete()
        
        XCTAssertEqual(FileManager.default.fileExists(atPath: File(File.Folder.document("files"), fileName: "new file").filePath), false)
    }
    
}
