//
//  SearchTabelCellModel.swift
//  Iceland
//
//  Created by ian luo on 2019/1/22.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Business

public struct SearchTabelCellModel {
    public let fileName: String
    public let textString: String
    public let hilightRange: NSRange
    public let url: URL
    
    public init(searchResult: DocumentTextSearchResult) {
        self.fileName = searchResult.documentInfo.url.fileName
        self.textString = searchResult.context
        self.hilightRange = searchResult.highlightRange
        self.url = searchResult.documentInfo.url
    }
}
