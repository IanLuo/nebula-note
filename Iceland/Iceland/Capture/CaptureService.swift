//
//  CaptureService.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIImage
import Storage

public protocol CaptureServiceProtocol {
    func save(content: String,
              type: Attachment.AttachmentType,
              description: String,
              completion: @escaping (Attachment) -> Void,
              failure: @escaping (Error) -> Void)
    func loadAll(completion: ([Attachment]) -> Void, failure: (Error) -> Void)
    func delete(key: String)
    func load(id: String) throws -> Attachment?
}

public struct CaptureService: CaptureServiceProtocol {
    public func load(id: String) throws -> Attachment? {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
        
        if let attachmentKey = plist.get(key: id) as? String {
            return try Attachment.load(with: attachmentKey)
        } else {
            return nil
        }
    }
    
    /// 创建一个新的 attachment, 并添加到 capture 列表中
    public func save(content: String,
                     type: Attachment.AttachmentType,
                     description: String,
                     completion: @escaping (Attachment) -> Void,
                     failure: @escaping (Error) -> Void) {
        Attachment.save(content: content,
                        type: type,
                        description: description,
                        complete: { key in
                            let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
                            plist.set(value: "", key: key) // value 没有用
                            do {
                                let savedAttachment = try Attachment.load(with: key)
                                completion(savedAttachment)
                            } catch {
                                failure(error)
                            }
        }, failure: {
            failure($0)
        })
    }
    
    /// 删除 capture 中的 attachment
    public func delete(key: String) {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
        plist.remove(key: key)
    }
    
    /// 删除 capture 中的 attachment，并且删除磁盘上的 attachment
    public func deleteWithAttachment(key: String) {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
        plist.remove(key: key)
    }
    
    /// 从 capture 中找到对应的 attahcment 并返回
    public func loadAll(completion: ([Attachment]) -> Void, failure: (Error) -> Void) {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
        
        do {
            let attachments = try plist.allKeys().map {
                try Attachment.load(with: $0)
            }
            
            completion(attachments)
        } catch {
            failure(error)
        }
    }
}
