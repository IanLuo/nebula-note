//
//  AttachmentManager.swift
//  Iceland
//
//  Created by ian luo on 2018/11/5.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Storage

extension Attachment {
    fileprivate init(date: Date,
                  url: URL,
                  key: String,
                  description: String,
                  kind: Kind) {
        self.date = date
        self.key = key
        self.description = description
        self.url = url
        self.kind = kind
    }
}

public enum AttachmentError: Error {
    case failToSaveDocument
    case noSuchFileToSave(String)
}

@objc public class AttachmentManager: NSObject {
    public override init() {
        // 确保附件文件夹存在
        File.Folder.document("attachment").createFolderIfNeeded()
    }
    
    /// 当附件创建的时候，生成附件的 key
    /// 这个 key 是在 attachment.plist 中改附件的字段名，也是附件内容保存在磁盘的文件名
    private func newKey() -> String {
        return UUID().uuidString
    }
    
    /// 保存附件内容到磁盘
    /// - parameter content: 与附件的类型有关，如果是文字，就是附件的内容，如果附件类型是文件，则是文件的路径
    /// - parameter type: 附件的类型
    /// - parameter description: 附件描述
    /// - returns: 保存的附件的 key
    public func insert(content: String,
                       kind: Attachment.Kind,
                       description: String,
                       complete: @escaping (String) throws -> Void,
                       failure: @escaping (Error) -> Void) rethrows {
        let jsonEncoder = JSONEncoder()
        let newKey = self.newKey()
        
        /// 附件信息保存的文件路径
        let jsonURL = URL(fileURLWithPath: newKey + ".json", relativeTo: URL.attachmentURL)
        
        /// 附件内容保存的文件路径
        var fileURL: URL!
        
        // 保存附件信息
        let saveFileInfo = {
            let attachment = Attachment(date: Date(),
                                        url: fileURL,
                                        key: newKey,
                                        description: description,
                                        kind: kind)
            
            jsonEncoder.dateEncodingStrategy = .secondsSince1970
            let encodedAttachment = try jsonEncoder.encode(attachment)
            try encodedAttachment.write(to: jsonURL)
        }
        
        switch kind {
        case .text: fallthrough
        case .location: fallthrough
        case .link:
            fileURL = URL(fileURLWithPath: newKey + ".txt", relativeTo: URL.attachmentURL)
            do {
                try content.write(to: fileURL, atomically: true, encoding: .utf8) // FIXME: 改为 Document 的 save  方法
                try saveFileInfo()
                try complete(newKey)
            } catch {
                failure(error)
            }
        default:
            let url = URL(fileURLWithPath: content)
            fileURL = URL.attachmentURL.appendingPathComponent(newKey).appendingPathExtension(url.pathExtension)
            let document = AttachmentFile(fileURL: url)
            document.save(to: fileURL, for: .forCreating) { result in
                if !result {
                    failure(AttachmentError.failToSaveDocument)
                } else {
                    do {
                        try saveFileInfo()
                        try complete(newKey)
                    } catch {
                        failure(error)
                    }
                }
            }
        }
    }
    
    /// 通过附件的 key 来删除附件
    /// - parameter key: 附件的 key
    public func delete(key: String) throws {
        
        let jsonURL = URL(fileURLWithPath: key + ".json", relativeTo: URL.attachmentURL)
        let fileURL = try attachment(with: key).url
        
        try FileManager.default.removeItem(at: jsonURL)
        try FileManager.default.removeItem(at: fileURL)
    }
    
    /// 已经添加的文档的附件，直接使用 key 来加载
    public func attachment(with key: String) throws -> Attachment {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970
        let json = try Data(contentsOf: URL(fileURLWithPath: key + ".json", relativeTo: URL.attachmentURL))
        return try jsonDecoder.decode(Attachment.self, from: json)
    }
}

public class AttachmentFile: UIDocument {
    public override func contents(forType typeName: String) throws -> Any {
        return try Data(contentsOf: self.fileURL)
    }
}
