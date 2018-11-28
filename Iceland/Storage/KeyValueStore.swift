//
//  KeyValueStore.swift
//  Storage
//
//  Created by ian luo on 2018/11/5.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import KeychainAccess

public protocol KeyValueStore {
    func get(key: String) -> Any?
    
    func set(value: Any, key: String)
    
    func remove(key: String)
    
    func clear()
    
    func allKeys() -> [String]
}

public enum KeyValueStoreType {
    case plist(PlistStoreType)
    /// bundleID
    /// group: 如果没有共享 Keychain 的应用组，设为 nil
    case keychain(String, String?)
}

public struct KeyValueStoreFactory {
    public static func store(type: KeyValueStoreType) -> KeyValueStore {
        switch type {
        case let .plist(type):
            return PlistStore(type: type)
        case .keychain(let bundleID, let group):
            return KeychainStore(bundleID: bundleID, group: group)
        }
    }
}

/// 只能保存 String 和 Data 类型数据
fileprivate struct KeychainStore: KeyValueStore {
    let keychain: Keychain
    
    public init(bundleID: String, group: String?) {
        if let group = group {
            keychain = Keychain(service: bundleID, accessGroup: group)
        } else {
            keychain = Keychain(service: bundleID)
        }
    }
    
    public func get(key: String) -> Any? {
        return keychain[key]
    }
    
    public func set(value: Any, key: String) {
        if value is String {
            try? keychain.set((value as? String)!, key: key)
        } else if value is Data {
            try? keychain.set((value as? Data)!, key: key)
        }
    }
    
    public func remove(key: String) {
        keychain[key] = nil
    }
    
    public func clear() {
        keychain.allKeys().forEach {
            try? keychain.remove($0)
        }
    }
    
    public func allKeys() -> [String] {
        return keychain.allKeys()
    }
}

/// 明文存储，不适合保存敏感数据
public enum PlistStoreType {
    case userDefault
    case custom(String)
}

fileprivate struct PlistStore: KeyValueStore {
    
    private var file: File?
    private var store: NSMutableDictionary?
    
    public init(type: PlistStoreType) {
        switch type {
        /// 提供一个 key 作为文件名，不要文件后缀，如果文件无法被创建，将使用 standard userDefaults
        case let .custom(fileName):
            file = File(File.Folder.document("KeyValueStore"), fileName: fileName + ".plist")
            if Settings.isLogEnabled {
                print("key value store path: \(file!.filePath)")
            }
            if Settings.isLogEnabled {
                print(file?.filePath ?? "")
            }
            
            if let filePath = file?.filePath {
                store = NSMutableDictionary(contentsOfFile: filePath) ?? NSMutableDictionary()
            }
            
        default: break
        }
    }
    
    public func get(key: String) -> Any? {
        if let store = store {
            return store.object(forKey: key)
        } else {
            return UserDefaults.standard.object(forKey: key)
        }
    }
    
    public func set(value: Any, key: String) {
        if let store = store, let filePath = file?.filePath {
            file?.folder.createFolderIfNeeded()
            store.setValue(value, forKey: key)
            store.write(toFile: filePath, atomically: true)
        } else {
            let userDefaults = UserDefaults.standard
            userDefaults.set(value, forKey: key)
            userDefaults.synchronize()
        }
    }
    
    public func remove(key: String) {
        if let store = store, let filePath = file?.filePath {
            store.removeObject(forKey: key)
            store.write(toFile: filePath, atomically: true)
        } else {
            let userDefaults = UserDefaults.standard
            userDefaults.removeObject(forKey: key)
            userDefaults.synchronize()
        }
    }
    
    public func clear() {
        if let filePath = file?.filePath {
            try? Foundation.FileManager.default.removeItem(atPath: filePath)
        } else {
            UserDefaults.resetStandardUserDefaults()
        }
    }
    
    public func allKeys() -> [String] {
        if let store = store {
            return store.allKeys as? [String] ?? []
        } else {
            return UserDefaults.standard.dictionaryRepresentation().keys.map {$0}
        }
    }
}
