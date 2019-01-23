//
//  Outline.swift
//  Iceland
//
//  Created by ian luo on 2018/11/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import TextStorage

public struct OutlineAttribute {
    public struct Link {
        public static let title: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_LINK_TITLE)
        public static let link: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_LINK)
    }
    
    public struct Checkbox {
        public static let box: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_CHECKBOX_BOX)
        public static let status: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_CHECKBOX_STATUS)
    }
    
    public struct Heading {
        public static let level: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_LEVEL)
        public static let folded: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_FOLDED)
        public static let schedule: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_SCHEDULE)
        public static let due: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_DUE)
        public static let tags: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_TAGS)
    }
}
