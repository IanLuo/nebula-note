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
    func save(key: String, completion: @escaping () -> Void)
    func loadAll(completion: @escaping ([Attachment]) -> Void, failure: @escaping (Error) -> Void)
    func delete(key: String)
    func load(id: String, completion: @escaping (Attachment) -> Void, failure: @escaping (Error) -> Void)
}

public struct CaptureService: CaptureServiceProtocol {
    private let _attachmentManager: AttachmentManager
    
    public init(attachmentManager: AttachmentManager) {
        self._attachmentManager = attachmentManager
    }
    
    public func load(id: String, completion: @escaping (Attachment) -> Void, failure: @escaping (Error) -> Void) {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
        
        if let attachmentKey = plist.get(key: id) as? String {
            self._attachmentManager.attachment(with: attachmentKey, completion: completion, failure: failure)
        } else {
            
        }
    }
    
    /// 创建一个新的 attachment, 并添加到 capture 列表中
    public func save(key: String, completion: @escaping () -> Void) {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
        plist.set(value: "", key: key) {
            completion()
        } // value 没用
    }
    
    /// 删除 capture 中的 attachment
    public func delete(key: String) {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
        plist.remove(key: key) {}
    }
    
    /// 删除 capture 中的 attachment，并且删除磁盘上的 attachment
    public func deleteWithAttachment(key: String) {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
        plist.remove(key: key) {}
    }
    
    /// 从 capture 中找到对应的 attahcment 并返回
    public func loadAll(completion: @escaping ([Attachment]) -> Void, failure: @escaping (Error) -> Void) {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
        
        var attachments: [Attachment] = []
        plist.allKeys().forEach {
            self._attachmentManager.attachment(with: $0, completion: {
                attachments.append($0)
            }, failure: { (error) in
                failure(error)
            })
        }
        
        completion(attachments)
    }
}
