//
//  AttachmentTests.swift
//  IcelandTests
//
//  Created by ian luo on 2018/11/24.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
@testable import Iceland
import XCTest
import Storage
import Business

public class AttachmentTests: XCTestCase {
    
    public override func tearDown() {
        do {
            try FileManager.default.removeItem(at: URL.attachmentURL)
        } catch {
            print(error)
        }
    }
    
    func testSaveAttachment() throws {
        let manager = AttachmentManager()
        
        let ex = expectation(description: "save")
        manager.insert(content: "test attachment", kind: Attachment.Kind.text, description: "test", complete: { key in
            
            manager.attachment(with: key, completion: { saved in
                
                XCTAssertEqual(saved.key, key)
                XCTAssertEqual(saved.description, "test")
                XCTAssertEqual(saved.kind, Attachment.Kind.text)
                XCTAssertEqual(try? String(contentsOf: saved.url), "test attachment")
                
                ex.fulfill()
            }, failure: { error in
                print(error)
                XCTAssert(false)
            })
        }, failure: { error in
            print(error)
            XCTAssert(false)
        })
        
        let folder = File.Folder.temp("attachment")
        folder.createFolderIfNeeded()
        let tempFile = File(folder, fileName: "audio.wav").url
        
        let data = "the fake audio data".data(using: String.Encoding.utf8)
        try data?.write(to: tempFile)
        
        let ex2 = expectation(description: "audio")
        manager.insert(content: tempFile.path, kind: Attachment.Kind.audio, description: "audio", complete: { key in
            manager.attachment(with: key, completion: { saved in
                
                XCTAssertEqual(saved.key, key)
                XCTAssertEqual(saved.description, "audio")
                XCTAssertEqual(saved.kind, Attachment.Kind.audio)
                XCTAssertEqual(try? String(contentsOf: saved.url), "the fake audio data")
                
                ex2.fulfill()
            }, failure: { error in
                print(error)
                XCTAssert(false)
            })
            
        }, failure: { error in
            print(error)
            XCTAssert(false)
        })
        
        wait(for: [ex, ex2], timeout: 1)
    }
    
    func testDeleteAttachment() throws {
        let manager = AttachmentManager()
        let ex = expectation(description: "delete")
        manager.insert(content: "test attachment", kind: Attachment.Kind.text, description: "test", complete: { key in
            manager.delete(key: key, completion: {
                manager.attachment(with: key, completion: { (_) in
                    XCTAssert(false)
                }, failure: { error in
                    print(error)
                    ex.fulfill()
                })
            }, failure: { error in
                print(error)
                XCTAssert(false)
            })
        }, failure: { error in
            print(error)
            XCTAssert(false)
        })
        
        wait(for: [ex], timeout: 2)
    }
}
