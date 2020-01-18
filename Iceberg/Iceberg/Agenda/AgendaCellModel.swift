//
//  AgendaCellModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/7.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Core

public class AgendaCellModel {
    public var headingText: String
    public let dateAndTimeRange: NSRange?
    public let url: URL
    public var planning: String?
    public var dateAndTime: DateAndTimeType?
    public var tags: [String]?
    public var priority: String?
    public let heading: DocumentHeading
    public let level: Int
    public let isFinished: Bool?
    public var currentDate: Date?
    
    public init(searchResult: DocumentHeadingSearchResult) {
        self.level = searchResult.heading.level
        self.priority = searchResult.heading.priority
        self.dateAndTime = searchResult.dateAndTime
        self.dateAndTimeRange = searchResult.dateAndTimeRange
        self.url = searchResult.documentInfo.url
        self.heading = searchResult.heading
        self.headingText = searchResult.heading.text.trimmingCharacters(in: CharacterSet.whitespaces)
        self.planning = searchResult.heading.planning
        self.tags = searchResult.heading.tags
        self.currentDate = Date().dayEnd // default to today
        
        if let planning = searchResult.heading.planning {
            self.isFinished = SettingsAccessor.shared.finishedPlanning.contains(planning)
        } else {
            self.isFinished = nil
        }
    }
}
