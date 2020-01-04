//
//  Paragraph.swift
//  Interface
//
//  Created by ian luo on 2020/1/4.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation

public extension NSParagraphStyle {
    static var bulletDescriptive: NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.headIndent = 15
        paragraph.lineSpacing = 10
        return paragraph
    }
    
    static var descriptive: NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 10
        return paragraph
    }
}
