//
//  SettingsAccessor.swift
//  Iceland
//
//  Created by ian luo on 2018/12/15.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Interface

public enum SettingsError: Error {
    case  removePlanningFailed(String)
}

/// used to fetch settings values
@objc public class SettingsAccessor: NSObject {
    public enum InterfaceStyle: String, CaseIterable {
        case dark
        case light
        case auto
    }
    
    private struct Constants {
        static var store: KeyValueStore { return KeyValueStoreFactory.store(type: KeyValueStoreType.plist(PlistStoreType.custom("Settings"))) }
        static let storeURL: URL = URL.file(directory: URL.keyValueStoreURL, name: "Settings", extension: "plist")
    }
    
    public enum Item: String {
        case finishedPlannings
        case unfinishedPlannings
        case landingTabIndex
        case interfaceStyle
        case foldAllEntriesWhenOpen
        case exportShowIndex
        case currentSubscription
        case isFirstLaunchApp
        case didShowUserGuide
        case openedDocuments
        
        public func set(_ value: Any, completion: @escaping () -> Void) {
            Constants.store.set(value: value, key: self.rawValue, completion: completion)
        }
        
        public func get<T>(_ t: T.Type) -> T? {
            return Constants.store.get(key: self.rawValue, type: T.self)
        }
    }
    
    private static let instance = SettingsAccessor()
    private override init() {
        super.init()
        NSFileCoordinator.addFilePresenter(self)
    }
    @objc public static var shared: SettingsAccessor { return instance }
    
    public var customizedPlannings: [String]? {
        switch (self.customizedFinishedPlannings, self.customizedUnfinishedPlannings) {
        case let (lhs?, rhs?):
            return lhs + rhs
        case let (lhs?, nil):
            return lhs
        case let (nil, rhs):
            return rhs
        }
    }
    
    @objc public var lineHeight: CGFloat {
        return InterfaceTheme.Font.body.xHeight
    }
    
    public var maxLevel: Int {
        return 6
    }
    
    public var priorities: [String] {
        return OutlineParser.Values.Heading.Priority.all
    }
    
    public func logOpenDocument(url: URL) {
        if var paths = Item.openedDocuments.get([String].self) {
            paths.append(url.documentRelativePath)
            paths = Array(Set(paths))
            Item.openedDocuments.set(paths, completion: {})
        } else {
            Item.openedDocuments.set([url.documentRelativePath], completion: {})
        }
    }
    
    public func logCloseDocument(url: URL) {
        if var paths = Item.openedDocuments.get([String].self) {
            paths.removeAll { p -> Bool in
                p == url.documentRelativePath
            }
            Item.openedDocuments.set(paths, completion: {})
        }
    }
    
    public var openedDocuments: [URL]? {
        return Item.openedDocuments.get([String].self)?.map {
            URL.documentBaseURL.appendingPathComponent($0)
        }
    }
    
    public var interfaceStyle: InterfaceStyle {
        // 支持 dark mode 的系统，默认值为自动，否则为 light
        if #available(iOS 13, *) {
            return InterfaceStyle(rawValue: SettingsAccessor.Item.interfaceStyle.get(String.self) ?? InterfaceStyle.auto.rawValue) ?? InterfaceStyle.auto
        } else {
            return InterfaceStyle(rawValue: SettingsAccessor.Item.interfaceStyle.get(String.self) ?? InterfaceStyle.light.rawValue) ?? InterfaceStyle.light
        }
    }
    
    public var customizedUnfinishedPlannings: [String]? {
        if let plannings = SettingsAccessor.Item.unfinishedPlannings.get([String].self) {
            return plannings.count > 0 ? plannings : nil
        } else {
            return nil
        }
    }
    
    public var customizedFinishedPlannings: [String]? {
        if let plannings = SettingsAccessor.Item.finishedPlannings.get([String].self) {
            return plannings.count > 0 ? plannings : nil
        } else {
            return nil
        }
    }
    
    public var unfinishedPlanning: [String] {
        return (customizedUnfinishedPlannings ?? []) + [OutlineParser.Values.Heading.Planning.todo]
    }
    
    public var finishedPlanning: [String] {
        return (customizedFinishedPlannings ?? []) + [OutlineParser.Values.Heading.Planning.canceled, OutlineParser.Values.Heading.Planning.done]
    }
    
    public var allPlannings: [String] {
        return unfinishedPlanning + finishedPlanning
    }
    
    public var defaultPlannings: [String] {
        return [OutlineParser.Values.Heading.Planning.todo, OutlineParser.Values.Heading.Planning.canceled,
                OutlineParser.Values.Heading.Planning.done]
    }
    
    /// add new planning
    public func addPlanning(_ planning: String, isForFinished: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        let item = isForFinished ? SettingsAccessor.Item.finishedPlannings : SettingsAccessor.Item.unfinishedPlannings
        if var plannings = item.get([String].self) {
            plannings.append(planning)
            item.set(plannings) {
                completion(.success(()))
            }
        } else {
            item.set([planning]) {
                completion(.success(()))
            }
        }
    }
    
    /// remove specified planning if there's on in the setting's configuration
    public func removePlanning(_ planning: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let removePlanningAction: (SettingsAccessor.Item) -> Bool = { item in
            if var plannings = item.get([String].self) {
                for (index, p) in plannings.enumerated() {
                    if p == planning {
                        plannings.remove(at: index)
                        item.set(plannings) {
                            completion(.success(()))
                        }
                        return true // planning found and removed, return true, so there's no need for another remove action for another planning list
                    }
                }
            } else {
                completion(.failure(SettingsError.removePlanningFailed("no planning found")))
            }
            
            return false
        }
        
        if !removePlanningAction(SettingsAccessor.Item.finishedPlannings) {
            _ = removePlanningAction(SettingsAccessor.Item.unfinishedPlannings)
        }
    }    
}

extension SettingsAccessor: NSFilePresenter {
    public var presentedItemURL: URL? {
        return Constants.storeURL
    }
    
    public var presentedItemOperationQueue: OperationQueue {
        return OperationQueue()
    }
    
    public func presentedItemDidGain(_ version: NSFileVersion) {
        if version.localizedName != nil {
            let thatStore = NSMutableDictionary(contentsOf: version.url) ?? NSMutableDictionary()
            let thatVersion = thatStore.value(forKey: "version") as? Int ?? 0
            let thisVersion = Constants.store.get(key: "version") as? Int ?? 0
            
            log.info("new settings version of file found")
            do {
                if thisVersion < thatVersion {
                    version.isResolved = true
                    try version.replaceItem(at: Constants.storeURL, options: [.init(rawValue: 0)])
                    try NSFileVersion.removeOtherVersionsOfItem(at: Constants.storeURL)
                    log.info("found remote version, which is newer, use that one")
                } else {
                    version.isResolved = true
                    try NSFileVersion.removeOtherVersionsOfItem(at: Constants.storeURL)
                    log.info("found remote version, which is older, removed")
                }
            } catch {
                log.error(error)
            }
        }
        
    }
}
