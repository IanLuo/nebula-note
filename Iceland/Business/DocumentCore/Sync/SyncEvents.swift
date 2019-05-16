//
//  SyncEvents.swift
//  Business
//
//  Created by ian luo on 2019/3/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public class SyncStartEvent: Event {}

public class SyncStatusChangedEvent: Event {
    public let progress: Double
    public init(progress: Double) {
        self.progress = progress
    }
}

public class SyncCompleteEvent: Event {}

public class SyncFailedEvent: Event {
    public enum SyncError: Error {
        case failed
    }
    
    public let error: SyncError
    public init(error: SyncError) {
        self.error = error
    }
}

public class iCloudOpeningStatusChangedevent: Event {
    public let isiCloudEnabled: Bool
    
    public init(isiCloudEnabled: Bool) {
        self.isiCloudEnabled = isiCloudEnabled
    }
}

public class NowUsingLocalDocumentsEvent: Event {}

public class NowUsingiCloudDocumentsEvent: Event {}
