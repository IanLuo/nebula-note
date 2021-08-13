//
//  AttachmentManager.swift
//  Iceland
//
//  Created by ian luo on 2018/11/5.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import RxSwift

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
//        URL.attachmentURL.createDirectoryIfNeeded(completion: nil)
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
        let fileURL: URL = URL.attachmentURL.appendingPathComponent(newKey).appendingPathExtension(AttachmentDocument.fileExtension)

        let saveAttahmentAction: (URL) -> Void = { attachmentURL in
            let attachment = Attachment(date: Date(),
                                        fileName: attachmentURL.lastPathComponent,
                                        key: newKey,
                                        description: description,
                                        kind: kind)
            
            let attachmentDocument = AttachmentDocument(fileURL: fileURL)
            attachmentDocument.attachment = attachment
            attachmentDocument.fileToSave = attachmentURL
            
            URL.attachmentURL.createDirectoryIfNeeded { error in
                if let error = error {
                    log.error(error)
                } else {
                    attachmentDocument.save(to: fileURL, for: UIDocument.SaveOperation.forCreating) { [attachmentDocument] result in
                        attachmentDocument.close(completionHandler: { result in
                            log.info("successfully insert new attachment key: \(newKey), url: \(fileURL)")
                            DispatchQueue.runOnMainQueueSafely {
                                if result {
                                    complete(newKey)
                                } else {
                                    log.error("failed to insert new attachment key: \(newKey), url: \(fileURL)")
                                    failure(AttachmentError.failToSaveAttachment)
                                }
                            }
                        })
                    }
                }
            }
        }
        
        switch kind {
        case .link: fallthrough
        case .location: fallthrough
        case .text:
            let tempFile = URL.file(directory: URL.directory(location: URLLocation.temporary), name: "attachments", extension: "txt")
            tempFile.write(queue: DispatchQueue.main, data: content.data(using: .utf8) ?? Data()) { _ in
                saveAttahmentAction(tempFile)
            }
        default:
            if let url = URL(string: content) {
                saveAttahmentAction(URL(fileURLWithPath: url.path))
            } else {
                let url = URL(fileURLWithPath: content)
                if FileManager.default.fileExists(atPath: url.path) {
                    saveAttahmentAction(URL(fileURLWithPath: url.path))
                } else {
                    log.error("fail to create url \(content)")
                    fatalError()
                }
            }
        }
    }
    
    public static func textAttachmentURL(with key: String) -> URL {
        return URL(fileURLWithPath: key + "." + AttachmentDocument.fileExtension, relativeTo: URL.attachmentURL).appendingPathComponent("attachments").appendingPathExtension("txt")
    }
    
    /// 通过附件的 key 来删除附件
    /// - parameter key: 附件的 key
    public func delete(key: String, completion: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let url = AttachmentManager.wrappterURL(key: key.unescaped)
        url.delete(queue: DispatchQueue.global(qos: .utility), completion: { [url] error in
            if let error = error {
                failure(error)
            } else {
                log.info("deleted attachment with key: \(key), url: \(url)")
                completion()
            }
        })
    }
    
    public func delete(keys: [String], completion: @escaping ([String]) -> Void, failure: @escaping (Error) -> Void) {
        var performDeleteAttachmentAction: (([String]) -> Void)!
        var deletedKeys: [String] = []
        
        performDeleteAttachmentAction = { keys in
            var keys = keys
            if let first = keys.first {
                keys.remove(at: 0)
                
                self.delete(key: first, completion: {
                    deletedKeys.append(first)
                    performDeleteAttachmentAction(keys)
                }) { error in
                    log.error(error)
                    performDeleteAttachmentAction(keys)
                }
            } else {
                completion(deletedKeys)
            }
        }
        
        if keys.count > 0 {
            DispatchQueue.global(qos: .userInitiated).async {
                performDeleteAttachmentAction(keys)
            }
        } else {
            completion(deletedKeys)
        }
    }
    
    public static func attachmentFileURL(key: String) -> URL? {
        let wrapperName = AttachmentManager.wrappterURL(key: key.unescaped)
        let jsonFileURL = wrapperName.appendingPathComponent(AttachmentDocument.jsonFile)
        
        do {
            let json = try JSONSerialization.jsonObject(with: Data(contentsOf: jsonFileURL), options: []) as? [String: Any]
            if let fileName = json?["fileName"] as? String {
                return wrapperName.appendingPathComponent(fileName)
            } else {
                return nil
            }
        } catch {
            log.error(error)
            return nil
        }
    }
    
    /// 已经添加的文档的附件，直接使用 key 来加载
    public func attachment(with key: String, completion: @escaping (Attachment) -> Void, failure: @escaping (Error) -> Void) {
        
        let url = AttachmentManager.wrappterURL(key: key.unescaped)
        var isDir = ObjCBool(true)
        
        guard FileManager.default.fileExists(atPath: url.path.unescaped, isDirectory: &isDir) == true else {
            failure(AttachmentError.noSuchAttachment(key))
            return
        }
        
        let document = AttachmentDocument(fileURL: url)
        
        let getContentAndCloseDocument: (AttachmentDocument?) -> Void = { document in
            if let attachment = document?.attachment {
                document?.close(completionHandler: { completed in
                    if completed {
                        log.info("loaded attachment with key: \(key), url: \(url)")
                        completion(attachment)
                    } else {
                        log.error("failed to load attachment with key: \(key), url: \(url), fail to close file")
                        failure(AttachmentError.failToCloseDocument(attachment.wrapperURL.path))
                    }
                })
            } else {
                log.error("failed to load attachment with key: \(key), url: \(url), fail to open file")
                failure(AttachmentError.failToOpenAttachment)
            }
        }
        
        if document.documentState != .normal {
            document.open { [weak document] in
                if $0 {
                    getContentAndCloseDocument(document)
                } else {
                    failure(AttachmentError.failToOpenAttachment)
                }
            }
        } else {
            getContentAndCloseDocument(document)
        }
    }
    
    public func attachment(with key: String) -> Attachment? {
        return AttachmentDocument.createAttachment(url: AttachmentManager.wrappterURL(key: key.unescaped))
    }
    
