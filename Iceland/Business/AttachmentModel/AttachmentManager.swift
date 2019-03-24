//
//  AttachmentManager.swift
//  Iceland
//
//  Created by ian luo on 2018/11/5.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Storage

public enum AttachmentError: Error {
    case noSuchAttachment(String)
    case failToSaveAttachment
    case failToOpenAttachment
    case failToCloseDocument(String)
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
                       complete: @escaping (String) -> Void,
                       failure: @escaping (Error) -> Void) {
        
        let newKey = self.newKey()
        
        let fileURL: URL = URL(fileURLWithPath: newKey + "." + AttachmentDocument.fileType, relativeTo: URL.attachmentURL)
        
        var attachmentURL: URL!
        if let url = URL(string: content) {
            attachmentURL = URL(fileURLWithPath: url.path)
        } else {
            let tempURL = File.init(File.Folder.temp("attachment"), fileName: "\(UUID().uuidString).txt", createFolderIfNeeded: true).url
            do {
                try content.write(to: tempURL, atomically: true, encoding: .utf8)
                attachmentURL = tempURL
            } catch {
                failure(error)
            }
        }
        
        let attachment = Attachment(date: Date(),
                                    fileName: attachmentURL.lastPathComponent,
                                    key: newKey,
                                    description: description,
                                    kind: kind)
        
        let attachmentDocument = AttachmentDocument(fileURL: fileURL)
        attachmentDocument.attachment = attachment
        attachmentDocument.fileToSave = attachmentURL
        attachmentDocument.save(to: fileURL, for: UIDocument.SaveOperation.forCreating) {
            if $0 {
                complete(newKey)
            } else {
                failure(AttachmentError.failToSaveAttachment)
            }
        }
    }
    
    /// 通过附件的 key 来删除附件
    /// - parameter key: 附件的 key
    public func delete(key: String, completion: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        
        self.attachment(with: key, completion: { attachment in
            attachment.wrapperURL.delete(completion: { error in
                if let error = error {
                    failure(error)
                } else {
                    completion()
                }
            })
        }, failure: failure)
    }
    
    /// 已经添加的文档的附件，直接使用 key 来加载
    public func attachment(with key: String, completion: @escaping (Attachment) -> Void, failure: @escaping (Error) -> Void) {
        
        let url = AttachmentManager.wrappterURL(key: key)
        var isDir = ObjCBool(true)
        
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) == true else {
            failure(AttachmentError.noSuchAttachment(key))
            return
        }
        
        let document = AttachmentDocument(fileURL: url)
        
        document.open {
            if $0 {
                if let attachment = document.attachment {
                    document.close(completionHandler: { completed in
                        if completed {
                            completion(attachment)
                        } else {
                            failure(AttachmentError.failToCloseDocument(attachment.wrapperURL.path))
                        }
                    })
                } else {
                    failure(AttachmentError.failToOpenAttachment)
                }
            } else {
                failure(AttachmentError.failToOpenAttachment)
            }
        }
    }
    
    public static func wrappterURL(key: String) -> URL {
        return URL.attachmentURL.appendingPathComponent(key).appendingPathExtension(AttachmentDocument.fileType)
    }
}

