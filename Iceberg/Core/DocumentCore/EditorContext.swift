//
//  EditServiceFactory.swift
//  Business
//
//  Created by ian luo on 2019/3/1.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public class EditorContext {
    
    public init(eventObserver: EventObserver, settingsAccessor: SettingsAccessor) {
        self._eventObserver = eventObserver
        self._settingsAccessor = settingsAccessor
    }
    
    private let _eventObserver: EventObserver
    private let _settingsAccessor: SettingsAccessor
    private static var _cachedServiceInstances: [String: EditorService] = [:]
    public let _editingQueue: DispatchQueue = DispatchQueue(label: "editor.doing.editing", qos: DispatchQoS.userInteractive)
    
    public func reloadParser() {
        OutlineParser.Matcher.reloadPlanning()
    }
    
    public func requestTemp(url: URL) -> EditorService {
        return EditorService(url: url, queue: self._editingQueue, eventObserver: self._eventObserver, parser: OutlineParser(), isTemp: true, settingsAccessor: self._settingsAccessor)
    }
    
    public func request(url: URL) -> EditorService {
        log.info("requesing editor service with url: \(url)")
        var url = url.wrapperURL
        
        let ext = url.path.hasSuffix(Document.fileExtension) ? "" : Document.fileExtension
        url = url.appendingPathExtension(ext)
                
        return self._getCachedService(with: url)
    }
    
    /// remove the editor service with specifiled url from cache
    public func end(with url: URL) {
        self._removeCachedService(with: url)
    }
    
    private func _getCachedService(with url: URL) -> EditorService {
        if let editorInstance = _tryGetCachedService(with: url) {
            log.info("load editor service from cache: \(url)")
            return editorInstance
        } else {
            log.info("no editor service found in cache, creating a new one")
            return _createAndCacheNewService(with: url)
        }
    }
    
    private func _tryGetCachedService(with url: URL) -> EditorService? {
        let cacheKey = url.documentRelativePath
        log.info("trying to get editor service from cache with key: \(cacheKey)")
        return EditorContext._cachedServiceInstances[cacheKey]
    }
    
    private func _removeCachedService(with url: URL) {
        let cacheKey = url.documentRelativePath
        EditorContext._cachedServiceInstances[cacheKey] = nil
    }
    
    private func _createAndCacheNewService(with url: URL) -> EditorService {
        let cacheKey = url.documentRelativePath
        let newService = EditorService(url: url, queue: self._editingQueue, eventObserver: self._eventObserver, parser: OutlineParser(), settingsAccessor: self._settingsAccessor)
        EditorContext._cachedServiceInstances[cacheKey] = newService
        log.info("created new editor service with url: \(url), and saved with cache key: \(cacheKey)")
        return newService
    }
    
    public func closeIfOpen(url: URL, complete: @escaping () -> Void) {
        if let service = self._tryGetCachedService(with: url) {
            
            if service.documentState != .closed {
                service.close { _ in
                    self._removeCachedService(with: url)
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
            for (key, service) in EditorContext._cachedServiceInstances {
                dispatchGroup.enter()
                if key.contains(relatePath) {
                    if service.documentState != .closed {
                        DispatchQueue.runOnMainQueueSafely {
                            service.close { _ in
                                queue.async {
                                    self._removeCachedService(with: service.fileURL)
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
