//
//  Attachment.swift
//  Iceland
//
//  Created by ian luo on 2018/11/5.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

/*
 1. 文本
 2. 音频
 3. 照片
 4. 视频
 5. 链接
 6. 涂鸦
 7. 位置
 */

/// 附件对象
public struct Attachment: Codable {
    /// 附件的类型
    public enum Kind: String, CaseIterable {
        case text, link, image, sketch, audio, video, location
    }
    
    /// 序列化的 key
    private enum _CodingKeys: CodingKey {
        case url
        case date
        case kind
        case description
        case key
    }
    
    /// 附件创建的日期
    public let date: Date
    
    /// 附件类型
    public let kind: Attachment.Kind
    
    /// 附件位置
    public let url: URL
    
    /// 附件描述
    public let description: String
    
    /// 附件在描述文件中的 key
    public var key: String
    
    // MARK: - 序列化反序列化
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: _CodingKeys.self)
        kind = try Attachment.Kind(rawValue: values.decode(String.self, forKey: .kind))!
        date = try values.decode(Date.self, forKey: .date)
        
        let fileName = try values.decode(String.self, forKey: .url)
        url = URL.attachmentURL.appendingPathComponent(fileName)
        description = try values.decode(String.self, forKey: .description)
        key = try values.decode(String.self, forKey: .key)
    }
    
    public func encode(to encoder: Encoder) throws {
        var encoder = encoder.container(keyedBy: _CodingKeys.self)
        try encoder.encode(kind.rawValue, forKey: .kind)
        
        let relativeFileURL = url.lastPathComponent // 只保存文件名的部分，文件的位置在同步之后会改变
        try encoder.encode(relativeFileURL, forKey: .url)
        try encoder.encode(date, forKey: .date)
        try encoder.encode(description, forKey: .description)
        try encoder.encode(key, forKey: .key)
    }
}

extension Attachment {
    /// 保存附件
    /// - Parameter content:
    /// 序列化后的附件 json
    /// - Parameter type
    /// 附件类型
    /// - Parameter description
    /// 附件描述
    public static func save(content: String,
                            kind: Attachment.Kind,
                            description: String,
                            complete: @escaping (String) -> Void,
                            failure: @escaping (Error) -> Void) {
        let manager = AttachmentManager()
        manager.insert(content: content,
                                  kind: kind,
                                  description: description,
                                  complete: complete,
                                  failure: failure)
    }
    
    /// 删除附件
    public func delete(key: String) throws {
        let manager = AttachmentManager()
        try manager.delete(key: key)
    }
    
    /// 通过保存在 key 加载附件
    /// 对于 capture 来说，如果 key 为 sampleKey，对应的 json 字符串保存在 sampleKey.json，位于 capture.plist 同一个目录中
    public static func load(with key: String) throws -> Attachment {
        let manager = AttachmentManager()
        return try manager.attachment(with: key)
    }
    
    public func delete() throws {
        let manager = AttachmentManager()
        try manager.delete(key: self.key)
    }
}
