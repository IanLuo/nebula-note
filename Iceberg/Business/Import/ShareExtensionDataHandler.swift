//
//  ShareExtensionDataHandler.swift
//  Business
//
//  Created by ian luo on 2019/6/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

/// 通过第三发 app 分享
public struct ShareExtensionDataHandler {
    public init() {}
    
    public var sharedContainterURL: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.iceberg.share")!
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
}
