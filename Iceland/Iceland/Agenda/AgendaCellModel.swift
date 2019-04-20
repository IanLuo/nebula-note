//
//  AgendaCellModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/7.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Business

public class AgendaCellModel {
    public var headingText: String
    public let dateAndTimeRange: NSRange?
    public let url: URL
    public var planning: String?
    public var dateAndTime: DateAndTimeType?
    public var tags: [String]?
    public var priority: String?
    public let heading: DocumentHeading
    
    public init(searchResult: DocumentHeadingSearchResult) {
        self.priority = searchResult.heading.priority
        self.dateAndTime = searchResult.dateAndTime
        self.dateAndTimeRange = searchResult.dateAndTimeRange
        self.url = searchResult.documentInfo.url
        self.heading = searchResult.heading
        self.headingText = searchResult.headingString.trimmingCharacters(in: CharacterSet.whitespaces)
        self.planning = searchResult.heading.planning
        self.tags = searchResult.heading.tags
    }
}
