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
    public let heading: Document.Heading
    public let trimmedHeading: String
    
    public init(heading: Document.Heading, text: String, url: URL, trimmedHeading: String) {
        self.headingText = text
        var trimmedHeading = trimmedHeading.substring(NSRange(location: heading.level + 1, length: trimmedHeading.count - heading.level - 1)) // + 1 为 level 后的空格
        if let planning = heading.planning {
            trimmedHeading = trimmedHeading.substring(NSRange(location: planning.length + 1, length: trimmedHeading.count - planning.length - 1)) // 同上
        }
        if let schedule = heading.schedule {
            trimmedHeading = trimmedHeading.substring(NSRange(location: 0, length: trimmedHeading.count - schedule.length - 1)) // schedule 前面有一个空格
        }
        if let due = heading.due {
            trimmedHeading = trimmedHeading.substring(NSRange(location: 0, length: trimmedHeading.count - due.length - 1)) // due 前面有一个空格
        }
        self.trimmedHeading = trimmedHeading
        self.headingLocation = heading.range.location
        self.url = url
        self.heading = heading
        
        if let schedule = heading.schedule {
            let dateRange = schedule.offset(-heading.range.location)
            self.schedule = DateAndTimeType.createFromSchedule((text as NSString).substring(with: dateRange))

            self.headingText = (self.headingText as NSString).replacingCharacters(in: dateRange, with: "")
        }
        
        if let due = heading.due {
            let dateRange = due.offset(-heading.range.location)
            self.due = DateAndTimeType.createFromDue(text.substring(dateRange))
            
            self.headingText = (self.headingText as NSString).replacingCharacters(in: dateRange, with: "")
        }
        
        if let planning = heading.planning {
            let planningRange = planning.offset(-heading.range.location)
            self.planning = text.substring(planningRange)
            
            self.headingText = (self.headingText as NSString).replacingCharacters(in: planningRange, with: "")
        }
        
        if let tags = heading.tags {
            let tagsRange = tags.offset(-heading.range.location)
            self.tags = (text as NSString).substring(with: tagsRange).components(separatedBy: ":").filter { $0.count > 0 }
            
            self.headingText = (self.headingText as NSString).replacingCharacters(in: tagsRange, with: "")
        }
    }
}
