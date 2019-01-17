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
import Business

public protocol CaptureServiceProtocol {
    func save(key: String)
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
    public func save(key: String) {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
        plist.set(value: "", key: key) // value 没用
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