//    public func scanUnusedAttachments() {
//        let searchManager = DocumentSearchManager()
//        let captureService = CaptureService(attachmentManager: self)
//        
//        var unReferencedAttachments: [URL] = []
//        
//        let dipatchGroup = DispatchGroup()
//        
//        var flag = 0
//        let queue = DispatchQueue(label: "", qos: DispatchQoS.background)
//        for url in self.allAttachments {
//            dipatchGroup.enter()
//            flag += 1
//            queue.async {
//                if self.isAttachmentInCaptureList(url: url, captureService: captureService) {
//                    dipatchGroup.leave()
//                    flag -= 1
//                } else {
//                    self.findReference(for: url, documentSearchManager: searchManager) { refs in
//                        if let refs = refs, refs.count == 0 {
//                            unReferencedAttachments.append(url)
//                        }
//                        dipatchGroup.leave()
//                        flag -= 1
//                    }
//                }
//            }
//        }
//        
//        dipatchGroup.notify(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background)) {
//            log.info("found \(unReferencedAttachments.count) attachments that is not used at any place: \n \(unReferencedAttachments)")
//            
//            for url in unReferencedAttachments {
//                do {
//                    try FileManager.default.removeItem(at: url)
//                } catch {
//                    log.error("fail to delete attachment when clearing un-referenced attachment: \(url)")
//                }
//            }
//        }
//        
//    }
    
    public func isAttachmentInCaptureList(url: URL, captureService: CaptureService) -> Bool {
        let name = url.deletingPathExtension().lastPathComponent
        
        return captureService.loadAllAttachmentNames().contains(where: { $0 == name })
    }
    
    public func findReference(for attachment: URL, documentSearchManager: DocumentSearchManager, completion: @escaping ([URL]?) -> Void) {
        let name = attachment.deletingPathExtension().lastPathComponent
        
        documentSearchManager.search(contain: name, cancelOthers: false, completion: { results in
            let urls = results.map { $0.documentInfo.url }
            completion(urls)
        }) { error in
            log.error(error)
            completion(nil)
        }
    }
    
    public var allAttachments: [URL] {
        var attachments: [URL] = []
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        let enumerator = FileManager.default.enumerator(at: URL.attachmentURL, includingPropertiesForKeys: nil, options: options, errorHandler: nil)
        
        while let url = enumerator?.nextObject() as? URL {
            if url.pathExtension == AttachmentDocument.fileExtension {
                enumerator?.skipDescendants()
                attachments.append(url)
            }
        }
        
        return attachments
    }
    
    public static func wrappterURL(key: String) -> URL {
        return URL.attachmentURL.appendingPathComponent(key).appendingPathExtension(AttachmentDocument.fileExtension)
    }
    
    public var allAttachmentsKeys: [String] {
        self.allAttachments.map {
            $0.deletingPathExtension().lastPathComponent
        }
    }
}

