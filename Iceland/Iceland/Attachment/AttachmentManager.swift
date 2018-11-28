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
                  type: AttachmentType) {
        self.date = date
        self.key = key
        self.description = description
        self.url = url
        self.type = type
    }
}

public struct AttachmentConstants {
    public static let folder: URL = URL(fileURLWithPath: File.Folder.document("attachment").path)
}

public struct AttachmentManager {
    public init() {
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
    public func insert(content: String, type: Attachment.AttachmentType, description: String) throws -> String {
        let jsonEncoder = JSONEncoder()
        let newKey = self.newKey()
        
        /// 附件信息保存的文件路径
        let jsonURL = URL(fileURLWithPath: newKey + ".json", relativeTo: AttachmentConstants.folder)
        
        /// 附件内容保存的文件路径
        let fileURL = URL(fileURLWithPath: newKey, relativeTo: AttachmentConstants.folder)
        
        let attachment = Attachment(date: Date(),
                                    url: fileURL,
                                    key: newKey,
                                    description: description,
                                    type: type)
        
        jsonEncoder.dateEncodingStrategy = .secondsSince1970
        let encodedAttachment = try jsonEncoder.encode(attachment)
        
        try encodedAttachment.write(to: jsonURL)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return newKey
    }
    
    /// 通过附件的 key 来删除附件
    /// - parameter key: 附件的 key
    public func delete(key: String) throws {
        let jsonURL = URL(fileURLWithPath: key + ".json", relativeTo: AttachmentConstants.folder)
        let fileURL = URL(fileURLWithPath: key, relativeTo: AttachmentConstants.folder)
        
        try FileManager.default.removeItem(at: jsonURL)
        try FileManager.default.removeItem(at: fileURL)
    }
    
    /// 已经添加的文档的附件，直接使用 key 来加载
    public func attachment(with key: String) throws -> Attachment {
        let data = try Data(contentsOf: URL(fileURLWithPath: key + ".json", relativeTo: AttachmentConstants.folder))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(Attachment.self, from: data)
    }
}
