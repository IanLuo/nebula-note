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
        try manager.insert(content: "test attachment", type: Attachment.AttachmentType.text, description: "test", complete: { key in
            let saved = try manager.attachment(with: key)
            
            XCTAssertEqual(saved.key, key)
            XCTAssertEqual(saved.description, "test")
            XCTAssertEqual(saved.type, Attachment.AttachmentType.text)
            XCTAssertEqual(try String(contentsOf: saved.url), "test attachment")
            
            ex.fulfill()
        }, failure: { error in
            
        })
        
        let folder = File.Folder.temp("attachment")
        folder.createFolderIfNeeded()
        let tempFile = File(folder, fileName: "audio.wav").url
        
        let data = "the fake audio data".data(using: String.Encoding.utf8)
        try data?.write(to: tempFile)
        
        let ex2 = expectation(description: "audio")
        try manager.insert(content: tempFile.path, type: Attachment.AttachmentType.audio, description: "audio", complete: { key in
            let saved = try manager.attachment(with: key)
            
            XCTAssertEqual(saved.key, key)
            XCTAssertEqual(saved.description, "audio")
            XCTAssertEqual(saved.type, Attachment.AttachmentType.audio)
            XCTAssertEqual(try String(contentsOf: saved.url), "the fake audio data")
            
            ex2.fulfill()
        }, failure: { error in
            print(error)
        })
        
        wait(for: [ex, ex2], timeout: 1)
    }
    
    func testDeleteAttachment() throws {
        let manager = AttachmentManager()
        let ex = expectation(description: "delete")
        try manager.insert(content: "test attachment", type: Attachment.AttachmentType.text, description: "test", complete: { key in
            try manager.delete(key: key)
            XCTAssertThrowsError(try manager.attachment(with: key))
            ex.fulfill()
        }, failure: { error in
            print(error)
        })
        
        wait(for: [ex], timeout: 1)
    }
}
