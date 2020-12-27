//
//  Outline.swift
//  Iceland
//
//  Created by ian luo on 2018/11/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public struct OutlineAttribute {
    public static let hidden: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HIDDEN)
    public static let hiddenValueDefault: NSNumber = NSNumber(value: OUTLINE_ATTRIBUTE_HIDDEN_VALUE_DEFAULT)
    public static let hiddenValueWithAttachment: NSNumber = NSNumber(value: OUTLINE_ATTRIBUTE_HIDDEN_VALUE_WITH_ATTACHMENT)
    public static let hiddenValueFolded: NSNumber = NSNumber(value: OUTLINE_ATTRIBUTE_HIDDEN_VALUE_FOLDED)
    
    public static let tempHidden: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_TEMPORARY_HIDDEN)
    
    public static let button: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_BUTTON)
    public static let buttonBorder: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_BUTTON_BORDER)
    
    public static let separator: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_SEPARATOR)
    
    public static let showAttachment: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_SHOW_ATTACHMENT)
    public static let tempShowAttachment: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_TEMPAROTY_SHOW_ATTACHMENT)
    
    public static let dateAndTime: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_DATE_AND_TIME)
    
    public static let documentLink: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_DOCUMENT_URL)
    
    public struct Attachment {
        public static let attachment: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_ATTACHMENT)
        public static let value: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_ATTACHMENT_VALUE)
        public static let type: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_ATTACHMENT_TYPE)
        public static let unavailable: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_ATTACHMENT_UNAVAILABLE)
    }
    
    public struct Link {
        public static let title: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_LINK_TITLE)
        public static let url: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_LINK_URL)
        public static let other: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_LINK_OTHER)
    }
    
    public struct UnorderedList {
        public static let range: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_UNORDERED_LIST)
        public static let prefix: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_UNORDERED_LIST_PREFIX)
    }
    
    public struct OrderedList {
        public static let range: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_ORDERED_LIST)
        public static let index: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_ORDERED_LIST_INDEX)
    }
    
    public static let checkbox: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_CHECKBOX)
    
    public struct Heading {
        public static let content: NSAttributedString.Key = NSAttributedString.Key("heading-content")
        public static let level: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_LEVEL)
        public static let folded: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_FOLDED)
        public static let foldingFolded: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_FOLD_FOLDED)
        public static let foldingUnfolded: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_FOLD_UNFOLDED)
        public static let schedule: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_SCHEDULE)
        public static let due: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_DUE)
        public static let tags: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_TAGS)
        public static let priority: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_PRIORITY)
        public static let planning: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_HEADING_PLANNING)
    }
    
    public struct Block {
        public static let quote: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_BLOCK_QUOTE)
        public static let code: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_BLOCK_CODE)
    }
    
    public static let onePiease: NSAttributedString.Key = NSAttributedString.Key(OUTLINE_ATTRIBUTE_ONE_PIEASE)
}
