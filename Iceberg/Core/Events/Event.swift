//
//  Event.swift
//  Business
//
//  Created by ian luo on 2019/3/1.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public class Event: NSObject {
}

// MARK: - App Events
public class AppStartedEvent: Event {}

public class UIStackReadyEvent: Event {}

// MARK: - Editor events


// MARK: -

public class AddDocumentEvent: Event {
    public let url: URL
    public init (url: URL) { self.url = url }
}

public class DeleteDocumentEvent: Event {
    public let url: URL
    public init (url: URL) { self.url = url }
}

public class RenameDocumentEvent: Event {
    public let oldUrl: URL
    public let newUrl: URL
    public init (oldUrl: URL, newUrl: URL) { self.oldUrl = oldUrl; self.newUrl = newUrl }
}

public class ChangeDocumentCoverEvent: Event {
    public let url: URL
    public let image: UIImage?
    public init (url: URL, image: UIImage?) { self.url = url; self.image = image }
}

public class UpdateDocumentEvent: Event {
    public let url: URL
    public init(url: URL) { self.url = url }
}

public class OpenDocumentEvent: Event {
    public let url: URL
    public init(url: URL) { self.url = url }
}

public class RecentDocumentRenamedEvent: RenameDocumentEvent {
    public init(renameDocumentEvent: RenameDocumentEvent) {
        super.init(oldUrl: renameDocumentEvent.oldUrl, newUrl: renameDocumentEvent.newUrl)
    }
}

// MARK: -

public class DocumentHeadingChangeEvent: Event {
    public let url: URL
    public let oldHeadings: [HeadingToken]
    public let newHeadings: [HeadingToken]

    public init(url: URL, oldHeadings: [HeadingToken], newHeadings: [HeadingToken]) {
        self.url = url
        self.oldHeadings = oldHeadings
        self.newHeadings = newHeadings
    }
}

// MARK: -

public class DocumentAgendaRelatedChangeEvent: Event {
    public let url: URL
    public let oldHeadings: [HeadingToken]
    public let newHeadings: [HeadingToken]

    public init(url: URL, oldHeadings: [HeadingToken], newHeadings: [HeadingToken]) {
        self.url = url
        self.oldHeadings = oldHeadings
        self.newHeadings = newHeadings
    }
}

// MARK: -

public class AttachmentAddedEvent: Event {
    let attachmentId: String
    
    public init(attachmentId: String) {
        self.attachmentId = attachmentId
    }
}

public class NewCaptureAddedEvent: AttachmentAddedEvent {
    let kind: String
    
    public init(attachmentId: String, kind: String) {
        self.kind = kind
        super.init(attachmentId: attachmentId)
    }
}

public class DateAndTimeChangedEvent: Event {
    let oldDateAndTime: DateAndTimeType?
    let newDateAndTime: DateAndTimeType?
    
    public init(oldDateAndTime: DateAndTimeType?, newDateAndTime: DateAndTimeType?) {
        self.oldDateAndTime = oldDateAndTime
        self.newDateAndTime = newDateAndTime
    }
}

public class ImportFileEvent: Event {
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
}

/// icloud turned on in settings
public class iCloudEnabledEvent: Event {}
/// icloud turnd off in settings
public class iCloudDisabledEvent: Event {}

/// is files available for iCloud
public class iCloudAvailabilityChangedEvent: Event {
    public let isEnabled: Bool
    public init(isEnabled: Bool) { self.isEnabled = isEnabled }
}
