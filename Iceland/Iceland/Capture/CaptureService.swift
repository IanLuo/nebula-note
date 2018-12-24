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
import Storage

public protocol CaptureServiceProtocol {
    func save(content: String,
              type: Attachment.AttachmentType,
              description: String) -> Observable<Attachment>
    func loadAll() -> Observable<[Attachment]>
    func delete(key: String) -> Observable<Void>
    func load(id: String) -> Observable<Attachment?>
}

private struct CaptureConstants {
    public static let captureAttachmentListFilePath: URL = URL(string: "")!
}

public struct CaptureService: CaptureServiceProtocol {
    /// 从 capture 列表中获取全部未处理的附件
    public func load(id: String) -> Observable<Attachment?> {
        return Observable<Attachment?>.create { observer in
            let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
            
            do {
                if let attachmentKey = plist.get(key: id) as? String {
                    let attachment = try Attachment.create(with: attachmentKey)
                    observer.onNext(attachment)
                } else {
                    observer.onNext(nil)
                }
                
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    /// 创建一个新的 attachment, 并添加到 capture 列表中
    public func save(content: String,
                     type: Attachment.AttachmentType,
                     description: String) -> Observable<Attachment> {
        return Observable<Attachment>.create { observer in
            Attachment.save(content: content,
                            type: type,
                            description: description,
                            complete: { key in
                                let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
                                plist.set(value: Date(), key: key)
                                
                                do {
                                    let savedAttachment = try Attachment.create(with: key)
                                    observer.onNext(savedAttachment)
                                    observer.onCompleted()
                                } catch {
                                    observer.onError(error)
                                }
            },
                            failure: { error in
                                observer.onError(error)
            })
            
            return Disposables.create()
        }
    }
    
    /// 删除 capture 中的 attachment
    public func delete(key: String) -> Observable<Void> {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
        plist.remove(key: key)
        
        return Observable.just(())
    }
    
    /// 删除 capture 中的 attachment，并且删除磁盘上的 attachment
    public func deleteWithAttachment(key: String) -> Observable<Void> {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
        plist.remove(key: key)
        
        return Observable.create { observer in
            do {
                try AttachmentManager().delete(key: key)
                observer.onNext(())
                observer.onCompleted()
            } catch { observer.onError(error) }
            
            return Disposables.create()
        }
    }
    
    /// 从 capture 中找到对应的 attahcment 并返回
    public func loadAll() -> Observable<[Attachment]> {
        let plist = KeyValueStoreFactory.store(type: .plist(.custom("capture")))
        
        return Observable<[Attachment]>.create { observer in
            do {
                let attachments: [Attachment] = try plist.allKeys().map {
                    try Attachment.create(with: $0)
                }
                
                observer.onNext(attachments)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
}
