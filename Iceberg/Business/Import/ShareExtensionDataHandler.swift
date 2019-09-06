//
//  ShareExtensionDataHandler.swift
//  Business
//
//  Created by ian luo on 2019/6/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

/// 通过第三发 app 分享
public struct ShareExtensionDataHandler {
    public init() {}
    
    public var sharedContainterURL: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.iceberg.share")!
    }
    
    public func clearAllSharedIdeas() {
        let fileManager = FileManager.default
        do {
            for url in self.loadAllUnHandledShareIdeas() {
                try fileManager.removeItem(at: url)
            }
        } catch {
            log.error(error)
        }
    }
    
    public func loadAllUnHandledShareIdeas() -> [URL] {
        do {
            return try FileManager.default.contentsOfDirectory(at: self.sharedContainterURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
        } catch {
            log.error(error)
            return []
        }
    }
    
    public func harvestSharedItems(attachmentManager: AttachmentManager, urlHandler: URLHandlerManager, captureService: CaptureService, completion: @escaping (Int) -> Void) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            let sharedItem = self.loadAllUnHandledShareIdeas()
            
            let completeHandleSharedItems: () -> Void = {
                self.clearAllSharedIdeas()
                completion(sharedItem.count)
            }
            
            var handleSaveItem: (([URL]) -> Void)!
            handleSaveItem = { urls in
                guard let url = urls.first else {
                    completeHandleSharedItems()
                    return
                }
                
                let remains: [URL] = Array(urls.dropFirst())
                
                let attachmentKindString = url.deletingPathExtension().pathExtension // kind 已经在保存的时候，添加成为了 url 的前一个 ext
                if let kind = Attachment.Kind(rawValue: attachmentKindString) {
                    var content = url.path
                    switch kind {
                    case .text: fallthrough
                    case .link: fallthrough
                    case .location:
                    content = try! String(contentsOf: url) // if the shared type is location, read the content of the file and insert it, otherwise, use the url as content
                    default: break
                    }
                    
                    attachmentManager.insert(content: content, kind: kind, description: "shared idea", complete: { key in
                        captureService.save(key: key, completion: {
                            handleSaveItem(remains)
                        })
                    }) { error in
                        log.error(error)
                        handleSaveItem(remains)
                    }
                } else { //  if the url is not an attachment, try handle it use url scheme handler
                    _ = urlHandler.handle(url: url, sourceApp: "")
                    handleSaveItem(remains)
                }
            }
                        
            handleSaveItem(sharedItem)
        }
    }
}
