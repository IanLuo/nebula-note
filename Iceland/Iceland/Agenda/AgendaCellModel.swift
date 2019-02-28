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
    public let headingLocation: Int
    public let url: URL
    public var planning: String? = nil
    public var schedule: DateAndTimeType? = nil
    public var due: DateAndTimeType? = nil
    public var tags: [String]? = nil
    public let heading: Heading
    public let contentSummary: String
    
    public init(heading: Heading, paragraph: String, url: URL, textTrimmer: OutlineTextTrimmer) {
        self.headingLocation = heading.range.location
        self.url = url
        self.heading = heading
        self.headingText = paragraph.substring(heading.headingTextRange)
        self.contentSummary = textTrimmer.trim(string: paragraph, range: heading.contentRange.offset(-heading.range.location)).trimmingCharacters(in: CharacterSet.controlCharacters)

        if let schedule = heading.schedule {
            let dateRange = schedule.offset(-heading.range.location)
            self.schedule = DateAndTimeType.createFromSchedule(paragraph.substring(dateRange))
        }
        
        if let due = heading.due {
            let dateRange = due.offset(-heading.range.location)
            self.due = DateAndTimeType.createFromDue(paragraph.substring(dateRange))
        }
        
        if let planning = heading.planning {
            let planningRange = planning.offset(-heading.range.location)
            self.planning = paragraph.substring(planningRange)
        }
        
        if let tags = heading.tags {
            let tagsRange = tags.offset(-heading.range.location)
            self.tags = paragraph.substring(tagsRange).components(separatedBy: ":").filter { $0.count > 0 }
        }
    }
}
