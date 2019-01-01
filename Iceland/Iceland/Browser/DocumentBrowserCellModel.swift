//
//  DocumentBrowserCellModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class DocumentBrowserCellModel {
    public var url: URL
    public var isFolded: Bool = true
    public var parent: URL?
    public var levelFromRoot: Int
    
    public init(url: URL) {
        self.url = url
        self.parent = url.parentDocumentURL
        self.levelFromRoot = url.convertoFolderURL.urlReleatedToRoot.deletingLastPathComponent().pathComponents.filter { $0 != "." }.count
    }
    
    public var hasSubDocuments: Bool {
        return url.hasSubDocuments
    }
}
