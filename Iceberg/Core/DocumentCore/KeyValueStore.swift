//
//  KeyValueStore.swift
//  Storage
//
//  Created by ian luo on 2018/11/5.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol KeyValueStore {
    func get(key: String) -> Any?
    
    func set(value: Any, key: String, completion: @escaping () -> Void)
    
    func remove(key: String, completion: @escaping () -> Void)
    
    func clear(completion: @escaping () -> Void)
    
    func allKeys() -> [String]
    
    func get<T>(key: String, type: T.Type) -> T?
}

/// 明文存储，不适合保存敏感数据
public enum PlistStoreType {
    case userDefault
    case custom(String)
}

public enum KeyValueStoreType {
    case plist(PlistStoreType)
}

public struct KeyValueStoreFactory {
    public static func store(type: KeyValueStoreType) -> KeyValueStore {
        switch type {
        case let .plist(type):
            return PlistStore(type: type)
        }
    }
}

fileprivate class PlistStore: NSObject, KeyValueStore {
    private var _url: URL?
    private var _store: NSMutableDictionary?
    fileprivate static let storeVersionKey = "version"
    
    public init(type: PlistStoreType) {
        super.init()
        switch type {
        /// 提供一个 key 作为文件名，不要文件后缀，如果文件无法被创建，将使用 standard userDefaults
        case let .custom(fileName):
            self._url = URL.file(directory: URL.keyValueStoreURL, name: fileName, extension: "plist")
            
            self._url?.read(completion: { [weak self] data in
                guard let strongSelf = self else { return }
                
                do {
                    strongSelf._store = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? NSMutableDictionary ?? NSMutableDictionary(dictionary: [PlistStore.storeVersionKey: 1])
                    log.verbose("created key value store with url: \(strongSelf._url!)")
                } catch {
                    log.error(error)
                }
            })
        default: break
        }
        
    }
    
    public func get<T>(key: String, type: T.Type) -> T? {
        return self.get(key: key) as? T
    }

    public func get(key: String) -> Any? {
        if let store = _store {
            return store.object(forKey: key)
        } else {
            return UserDefaults.standard.object(forKey: key)
        }
    }
    
    private func bumpVersionNumber(_ store: NSMutableDictionary, forceVersion: Int? = nil) {
        if let version = store.value(forKey: PlistStore.storeVersionKey) as? Int {
            let newVersion = forceVersion ?? version + 1
            store.setValue(newVersion + 1, forKey: PlistStore.storeVersionKey)
        } else {
            let newVersion = forceVersion ?? 1
            store.setValue(newVersion, forKey: PlistStore.storeVersionKey)
        }
    }
    
    public func set(value: Any, key: String, completion: @escaping () -> Void) {
        if let store = _store, let url = self._url {
            store.setValue(value, forKey: key)
            
            url.deletingLastPathComponent().createDirectoryIfNeeded { error in
                guard error == nil else { log.error(error!); return }
                
                url.writeBlock(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive), accessor: { error in
                    if let error = error {
                        log.error(error)
                    } else {
                        // bump version number
                        self.bumpVersionNumber(store)
                        
                        store.write(to: url, atomically: true)
                        completion()
                    }
                })
            }
        } else {
            let userDefaults = UserDefaults.standard
            userDefaults.set(value, forKey: key)
            userDefaults.synchronize()
        }
    }
    
    public func remove(key: String, completion: @escaping () -> Void) {
        if let store = _store, let url = self._url {
            store.removeObject(forKey: key)
            
            url.writeBlock(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive), accessor: { error in
                if let error = error {
                    log.error(error)
                } else {
                    // bump version number
                    self.bumpVersionNumber(store)
                    
                    store.write(to: url, atomically: true)
                    completion()
                }
            })
        } else {
            let userDefaults = UserDefaults.standard
            userDefaults.removeObject(forKey: key)
            userDefaults.synchronize()
            completion()
        }
    }
    
    public func clear(completion: @escaping () -> Void) {
        if let store = _store, let url = self._url {
            
            url.writeBlock(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)) { error in
                if let error = error {
                    log.error(error)
                } else {
                    store.removeAllObjects()
                    
                    let version = (store.value(forKey: PlistStore.storeVersionKey) as? Int) ?? 0
                    let newVersion = version + 1
                    self.bumpVersionNumber(store, forceVersion: newVersion)
                    
                    store.write(to: url, atomically: true)
                    completion()
                }
            }
        } else {
            UserDefaults.resetStandardUserDefaults()
        }
    }
    
    public func allKeys() -> [String] {
        if let store = _store {
            return store.allKeys as? [String] ?? []
        } else {
            return UserDefaults.standard.dictionaryRepresentation().keys.map {$0}
        }
    }
}

public func mergePlistFiles(name: String, url1: URL, url2: URL) -> URL {
    let plist1 = NSMutableDictionary(contentsOf: url1) ?? NSMutableDictionary()
    let plist2 = NSMutableDictionary(contentsOf: url2) ?? NSMutableDictionary()
    
    for (key, value) in plist2 {
        plist1[key] = value
    }
    
    let mergedFileURL = URL.file(directory: URL.directory(location: URLLocation.temporary), name: name, extension: "plist")
    
    if FileManager.default.fileExists(atPath: mergedFileURL.path) {
        try? FileManager.default.removeItem(at: mergedFileURL)
    }
    
    plist2.write(to: mergedFileURL, atomically: false)
    return mergedFileURL
}
