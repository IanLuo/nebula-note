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
    public enum AttachmentType: String {
        case text, link, image, sketch, audio, video, location
    }
    
    /// 序列化的 key
    private enum CodingKeys: CodingKey {
        case url
        case date
        case type
        case description
        case key
    }
    
    public let date: Date
    
    public let type: Attachment.AttachmentType
    
    public let url: URL
    
    public let description: String
    
    public var key: String
    
    // MARK: - 序列化反序列化
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try Attachment.AttachmentType(rawValue: values.decode(String.self, forKey: .type))!
        date = try values.decode(Date.self, forKey: .date)
        url = try values.decode(URL.self, forKey: .url)
        description = try values.decode(String.self, forKey: .description)
        key = try values.decode(String.self, forKey: .key)
    }
    
    public func encode(to encoder: Encoder) throws {
        var encoder = encoder.container(keyedBy: CodingKeys.self)
        try encoder.encode(type.rawValue, forKey: .type)
        try encoder.encode(url, forKey: .url)
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
    public static func save(content: String, type: Attachment.AttachmentType, description: String) throws -> String {
        let manager = AttachmentManager()
        return try manager.insert(content: content, type: type, description: description)
    }
    
    /// 删除附件
    public func delete(key: String) throws {
        let manager = AttachmentManager()
        try manager.delete(key: key)
    }
    
    /// 通过保存在 attachment.plist 中的 key 来获取对应的 json 字符串
    /// 如果 key 为 sampleKey，对应的 json 字符串保存在 sampleKey.json，位于 capture.plist 同一个目录中
    public static func create(with key: String) throws -> Attachment {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970
        let json = try Data(contentsOf: URL(fileURLWithPath: key + ".json", relativeTo: AttachmentConstants.folder))
        return try jsonDecoder.decode(Attachment.self, from: json)
    }
}
