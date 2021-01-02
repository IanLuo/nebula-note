//
//  SyncTests.swift
//  IcebergTests
//
//  Created by ian luo on 2019/12/1.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
@testable import x3Note
import XCTest
@testable import Core

class SyncTests: XCTestCase {
    func testFindFilesToSyncUp() {
        let syncCoordinator = SyncCoordinator(eventObserver: EventObserver())
        let files = syncCoordinator.findRelativeFilePathsToSyncUp(remoteSyncManager: iCloudSyncManager(iCloudDocumentManager: iCloudDocumentManager(eventObserver: EventObserver())), localFiles: URL.localRootURL.allPackagesInside)
        print(files)
    }
    
    func testFindFilesToSyncDown() {
        let syncCoordinator = SyncCoordinator(eventObserver: EventObserver())
        let files = syncCoordinator.findRelativeFilePathsToSyncDown(remoteSyncManager: iCloudSyncManager(iCloudDocumentManager: iCloudDocumentManager(eventObserver: EventObserver())), localFiles: URL.localRootURL.allPackagesInside)
        print(files)
    }
}
