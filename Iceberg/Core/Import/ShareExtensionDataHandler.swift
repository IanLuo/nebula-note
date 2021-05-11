//
//  ShareExtensionDataHandler.swift
//  Business
//
//  Created by ian luo on 2019/6/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import RxSwift

/// 通过第三发 app 分享
public struct ShareExtensionDataHandler {
    enum IdeaError: Error {
        case dataUnavailable
    }
    
    public init() {}
    
    public var sharedContainterURL: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.x3note.share")!
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
    
    public func createAttachmentFromIdea(attachmentManager: AttachmentManager, url: URL) -> Observable<String?> {
        return Observable.create { observer in
            
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
                    do {
                        try FileManager.default.removeItem(at: url)
                        observer.onNext(key)
                        observer.onCompleted()
                    } catch {
                        observer.onNext(nil)
                        observer.onCompleted()
                    }
                }) { error in
                    log.error(error)
                    observer.onNext(nil)
                    observer.onCompleted()
                }
            } else {
                observer.onNext(nil)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    public func harvestSharedItems(attachmentManager: AttachmentManager, urlHandler: URLHandlerManager, captureService: CaptureService) -> Observable<Int> {
        
        let sharedItem = self.loadAllUnHandledShareIdeas()
        
        guard sharedItem.count > 0 else {
            return Observable.just(0)
        }
        
        return Observable
            .zip(sharedItem.map {
                return self.createAttachmentFromIdea(attachmentManager: attachmentManager, url: $0)
                    .flatMap({ (key: String?) ->  Observable<String?> in
                        if let key = key {
                            return captureService.save(key: key).map { Optional($0) }
                        } else {
                            return Observable<String?>.just(nil)
                        }
                    })
            })
            .map({ $0.filter { $0 != nil } })
            .map { $0.count }
            .observe(on: ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global(qos: .background)))
    }
}
