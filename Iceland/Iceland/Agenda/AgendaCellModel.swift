//
//  AgendaCellModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/7.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public class AgendaCellModel {
    
    public var headingText: String
    public var planning: String? = nil
    public var schedule: DateAndTimeType? = nil
    public var due: DateAndTimeType? = nil
    public var tags: [String]? = nil
    
    public init(heading: OutlineTextStorage.Heading, text: String) {
        self.headingText = (text as NSString).substring(with: heading.range)
        
        if let schedule = heading.schedule {
            let dateRange = schedule.offset(-heading.range.location)
            self.schedule = DateAndTimeType.createFromSchedule((text as NSString).substring(with: dateRange))

            self.headingText = (self.headingText as NSString).replacingCharacters(in: dateRange, with: "")
        }
        
        if let schedule = heading.due {
            let dateRange = schedule.offset(-heading.range.location)
            self.due = DateAndTimeType.createFromSchedule((text as NSString).substring(with: dateRange))
            
            self.headingText = (self.headingText as NSString).replacingCharacters(in: dateRange, with: "")
        }
        
        if let planning = heading.planning {
            let planningRange = planning.offset(-heading.range.location)
            self.planning = (text as NSString).substring(with: planningRange)
            
            self.headingText = (self.headingText as NSString).replacingCharacters(in: planningRange, with: "")
        }
        
        if let tags = heading.tags {
            let tagsRange = tags.offset(-heading.range.location)
            self.tags = (text as NSString).substring(with: tagsRange).components(separatedBy: ":").filter { $0.count > 0 }
            
            self.headingText = (self.headingText as NSString).replacingCharacters(in: tagsRange, with: "")
        }
        
    }
}
