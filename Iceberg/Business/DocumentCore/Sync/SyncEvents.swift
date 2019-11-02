//
//  SyncEvents.swift
//  Business
//
//  Created by ian luo on 2019/3/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

/// user changed the icloud switch status
public class iCloudOpeningStatusChangedEvent: Event {
    public let isiCloudEnabled: Bool
    
    public init(isiCloudEnabled: Bool) {
        self.isiCloudEnabled = isiCloudEnabled
    }
}

public class NewDocumentPackageDownloadedEvent: Event {
    public let url: URL
    public init(url: URL) {
        self.url = url
    }
}

public class NewAttachmentDownloadedEvent: Event {
    public let url: URL
    public init(url: URL) {
        self.url = url
    }
}

public class NewRecentFilesListDownloadedEvent: Event {
    public let url: URL
    public init(url: URL) {
        self.url = url
    }
}

public class NewCaptureListDownloadedEvent: Event {
    public let url: URL
    public init(url: URL) {
        self.url = url
    }
}

public class DocumentRemovedFromiCloudEvent: Event {
    public let url: URL
    public init(url: URL) {
        self.url = url
    }
}

public class NewDocumentAddedFromiCloudEvent: Event {
    public let url: URL
    public init(url: URL) {
        self.url = url
    }
}

