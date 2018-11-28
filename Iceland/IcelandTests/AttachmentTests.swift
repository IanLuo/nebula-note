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

public class AttachmentTests: XCTestCase {
    
    public override func tearDown() {
        do {
            try FileManager.default.removeItem(at: AttachmentConstants.folder)
        } catch {
            print(error)
        }
    }
    
    func testSaveAttachment() throws {
        let manager = AttachmentManager()
        let key = try manager.insert(content: "test attachment", type: Attachment.AttachmentType.text, description: "test")
        let saved = try manager.attachment(with: key)
        
        XCTAssertEqual(saved.key, key)
        XCTAssertEqual(saved.description, "test")
        XCTAssertEqual(saved.type, Attachment.AttachmentType.text)
        XCTAssertEqual(try String(contentsOf: saved.url), "test attachment")
    }
    
    func testDeleteAttachment() throws {
        let manager = AttachmentManager()
        let key = try manager.insert(content: "test attachment", type: Attachment.AttachmentType.text, description: "test")
        try manager.delete(key: key)
        XCTAssertThrowsError(try manager.attachment(with: key))
    }
}
