//
//  CaptureService.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIImage
import RxSwift

public protocol CaptureServiceProtocol {
    func save(key: String, completion: @escaping () -> Void)
    func loadAll(completion: @escaping ([Attachment]) -> Void, failure: @escaping (Error) -> Void)
    func delete(key: String, completion: @escaping () -> Void)
    func load(id: String, completion: @escaping (Attachment) -> Void, failure: @escaping (Error) -> Void)
}

public struct CaptureService: CaptureServiceProtocol {
    public static let plistFileName: String = "capture"
    private let _attachmentManager: AttachmentManager
    
    public init(attachmentManager: AttachmentManager) {
        self._attachmentManager = attachmentManager
    }
    
    public func load(id: String, completion: @escaping (Attachment) -> Void, failure: @escaping (Error) -> Void) {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom(CaptureService.plistFileName)))
        
        if let attachmentKey = plist.get(key: id) as? String {
            self._attachmentManager.attachment(with: attachmentKey, completion: completion, failure: failure)
        } else {
            
        }
    }
    
    /// 创建一个新的 attachment, 并添加到 capture 列表中
    public func save(key: String, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
            let plist = KeyValueStoreFactory.store(type: .plist(.custom(CaptureService.plistFileName)))
            plist.set(value: "", key: key) {
                log.info("successfully add new capture idea for key: \(key)")
                completion()
            } // value 没用
        }
    }
    
    public func save(key: String) -> Observable<String> {
        return Observable.create { observer in
            
            self.save(key: key) {
                observer.onNext(key)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    /// 删除 capture 中的 attachment
    public func delete(key: String, completion: @escaping () -> Void) {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom(CaptureService.plistFileName)))
        log.info("successfully deleted capture idea for key: \(key)")
        plist.remove(key: key, completion: completion)
    }
    
    /// 删除 capture 中的 attachment，并且删除磁盘上的 attachment
    public func deleteWithAttachment(key: String) {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom(CaptureService.plistFileName)))
        plist.remove(key: key) {}
    }
    
    public func loadAllAttachmentNames() -> [String] {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom(CaptureService.plistFileName)))
        return plist.allKeys()
    }
    
    /// 从 capture 中找到对应的 attahcment 并返回
    public func loadAll(completion: @escaping ([Attachment]) -> Void, failure: @escaping (Error) -> Void) {        
        var attachments: [Attachment] = []
        
        
        let group = DispatchGroup()
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            self.loadAllAttachmentNames().forEach {
                group.enter()
                
                if let attachment = self._attachmentManager.attachment(with: $0) {
                    attachments.append(attachment)
                }
                
                group.leave()
            }
            
            group.notify(queue: DispatchQueue.main) {
                completion(attachments)
            }
        }
    }
}
