//
//  SyncManager.swift
//  Iceland
//
//  Created by ian luo on 2018/12/2.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol DocumentSyncDelegate: class {
    func didSyncUpdated(progress: Double)
    func didSyncCompleted()
    func didSyncFailed(with error: Error)
}

public class SyncManager {
    
}
