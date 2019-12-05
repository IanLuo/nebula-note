////
////  DocumentTests.swift
////  IcelandTests
////
////  Created by ian luo on 2018/12/3.
////  Copyright © 2018 wod. All rights reserved.
////
//
//import Foundation
//import XCTest
//@testable import Business
//
//public class DocumentEditTests: XCTestCase {
//    public override func tearDown() {
//        let url = URL.directory(location: URLLocation.document, relativePath: "files")
//        try? FileManager.default.contentsOfDirectory(atPath: url.path).forEach {
//            try? FileManager.default.removeItem(atPath: "\(url.path)/\($0)")
//        }
//    }
//    
//    let editorContext = EditorContext(eventObserver: EventObserver())
//    
//    func testCreateDocument() throws {
//        let url = URL(fileURLWithPath: "testCreateDocument.org", relativeTo: URL.directory(location: URLLocation.document, relativePath: "files"))
//        try "1".write(to: url, atomically: true, encoding: .utf8)
//        let service = editorContext.request(url: url)
//        let ex = expectation(description: "")
//        service.start { isOpen, s in
//            XCTAssert(isOpen)
//            s.string = "123"
//            s.save {
//                XCTAssert($0)
//                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
//                XCTAssertEqual(try! String(contentsOf: url), "123")
//                ex.fulfill()
//            }
//        }
//        
//        wait(for: [ex], timeout: 2)
//    }
//    
//    func testLoadDocument() {
//        let ex = expectation(description: "load")
//        let service = editorContext.request(url: URL(fileURLWithPath: "load test.org", relativeTo: URL.directory(location: URLLocation.document, relativePath: "files")))
//        
//        service.start {_, s in
//            s.replace(text: "testLoadDocument", range: NSRange(location: 0, length: 0))
//            s.close()
//            
//            s.start(complete: {_, s in
//                ex.fulfill()
//                XCTAssertEqual(s.string, "testLoadDocument")
//            })
//        }
//
//        wait(for: [ex], timeout: 1)
//    }
//    
//    func testRenameDocument() {
//        let ex = expectation(description: "")
//        editorContext.request(url: URL(fileURLWithPath: "rename test", relativeTo: URL.directory(location: URLLocation.document, relativePath: "files")))
//            .start {_, s in
//                s.string = "testRenameDocument"
//                s.rename(newTitle: "changed test") { _ in
//                    self.editorContext.request(url: URL(fileURLWithPath: "changed test", relativeTo: URL.directory(location: URLLocation.document, relativePath: "files")))
//                        .start {_, s in
//                            XCTAssertEqual(s.string, "testRenameDocument")
//                            ex.fulfill()
//                    }
//                }
//        }
//        
//        wait(for: [ex], timeout: 3)
//    }
//    
//    func testDeleteDocument() throws {
//        let ex = expectation(description: "")
//        let url = URL(fileURLWithPath: "delete test.org", relativeTo: URL.directory(location: URLLocation.document, relativePath: "files"))
//        try "1".write(to: url, atomically: true, encoding: .utf8)
//        XCTAssertEqual(FileManager.default.fileExists(atPath: url.path), true)
//        editorContext.request(url: url)
//            .start {_, s in
//                s.string = "testDeleteDocument"
//                s.delete { _ in
//                    XCTAssertEqual(FileManager.default.fileExists(atPath: url.path), false)
//                    ex.fulfill()
//                }
//        }
//        
//        wait(for: [ex], timeout: 5)
//    }
//    
//    func testGetParagraph() {
//        let text = """
//* first heading
//content in first
//** second heading
//content in second
//*** third heading
//content in third
//"""
//        
//        let editorController = EditorController(parser: OutlineParser(), eventObserver: EventObserver(), attachmentManager: AttachmentManager())
//        editorController.string = text
//        
//        let paragraphs = editorController.getParagraphs()
//        
//        XCTAssertEqual(paragraphs.count, 3)
//        XCTAssertEqual(paragraphs[0].level, 1)
//        XCTAssertEqual(paragraphs[1].level, 2)
//        XCTAssertEqual(paragraphs[2].level, 3)
//        XCTAssertEqual((text as NSString).substring(with: paragraphs[0].paragraphRange), "* first heading\ncontent in first")
//        XCTAssertEqual((text as NSString).substring(with: paragraphs[1].paragraphRange), "** second heading\ncontent in second")
//        XCTAssertEqual((text as NSString).substring(with: paragraphs[2].paragraphRange), "*** third heading\ncontent in third")
//    }
//    
//    func testInsertParagraph() {
//        let text = """
//* first heading
//content in first
//** second heading
//content in second
//*** third heading
//content in third
//"""
//        
//        let editorController = EditorController(parser: OutlineParser(), eventObserver: EventObserver(), attachmentManager: AttachmentManager())
//        editorController.string = text
//        
//        let paragraphs = editorController.getParagraphs()
//        
//        XCTAssertEqual(paragraphs.count, 3)
//        XCTAssertEqual(paragraphs[0].level, 1)
//        XCTAssertEqual(paragraphs[1].level, 2)
//        XCTAssertEqual(paragraphs[2].level, 3)
//        XCTAssertEqual((editorController.string as NSString).substring(with: paragraphs[0].paragraphRange), "* first heading\ncontent in first")
//        XCTAssertEqual((editorController.string as NSString).substring(with: paragraphs[1].paragraphRange), "** second heading\ncontent in second")
//        XCTAssertEqual((editorController.string as NSString).substring(with: paragraphs[2].paragraphRange), "*** third heading\ncontent in third")
//        
//        editorController.insertToParagraph(at: paragraphs[0], content: "first added content")
//        editorController.insertToParagraph(at: paragraphs[1], content: "second added content")
//        editorController.insertToParagraph(at: paragraphs[2], content: "third added content")
//        
//        let paragraphs2 = editorController.getParagraphs()
//        XCTAssertEqual(paragraphs2.count, 3)
//        XCTAssertEqual(paragraphs2[0].level, 1)
//        XCTAssertEqual(paragraphs2[1].level, 2)
//        XCTAssertEqual(paragraphs2[2].level, 3)
//        XCTAssertEqual((editorController.string as NSString).substring(with: paragraphs2[0].paragraphRange), "* first heading\ncontent in first\nfirst added content")
//        XCTAssertEqual((editorController.string as NSString).substring(with: paragraphs2[1].paragraphRange), "** second heading\ncontent in second\nsecond added content")
//        XCTAssertEqual((editorController.string as NSString).substring(with: paragraphs2[2].paragraphRange), "*** third heading\ncontent in third\nthird added content")
//    }
//    
//    private func createDocumentForTest(text: String, complete: @escaping (Document?) -> Void) {
//        let folder = URL.directory(location: URLLocation.temporary, relativePath: "test")
//        folder.createDirectoryIfNeeded { _ in
//            
//            let tempURL = URL.file(directory: folder, name: UUID().uuidString, extension: "orf")
//            
//            let document = Document(fileURL: tempURL)
//            self.editorContext.request(url: document.fileURL).close()
//            document.updateContent(text)
//            document.save(to: tempURL, for: UIDocument.SaveOperation.forCreating) {
//                if $0 {
//                    complete(document)
//                } else {
//                    complete(nil)
//                }
//            }
//        }
//        
//    }
//    
//    func testAddTag() {
//        let text = """
//* first heading
//content in first
//** second heading
//SCHEDULE: <2018-12-11>
//content in second
//*** third heading
//SCHEDULE: <2018-12-11>
//DEADLINE: <2018-12-11>
//content in third
//"""
//        let ex = expectation(description: "add tag")
//        createDocumentForTest(text: text) { document in
//            guard let document = document else { XCTAssert(false); return }
//            
//            self.editorContext.request(url: document.fileURL).start {_, s in
//                var isHit = false
//                s.toggleContentAction(command: TagCommand(location: s.headingList()[0].range.location, kind: .add("test")))
//                if let tags = s.headingList()[0].tags {
//                    XCTAssertEqual(s.string.substring(tags), ":test:")
//                    isHit = true
//                }
//                
//                XCTAssertTrue(isHit)
//                isHit = false
//                
//                s.toggleContentAction(command: TagCommand(location: s.headingList()[0].range.location, kind: .add("tests")))
//                if let tags = s.headingList()[0].tags {
//                    XCTAssertEqual(s.string.substring(tags), ":test:test2:")
//                    isHit = true
//                }
//                
//                XCTAssertTrue(isHit)
//                isHit = false
//                
//                let heading = s.heading(at: s.headingList()[0].range.location)!
//                
//                XCTAssertEqual(s.string.substring(heading.range), "* first heading :test:test2:")
//                
//                s.toggleContentAction(command: TagCommand(location: s.headingList()[0].range.location, kind: .add("test3")))
//                if let tags = s.headingList()[1].tags {
//                    XCTAssertEqual(s.string.substring(tags), ":test3:")
//                    isHit = true
//                }
//                
//                XCTAssertTrue(isHit)
//                isHit = false
//                
//                s.toggleContentAction(command: TagCommand(location: s.headingList()[0].range.location, kind: .add("test4")))
//                if let tags = s.headingList()[1].tags {
//                    XCTAssertEqual(s.string.substring(tags), ":test3:test4:")
//                    isHit = true
//                }
//                
//                XCTAssertTrue(isHit)
//                isHit = false
//                
//                let heading1 = s.heading(at: s.headingList()[1].range.location)!
//                
//                XCTAssertEqual(s.string.substring(heading1.range), "** second heading :test3:test4:")
//                
//                s.toggleContentAction(command: TagCommand(location: s.headingList()[0].range.location, kind: .add("test5")))
//                if let tags = s.headingList()[2].tags {
//                    XCTAssertEqual(s.string.substring(tags), ":test5:")
//                    isHit = true
//                }
//                
//                XCTAssertTrue(isHit)
//                isHit = false
//                
//                s.toggleContentAction(command: TagCommand(location: s.headingList()[0].range.location, kind: .add("test6")))
//                if let tags = s.headingList()[2].tags {
//                    XCTAssertEqual(s.string.substring(tags), ":test5:test6:")
//                    isHit = true
//                }
//                
//                XCTAssertTrue(isHit)
//                
//                let heading2 = s.heading(at: s.headingList()[2].range.location)!
//                
//                XCTAssertEqual(s.string.substring(heading2.range), "*** third heading :test5:test6:")
//                
//                ex.fulfill()
//            }
//        }
//        
//        wait(for: [ex], timeout: 5)
//    }
//    
//    func testRemoveTag() {
//        let text = """
//* first heading :test:
//content in first
//** second heading :tag1:tag2:
//SCHEDULE:[2018-12-11]
//content in second
//*** third heading
//SCHEDULE:[2018-12-11]
//DEADLINE:[2018-12-11]
//content in third
//"""
//        
//        let ex = expectation(description: "test remove tag")
//        createDocumentForTest(text: text) { (document) in
//            
//            guard let document = document else {  XCTAssert(false);return }
//            self.editorContext.request(url: document.fileURL).start {_, s in
//                
//                
//                s.toggleContentAction(command: TagCommand(location: s.headingList()[0].range.location, kind: .remove("test")))
//                
//                XCTAssertEqual("* first heading ", s.string.substring(s.headingList()[0].range))
//                
//                s.toggleContentAction(command: TagCommand(location: s.headingList()[1].range.location, kind: .remove("test")))
//                
//                XCTAssertEqual("** second heading :tag1:", s.string.substring(s.headingList()[1].range))
//                
//                ex.fulfill()
//            }
//            
//        }
//        
//        wait(for: [ex], timeout: 5)
//    }
//}
