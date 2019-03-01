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
