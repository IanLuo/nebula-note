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
    public let heading: DocumentHeading
    public let contentSummary: String
    
    public init(heading: DocumentHeading) {
        self.headingLocation = heading.location
        self.url = heading.url
        self.heading = heading
        self.headingText = heading.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        self.contentSummary = heading.paragraphSummery.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//        self.schedule = heading.schedule
//        self.due = heading.due
        self.planning = heading.planning
        self.tags = heading.tags
    }
}
