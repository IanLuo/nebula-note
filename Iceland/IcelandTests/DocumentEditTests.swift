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
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: document)
        
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
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: document)
        
        viewModel.editorController.string = "testLoadDocument"
        
        viewModel.save { _ in
            
            viewModel.close { _ in
                let viewModel2 = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: Document(fileURL: URL(fileURLWithPath: "load test", relativeTo: File.Folder.document("files").url)))
                
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
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: document)
        viewModel.editorController.string = "testRenameDocument"
        
        let ex = expectation(description: "load")
        viewModel.save { [weak viewModel] _ in
            viewModel?.rename(newTitle: "changed test") { _ in
                
                let document = Document(fileURL: URL(fileURLWithPath: "changed test", relativeTo: File.Folder.document("files").url))
                let viewModel2 = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: document)
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
        let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: document)
        
        viewModel.editorController.string = "testDeleteDocument"
        viewModel.save { _ in
            
            XCTAssertEqual(FileManager.default.fileExists(atPath: File(File.Folder.document("files"), fileName: "delete test.org").filePath), true)
            viewModel.delete { _ in
                
                XCTAssertEqual(FileManager.default.fileExists(atPath: File(File.Folder.document("files"), fileName: "delete test.org").filePath), false)
            }
        }
    }
    
    func testGetParagraph() {
        let text = """
* first heading
content in first
** second heading
content in second
*** third heading
content in third
"""
        
        let editorController = EditorController(parser: OutlineParser())
        editorController.string = text
        
        let paragraphs = editorController.getParagraphs()
        
        XCTAssertEqual(paragraphs.count, 3)
        XCTAssertEqual(paragraphs[0].level, 1)
        XCTAssertEqual(paragraphs[1].level, 2)
        XCTAssertEqual(paragraphs[2].level, 3)
        XCTAssertEqual((text as NSString).substring(with: paragraphs[0].paragraphRange), "* first heading\ncontent in first")
        XCTAssertEqual((text as NSString).substring(with: paragraphs[1].paragraphRange), "** second heading\ncontent in second")
        XCTAssertEqual((text as NSString).substring(with: paragraphs[2].paragraphRange), "*** third heading\ncontent in third")
    }
    
    func testInsertParagraph() {
        let text = """
* first heading
content in first
** second heading
content in second
*** third heading
content in third
"""
        
        let editorController = EditorController(parser: OutlineParser())
        editorController.string = text
        
        let paragraphs = editorController.getParagraphs()
        
        XCTAssertEqual(paragraphs.count, 3)
        XCTAssertEqual(paragraphs[0].level, 1)
        XCTAssertEqual(paragraphs[1].level, 2)
        XCTAssertEqual(paragraphs[2].level, 3)
        XCTAssertEqual((editorController.string as NSString).substring(with: paragraphs[0].paragraphRange), "* first heading\ncontent in first")
        XCTAssertEqual((editorController.string as NSString).substring(with: paragraphs[1].paragraphRange), "** second heading\ncontent in second")
        XCTAssertEqual((editorController.string as NSString).substring(with: paragraphs[2].paragraphRange), "*** third heading\ncontent in third")
        
        editorController.insertToParagraph(at: paragraphs[0], content: "first added content")
        editorController.insertToParagraph(at: paragraphs[1], content: "second added content")
        editorController.insertToParagraph(at: paragraphs[2], content: "third added content")
        
        let paragraphs2 = editorController.getParagraphs()
        XCTAssertEqual(paragraphs2.count, 3)
        XCTAssertEqual(paragraphs2[0].level, 1)
        XCTAssertEqual(paragraphs2[1].level, 2)
        XCTAssertEqual(paragraphs2[2].level, 3)
        XCTAssertEqual((editorController.string as NSString).substring(with: paragraphs2[0].paragraphRange), "* first heading\ncontent in first\nfirst added content")
        XCTAssertEqual((editorController.string as NSString).substring(with: paragraphs2[1].paragraphRange), "** second heading\ncontent in second\nsecond added content")
        XCTAssertEqual((editorController.string as NSString).substring(with: paragraphs2[2].paragraphRange), "*** third heading\ncontent in third\nthird added content")
    }
    
    func testAddTag() {
        let text = """
* first heading
content in first
** second heading
SCHEDULE:[2018-12-11]
content in second
*** third heading
SCHEDULE:[2018-12-11]
DEADLINE:[2018-12-11]
content in third
"""
        let ex = expectation(description: "add tag")
        let folder = File.Folder.temp("test")
        folder.createFolderIfNeeded()
        let tempURL = File(folder, fileName: "text.org").url
        
        let document = Document(fileURL: tempURL)
        document.string = text
        document.save(to: tempURL, for: UIDocument.SaveOperation.forCreating) {
            if $0 == false {
                XCTAssert(false)
            } else {
                let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: document)
                
                viewModel.open {
                    XCTAssert($0 != nil)
                    var isHit = false
                    viewModel.add(tag: "test", at: viewModel.headingList()[0].range.location, completion: {
                        XCTAssert($0)
                        if let tags = viewModel.headingList()[0].tags {
                            XCTAssertEqual(document.string.subString(tags), ":test:")
                            isHit = true
                        }
                    })
                    
                    XCTAssertTrue(isHit)
                    isHit = false
                    
                    viewModel.add(tag: "test2", at: viewModel.headingList()[0].range.location, completion: {
                        XCTAssert($0)
                        if let tags = viewModel.headingList()[0].tags {
                            XCTAssertEqual(document.string.subString(tags), ":test:test2:")
                            isHit = true
                        }
                    })
                    
                    XCTAssertTrue(isHit)
                    isHit = false
                    
                    let heading = viewModel.heading(at: viewModel.headingList()[0].range.location)!
                    
                    XCTAssertEqual(document.string.subString(heading.range), "* first heading :test:test2:")
                    
                    viewModel.add(tag: "test3", at: viewModel.headingList()[1].range.location, completion: {
                        XCTAssert($0)
                        if let tags = viewModel.headingList()[1].tags {
                            XCTAssertEqual(document.string.subString(tags), ":test3:")
                            isHit = true
                        }
                    })
                    
                    XCTAssertTrue(isHit)
                    isHit = false
                    
                    viewModel.add(tag: "test4", at: viewModel.headingList()[1].range.location, completion: {
                        XCTAssert($0)
                        if let tags = viewModel.headingList()[1].tags {
                            XCTAssertEqual(document.string.subString(tags), ":test3:test4:")
                            isHit = true
                        }
                    })
                    
                    XCTAssertTrue(isHit)
                    isHit = false
                    
                    let heading1 = viewModel.heading(at: viewModel.headingList()[1].range.location)!
                    
                    XCTAssertEqual(document.string.subString(heading1.range), "** second heading :test3:test4:")
                    
                    viewModel.add(tag: "test5", at: viewModel.headingList()[2].range.location, completion: {
                        XCTAssert($0)
                        if let tags = viewModel.headingList()[2].tags {
                            XCTAssertEqual(document.string.subString(tags), ":test5:")
                            isHit = true
                        }
                    })
                    
                    XCTAssertTrue(isHit)
                    isHit = false
                    
                    viewModel.add(tag: "test6", at: viewModel.headingList()[2].range.location, completion: {
                        XCTAssert($0)
                        if let tags = viewModel.headingList()[2].tags {
                            XCTAssertEqual(document.string.subString(tags), ":test5:test6:")
                            isHit = true
                        }
                    })
                    
                    XCTAssertTrue(isHit)
                    
                    let heading2 = viewModel.heading(at: viewModel.headingList()[2].range.location)!
                    
                    XCTAssertEqual(document.string.subString(heading2.range), "*** third heading :test5:test6:")
                    
                    ex.fulfill()
                }
            }
        }
        
        wait(for: [ex], timeout: 5)
    }
}
