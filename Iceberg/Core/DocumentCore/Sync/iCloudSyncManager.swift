//
//  iCloudSyncManager.swift
//  Business
//
//  Created by ian luo on 2019/11/28.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public struct iCloudSyncManager: SyncManagerProtocol {
    public init(iCloudDocumentManager: iCloudDocumentManager) {
        self._iCloudDocumentManager = iCloudDocumentManager
    }
    
    private let _iCloudDocumentManager: iCloudDocumentManager
    
    public var remoteFileRelativePaths: [String] {
        if let remoteRoot = self.remoteRoot, self.isReadyToUse {
            return remoteRoot.allPackagesInside.map {
                $0.resolvingSymlinksInPath().path.replacingOccurrences(of: remoteRoot.resolvingSymlinksInPath().path, with: "").removingPercentEncoding!
            }
        } else {
            return []
        }
    }
    
    public func `switch`(_ on: Bool, complete: @escaping (Bool) -> Void) {
        self._iCloudDocumentManager.swithiCloud(on: on) { error in
            if let error = error {
                log.error(error)
                complete(false)
            } else {
                complete(true)
            }
        }
    }
    
    public func urlForRelativePath(_ path: String) -> URL? {
        return self.remoteRoot?.appendingPathComponent(path)
    }
    
    public var isReadyToUse: Bool {
        return self._iCloudDocumentManager.iCloudAccountStatus == .open
    }
    
    public var remoteRoot: URL? {
        return iCloudDocumentManager.iCloudRoot?.appendingPathComponent("Documents")
    }
}
