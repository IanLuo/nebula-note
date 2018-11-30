//
//  Outline.swift
//  Iceland
//
//  Created by ian luo on 2018/11/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public struct OutlineAttribute {
    public struct Link {
        public static let title: NSAttributedString.Key = NSAttributedString.Key("link-title")
    }
    
    public struct Checkbox {
        public static let box: NSAttributedString.Key = NSAttributedString.Key("checkbox-box")
        public static let status: NSAttributedString.Key = NSAttributedString.Key("checkbox-status")
    }
    
    public struct Heading {
        public static let level: NSAttributedString.Key = NSAttributedString.Key("heading-level")
        public static let folded: NSAttributedString.Key = NSAttributedString.Key("heading-folded")
        public static let schedule: NSAttributedString.Key = NSAttributedString.Key("heading-schedule")
        public static let deadline: NSAttributedString.Key = NSAttributedString.Key("heading-deadline")
        public static let tags: NSAttributedString.Key = NSAttributedString.Key("heading-tags")
    }
    public static let link: NSAttributedString.Key = NSAttributedString.Key("link")
}
