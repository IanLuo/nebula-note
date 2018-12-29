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
        let url = URL(fileURLWithPath: "testCreateDocument.org", relativeTo: File.Folder.document("files").url)
        try "1".write(to: url, atomically: true, encoding: .utf8)
        let service = OutlineEditorServer.request(url: url)
        let ex = expectation(description: "")
        service.start { isOpen, s in
            XCTAssert(isOpen)
            s.string = "123"
            s.save {
                XCTAssert($0)
                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
                XCTAssertEqual(try! String(contentsOf: url), "123")
                ex.fulfill()
            }
        }
        
        wait(for: [ex], timeout: 2)
    }
    
    func testLoadDocument() {
        let ex = expectation(description: "load")
        let service = OutlineEditorServer.request(url: URL(fileURLWithPath: "load test.org", relativeTo: File.Folder.document("files").url))
        
        service.start {_, s in
            s.replace(text: "testLoadDocument", range: NSRange(location: 0, length: 0))
            s.close()
            
            s.start(complete: {_, s in
                ex.fulfill()
                XCTAssertEqual(s.string, "testLoadDocument")
            })
        }

        wait(for: [ex], timeout: 1)
    }
    
    func testRenameDocument() {
        let ex = expectation(description: "")
        OutlineEditorServer.request(url: URL(fileURLWithPath: "rename test", relativeTo: File.Folder.document("files").url))
            .start {_, s in
                s.string = "testRenameDocument"
                s.rename(newTitle: "changed test") { _ in
                    OutlineEditorServer.request(url: URL(fileURLWithPath: "changed test", relativeTo: File.Folder.document("files").url))
                        .start {_, s in
                            XCTAssertEqual(s.string, "testRenameDocument")
                            ex.fulfill()
                    }
                }
        }
        
        wait(for: [ex], timeout: 3)
    }
    
    func testDeleteDocument() throws {
        let ex = expectation(description: "")
        let url = URL(fileURLWithPath: "delete test.org", relativeTo: File.Folder.document("files").url)
        try "1".write(to: url, atomically: true, encoding: .utf8)
        XCTAssertEqual(FileManager.default.fileExists(atPath: url.path), true)
        OutlineEditorServer.request(url: url)
            .start {_, s in
                s.string = "testDeleteDocument"
                s.delete { _ in
                    XCTAssertEqual(FileManager.default.fileExists(atPath: url.path), false)
                    ex.fulfill()
                }
        }
        
        wait(for: [ex], timeout: 5)
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
    
    private func createDocumentForTest(text: String, complete: @escaping (Document?) -> Void) {
        let folder = File.Folder.temp("test")
        folder.createFolderIfNeeded()
        let tempURL = File(folder, fileName: "\(UUID().uuidString).org").url
        
        let document = Document(fileURL: tempURL)
        OutlineEditorServer.request(url: document.fileURL).close()
        document.string = text
        document.save(to: tempURL, for: UIDocument.SaveOperation.forCreating) {
            if $0 {
                complete(document)
            } else {
                complete(nil)
            }
        }
        
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
        createDocumentForTest(text: text) { document in
            guard let document = document else { XCTAssert(false); return }
            
            OutlineEditorServer.request(url: document.fileURL).start {_, s in
                var isHit = false
                s.add(tag: "test", at: s.headingList()[0].range.location)
                if let tags = s.headingList()[0].tags {
                    XCTAssertEqual(s.string.subString(tags), ":test:")
                    isHit = true
                }
                
                XCTAssertTrue(isHit)
                isHit = false
                
                s.add(tag: "test2", at: s.headingList()[0].range.location)
                if let tags = s.headingList()[0].tags {
                    XCTAssertEqual(s.string.subString(tags), ":test:test2:")
                    isHit = true
                }
                
                XCTAssertTrue(isHit)
                isHit = false
                
                let heading = s.heading(at: s.headingList()[0].range.location)!
                
                XCTAssertEqual(s.string.subString(heading.range), "* first heading :test:test2:")
                
                s.add(tag: "test3", at: s.headingList()[1].range.location)
                if let tags = s.headingList()[1].tags {
                    XCTAssertEqual(s.string.subString(tags), ":test3:")
                    isHit = true
                }
                
                XCTAssertTrue(isHit)
                isHit = false
                
                s.add(tag: "test4", at: s.headingList()[1].range.location)
                if let tags = s.headingList()[1].tags {
                    XCTAssertEqual(s.string.subString(tags), ":test3:test4:")
                    isHit = true
                }
                
                XCTAssertTrue(isHit)
                isHit = false
                
                let heading1 = s.heading(at: s.headingList()[1].range.location)!
                
                XCTAssertEqual(s.string.subString(heading1.range), "** second heading :test3:test4:")
                
                s.add(tag: "test5", at: s.headingList()[2].range.location)
                if let tags = s.headingList()[2].tags {
                    XCTAssertEqual(s.string.subString(tags), ":test5:")
                    isHit = true
                }
                
                XCTAssertTrue(isHit)
                isHit = false
                
                s.add(tag: "test6", at: s.headingList()[2].range.location)
                if let tags = s.headingList()[2].tags {
                    XCTAssertEqual(s.string.subString(tags), ":test5:test6:")
                    isHit = true
                }
                
                XCTAssertTrue(isHit)
                
                let heading2 = s.heading(at: s.headingList()[2].range.location)!
                
                XCTAssertEqual(s.string.subString(heading2.range), "*** third heading :test5:test6:")
                
                ex.fulfill()
            }
        }
        
        wait(for: [ex], timeout: 5)
    }
    
    func testRemoveTag() {
        let text = """
* first heading :test:
content in first
** second heading :tag1:tag2:
SCHEDULE:[2018-12-11]
content in second
*** third heading
SCHEDULE:[2018-12-11]
DEADLINE:[2018-12-11]
content in third
"""
        
        let ex = expectation(description: "test remove tag")
        createDocumentForTest(text: text) { (document) in
            
            guard let document = document else {  XCTAssert(false);return }
            OutlineEditorServer.request(url: document.fileURL).start {_, s in
                
                
                s.remove(tag: "test", at: s.headingList()[0].range.location)
                
                XCTAssertEqual("* first heading ", s.string.subString(s.headingList()[0].range))
                
                s.remove(tag: "tag2", at: s.headingList()[1].range.location)
                
                XCTAssertEqual("** second heading :tag1:", s.string.subString(s.headingList()[1].range))
                
                ex.fulfill()
            }
            
        }
        
        wait(for: [ex], timeout: 5)
    }
}
