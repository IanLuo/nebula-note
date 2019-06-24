//
//  ShareExtensionDataHandler.swift
//  Business
//
//  Created by ian luo on 2019/6/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public struct ShareExtensionDataHandler {
    public init() {}
    
    public var sharedContainterURL: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.icenote.share")!
    }
}
