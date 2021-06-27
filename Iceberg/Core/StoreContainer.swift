//
//  StoreContainer.swift
//  Core
//
//  Created by ian luo on 2021/6/26.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation

public class StoreContainer {
    public enum Store {
        case setting
        case favorite
        case openningFiles
        case ignoredDocumentsInKanban
        
        public var key: String {
            switch self {
            case .setting: return "Settings"
            case .favorite: return "Favorite"
            case .openningFiles: return "OpeningFiles"
            case .ignoredDocumentsInKanban: return "ignoredEntries"
            }
        }
        
        public var url: URL {
            return URL.file(directory: URL.keyValueStoreURL, name: self.key, extension: "plist")
        }
    }
    
    private static let instance = StoreContainer()
    public static var shared: StoreContainer { return instance }
    
    private init() {}

    private var stores: [String: KeyValueStore] = [:]
    
    public func reset() {
        stores = [:]
    }
    
    public func get(store: Store) -> KeyValueStore {
        if let store = stores[store.key] {
            return store
        } else {
            stores[store.key] = KeyValueStoreFactory.store(type: KeyValueStoreType.plist(PlistStoreType.custom(store.key)))
            return get(store: store)
        }
    }
    
    public func storeURL(store: Store) -> URL {
        return store.url
    }
}
