//
//  EditServiceFactory.swift
//  Business
//
//  Created by ian luo on 2019/3/1.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public class EditorContext {
    
    public init(eventObserver: EventObserver) {
         self.recentFilesManager = RecentFilesManager(eventObserver: eventObserver)
        self._eventObserver = eventObserver
    }
    
    public let recentFilesManager: RecentFilesManager
    
    private let _eventObserver: EventObserver
    private var _cachedServiceInstances: [URL: EditorService] = [:]
    private let _editingQueue: DispatchQueue = DispatchQueue(label: "editor.doing.editing", qos: DispatchQoS.userInteractive, attributes: [.concurrent])
    
    public func request(url: URL) -> EditorService {
        var url = url.wrapperURL
        
        let ext = url.path.hasSuffix(Document.fileExtension) ? "" : Document.fileExtension
        url = url.appendingPathExtension(ext)
        
        // 打开文件时， 添加到最近使用的文件
        self.recentFilesManager.addRecentFile(url: url, lastLocation: 0) { [weak self] in
            self?._eventObserver.emit(OpenDocumentEvent(url: url))
        }
        
        if let editorInstance = self._cachedServiceInstances[url] {
            return editorInstance
        } else {
            let newService = EditorService(url: url, queue: self._editingQueue, eventObserver: self._eventObserver)
            self._cachedServiceInstances[url] = newService
            return newService
        }
    }
    
    public func closeIfOpen(url: URL, complete: @escaping () -> Void) {
        if let service = self._cachedServiceInstances[url] {
            
            if service.documentState != .closed {
                service.close { _ in
                    self._cachedServiceInstances[url] = nil
                    complete()
                }
            } else {
                complete()
            }
        } else {
            complete()
        }
    }
    
    public func closeIfOpen(dir: URL, complete: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "close files")
        let relatePath = dir.documentRelativePath
        
        queue.async {
            for (url, service) in self._cachedServiceInstances {
                dispatchGroup.enter()
                if url.path.contains(relatePath) {
                    if service.documentState != .closed {
                        DispatchQueue.main.async {
                            service.close { _ in
                                queue.async {
                                    self._cachedServiceInstances[url] = nil
                                    dispatchGroup.leave()
                                }
                            }
                        }
                    } else {
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: queue) {
            complete()
        }
    }
}
