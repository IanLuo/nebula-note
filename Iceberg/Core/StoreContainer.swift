//
//  StoreContainer.swift
//  Core
//
//  Created by ian luo on 2021/6/26.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation

public class StoreContainer: CustomDebugStringConvertible {
    public enum Store {
        case setting
        case favorite
        case openningFiles
        case ignoredDocumentsInKanban
        case customizedFinishedStatus
        case customizedUnfinishedStatus
        
        public var key: String {
            switch self {
            case .setting: return "Settings"
            case .favorite: return "Favorite"
            case .openningFiles: return "OpeningFiles"
            case .ignoredDocumentsInKanban: return "ignoredEntries"
            case .customizedFinishedStatus: return "customizedFinishedStatus"
            case .customizedUnfinishedStatus: return "customizedUnfinishedStatus"
            }
        }
        
        public var url: URL {
            return URL.file(directory: URL.keyValueStoreURL, name: self.key, extension: "plist")
        }
    }
    
    private static let instance = StoreContainer()
    public static var shared: StoreContainer { return instance }
    
    private let lock = NSLock()
    
    private init() {}

    private var stores: [String: KeyValueStore] = [:]
    
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        
        stores = [:]
    }
    
    public func get(store: Store) -> KeyValueStore {
        if let store = stores[store.key] {
            return store
        } else {
            lock.lock()
            stores[store.key] = KeyValueStoreFactory.store(type: KeyValueStoreType.plist(PlistStoreType.custom(store.key)))
            lock.unlock()
            return get(store: store)
        }
    }
    
    public func storeURL(store: Store) -> URL {
        return store.url
    }
    
    public var debugDescription: String {
        let value = self.stores.map {
            "\($0.value)"
        }.joined(separator: "\n")
        
        return value
    }
}
