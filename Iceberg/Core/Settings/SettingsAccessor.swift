//
//  SettingsAccessor.swift
//  Iceland
//
//  Created by ian luo on 2018/12/15.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Interface
import RxSwift
import RxCocoa

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
        static var favoritesStore: KeyValueStore { StoreContainer.shared.get(store: .favorite) }
        static var settingsStore: KeyValueStore { StoreContainer.shared.get(store: .setting) }
        static var recentFilesStore: KeyValueStore = { StoreContainer.shared.get(store: .openningFiles) }()
        static let storeURL: URL = StoreContainer.shared.storeURL(store: .setting)
    }
    
    public enum Item: String {
        case finishedPlannings
        case unfinishedPlannings
        case landingTabIndex
        case interfaceStyle
        case exportShowIndex
        case currentSubscription
        case isFirstLaunchApp
        case didShowUserGuide
        case browserCellMode
        
        public func set(_ value: Any, completion: @escaping () -> Void) {
            Constants.settingsStore.set(value: value, key: self.rawValue, completion: completion)
        }
        
        public func get<T>(_ t: T.Type) -> T? {
            return Constants.settingsStore.get(key: self.rawValue, type: T.self)
        }
    }
    
    private static let instance = SettingsAccessor()
    
    private override init() {
        super.init()
    }
    @objc public static var shared: SettingsAccessor { return instance }
    
    public func getSetting<T>(item: Item, type: T.Type) -> T? {
        return item.get(T.self)
    }
    
    public func setSetting<T>(item: Item, value: T, completion: @escaping () -> Void) {
        item.set(value, completion: completion)
    }
    
    public let documentDidOpen: PublishSubject<URL> = PublishSubject()
    
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
        return InterfaceTheme.Font.body.capHeight
    }
    
    public var maxLevel: Int {
        return 6
    }
    
    public var priorities: [String] {
        return OutlineParser.Values.Heading.Priority.all
    }
    
    public func logOpenDocument(url: URL) {
        Constants.recentFilesStore.set(value: "\(Date().timeIntervalSince1970)",
                                       key: url.documentRelativePath, completion: {})
        
        documentDidOpen.onNext(url)
    }
    
    public func logCloseDocument(url: URL) {
        Constants.recentFilesStore.remove(key: url.documentRelativePath, completion: {})
    }
    
    public var favorites: [String] {
        return Constants.favoritesStore.allKeys()
    }
    
    public func addFavorite(id: String, completion: @escaping () -> Void) {
        Constants.favoritesStore.set(value: "", key: id, completion: completion)
    }
    
    public func removeFavorite(id: String, completion: @escaping () -> Void) {
        Constants.favoritesStore.remove(key: id, completion: completion)
    }
    
    public var openedDocuments: [URL]? {
        let resourceKeys: Set<URLResourceKey> = [.creationDateKey, .contentModificationDateKey]
        
        return Constants.recentFilesStore.allKeys().map {
            URL.documentBaseURL.appendingPathComponent($0)
        }.sorted(by: { url1, url2 in
            do {
                let urlResourceValue1 = try url1.resourceValues(forKeys: resourceKeys)
                let urlResourceValue2 = try url2.resourceValues(forKeys: resourceKeys)
                if let accessDate1 = urlResourceValue1.contentModificationDate, let accessDate2 = urlResourceValue2.contentModificationDate {
                    return accessDate1.timeIntervalSince1970 < accessDate2.timeIntervalSince1970
                } else {
                    return true
                }
            } catch {
                return true
            }
        })
    }
    
    public var interfaceStyle: InterfaceStyle {
        // 支持 dark mode 的系统，默认值为自动，否则为 dark
        if #available(iOS 13, *) {
            return InterfaceStyle(rawValue: SettingsAccessor.Item.interfaceStyle.get(String.self) ?? InterfaceStyle.auto.rawValue) ?? InterfaceStyle.auto
        } else {
            return InterfaceStyle(rawValue: SettingsAccessor.Item.interfaceStyle.get(String.self) ?? InterfaceStyle.light.rawValue) ?? InterfaceStyle.dark
        }
    }
    
    public var customizedUnfinishedPlannings: [String]? {
        return (SettingsAccessor.Item.unfinishedPlannings.get([String].self) ?? []) + StoreContainer.shared.get(store: .customizedUnfinishedStatus).allKeys()
    }
    
    public var customizedFinishedPlannings: [String]? {
        return (SettingsAccessor.Item.finishedPlannings.get([String].self) ?? []) + StoreContainer.shared.get(store: .customizedFinishedStatus).allKeys()
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
        if isForFinished {
            StoreContainer.shared.get(store: .customizedFinishedStatus).set(value: "", key: planning) {
                completion(.success(()))
            }
        } else {
            StoreContainer.shared.get(store: .customizedUnfinishedStatus).set(value: "", key: planning) {
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
        
        StoreContainer.shared.get(store: .customizedFinishedStatus).remove(key: planning, completion: {})
        StoreContainer.shared.get(store: .customizedUnfinishedStatus).remove(key: planning, completion: {})
    }    
}
