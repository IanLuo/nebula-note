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
    public static let fileExtension = "ica"
    public static let jsonFile = "info.json"
    public var fileToSave: URL?
    
    public var attachment: Attachment?
    
    public override func contents(forType typeName: String) throws -> Any {
        guard let attachment = self.attachment else { return "".data(using: .utf8)! }
        guard let fileToSave = self.fileToSave else { return "".data(using: .utf8)! }
        
        let wrapper = FileWrapper(directoryWithFileWrappers: [:])
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        do {
            // change the url of content in to be the one inside attchment wrapper
            let json = try encoder.encode(attachment)
            let jsonWrapper = FileWrapper(regularFileWithContents: json)
            
            jsonWrapper.preferredFilename = AttachmentDocument.jsonFile
            wrapper.addFileWrapper(jsonWrapper)
        } catch {
            log.error(error)
            throw error
        }
        
        let dataWrapper = FileWrapper(regularFileWithContents: try Data(contentsOf: fileToSave)) // use the outter file url, and write to wrapper directory
        dataWrapper.preferredFilename = attachment.fileName
        wrapper.addFileWrapper(dataWrapper)
        
        return wrapper
    }
    
    public override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let wrapper = contents as? FileWrapper {
            if let jsonData = wrapper.fileWrappers?[AttachmentDocument.jsonFile]?.regularFileContents {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                
                let keyOnPath = self.fileURL.deletingPathExtension().lastPathComponent
                
                self.attachment = try decoder.decode(Attachment.self, from: jsonData)
                
                if self.attachment?.key != keyOnPath {
                    self.attachment?.key = keyOnPath
                }
            }
        }
    }
    
    public class func createAttachment(url: URL) -> Attachment? {
        let jsonURL = url.appendingPathComponent(AttachmentDocument.jsonFile)
        do {
            var dd: Data?
            jsonURL.read(completion: { d in
                dd = d
            })

            guard let data = dd else { return nil }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            
            let keyOnPath = url.deletingPathExtension().lastPathComponent
            
            var attachment = try decoder.decode(Attachment.self, from: data)
            
            if attachment.key != keyOnPath {
                attachment.key = keyOnPath
            }
            
            return attachment
        } catch {
            log.error(error)
            return nil
        }
    }
    
    public override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
        
        log.error(error)
    }
}
