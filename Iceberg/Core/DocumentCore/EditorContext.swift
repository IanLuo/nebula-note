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
    
    private let _cacheLock: NSLock = NSLock()
    private static var _cachedServiceInstances: [String: EditorService] = [:]
    public let _editingQueue: DispatchQueue = DispatchQueue(label: "editor context", qos: .userInteractive, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    
    private let _serviceReferenceCounter: ReferenceCounter = ReferenceCounter()
    
    // reload if constants changes
    public func reloadParser() {
        OutlineParser.Matcher.reloadPlanning()
    }
    
//    public func requestTemp(url: URL) -> EditorService {
//        return EditorService(url: url, queue: self._editingQueue, eventObserver: self._eventObserver, parser: OutlineParser(), isTemp: true, settingsAccessor: self._settingsAccessor)
//    }
    
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

            // if load from cache successfully, add cache reference count
            self._serviceReferenceCounter.increase(url: url)

            return editorInstance
        } else {
            log.info("no editor service found in cache, creating a new one")
            
            // if load from cache successfully, add cache reference count
            self._serviceReferenceCounter.increase(url: url)
            
            return _createAndCacheNewService(with: url)
        }
    }
    
    private func _tryGetCachedService(with url: URL) -> EditorService? {
        let cacheKey = url.documentRelativePath
        log.info("trying to get editor service from cache with key: \(cacheKey)")
        return EditorContext._cachedServiceInstances[cacheKey]
    }
    
    private func _removeCachedService(with url: URL) {
        
        defer {
            self._cacheLock.unlock()
        }
        
        self._cacheLock.lock()
        
        self._serviceReferenceCounter.decrease(url: url)
        
        if self._serviceReferenceCounter.checkCount(url: url) == 0 {
            let cacheKey = url.documentRelativePath
            
            if let service = EditorContext._cachedServiceInstances[cacheKey] {
                if service.isOpen {
                    service.close()
                }
                EditorContext._cachedServiceInstances[cacheKey] = nil
            } else {
                EditorContext._cachedServiceInstances[cacheKey] = nil
            }
        }
    }
    
    private func _createAndCacheNewService(with url: URL) -> EditorService {
        defer {
            self._cacheLock.unlock()
        }
        
        self._cacheLock.lock()
        
        let cacheKey = url.documentRelativePath
        let newService = EditorService(url: url, queue: self._editingQueue, eventObserver: self._eventObserver, parser: OutlineParser(), settingsAccessor: self._settingsAccessor)
        EditorContext._cachedServiceInstances[cacheKey] = newService
        log.info("created new editor service with url: \(url), and saved with cache key: \(cacheKey)")
        return newService
    }
    
    public func closeIfOpen(url: URL, complete: @escaping () -> Void) {
        self._removeCachedService(with: url)
        complete()
    }
    
    public func closeIfOpen(dir: URL, complete: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "close files")
        let relatePath = dir.documentRelativePath
        
        queue.async {
            for (key, service) in EditorContext._cachedServiceInstances {
                dispatchGroup.enter()
                if key.contains(relatePath) {
                    DispatchQueue.runOnMainQueueSafely {
                        self._removeCachedService(with: service.fileURL)
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
    
    private class ReferenceCounter {
        let cacheKey: (URL) -> String = { $0.documentRelativePath }
        var countMap: [String: Int] = [:]
        
        private let _lock = NSLock()
        
        func checkCount(url: URL) -> Int {
            return self.countMap[cacheKey(url)] ?? 0
        }
        
        func increase(url: URL) {
            defer {
                _lock.unlock()
            }
            
            _lock.lock()
            
            if let count = self.countMap[cacheKey(url)] {
                self.countMap[cacheKey(url)] = count + 1
            } else {
                self.countMap[cacheKey(url)] = 1
            }
        }
        
        func decrease(url: URL) {
            defer {
                _lock.unlock()
            }
            
            _lock.lock()
            
            if let count = self.countMap[cacheKey(url)] {
                let newCount = count - 1
                
                if newCount > 0 {
                    self.countMap[cacheKey(url)] = newCount
                } else {
                    self.countMap[cacheKey(url)] = nil
                }
            }
        }
    }
}
