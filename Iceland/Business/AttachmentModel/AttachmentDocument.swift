//
//  AttachmentDocument.swift
//  Business
//
//  Created by ian luo on 2019/3/22.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class AttachmentDocument: UIDocument {
    public static let fileType = "ilattach"
    private static let _jsonFile = "info.json"
    public var fileToSave: URL?
    
    public var attachment: Attachment?
    
    public override func contents(forType typeName: String) throws -> Any {
        guard let attachment = self.attachment else { fatalError("attachment can't be nill") }
        guard let fileToSave = self.fileToSave else { fatalError("no file to save") }
        
        let wrapper = FileWrapper(directoryWithFileWrappers: [:])
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        // change the url of content in to be the one inside attchment wrapper
        let json = try encoder.encode(attachment)
        let jsonWrapper = FileWrapper(regularFileWithContents: json)
        
        jsonWrapper.preferredFilename = AttachmentDocument._jsonFile
        wrapper.addFileWrapper(jsonWrapper)
        
        let dataWrapper = FileWrapper(regularFileWithContents: try Data(contentsOf: fileToSave)) // use the outter file url, and write to wrapper directory
        dataWrapper.preferredFilename = attachment.fileName
        wrapper.addFileWrapper(dataWrapper)
        
        return wrapper
    }
    
    public override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let wrapper = contents as? FileWrapper {
            if let jsonData = wrapper.fileWrappers?[AttachmentDocument._jsonFile]?.regularFileContents {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                self.attachment = try decoder.decode(Attachment.self, from: jsonData)
            }
        }
    }
}
