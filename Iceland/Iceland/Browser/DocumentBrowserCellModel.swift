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
    public var shouldShowActions: Bool = true
    public var shouldShowChooseHeadingIndicator: Bool = false
    
    public init(url: URL) {
        self.url = url
        self.parent = url.parentDocumentURL
        self.levelFromRoot = url.pathReleatedToRoot.components(separatedBy: "/").filter { $0.count > 0 }.count
    }
    
    public var hasSubDocuments: Bool {
        return url.hasSubDocuments
    }
}
