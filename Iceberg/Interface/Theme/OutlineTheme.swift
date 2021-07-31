//
//  OutlineTheme.swift
//  Iceland
//
//  Created by ian luo on 2018/11/22.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class OutlineThemeSelector {
    private static let _instance: OutlineThemeSelector = OutlineThemeSelector(theme: OutlineThemeStyle(theme: DarkInterfaceTheme()))
    fileprivate var currentTheme: OutlineThemeConfigProtocol
    
    private init(theme: OutlineThemeConfigProtocol) {
        self.currentTheme = theme
    }
    
    public static var shared: OutlineThemeSelector {
        return _instance
    }
    
    public func changeTheme(_ theme: OutlineThemeConfigProtocol) {
        OutlineThemeSelector.shared.currentTheme = theme
    }
}

@objc public class OutlineTheme: NSObject {
    public static var textMarkStyle: TextMarkStyle {
        return OutlineThemeSelector.shared.currentTheme.textMarkStyle
    }
    
    public static func dateAndTimeStyle(datesFromToday: Int) -> ButtonStyle {
        if datesFromToday > 1 {
            return OutlineThemeSelector.shared.currentTheme.dateAndTimeStyle.normal
        } else if datesFromToday <= 1 && datesFromToday >= 0 {
            return OutlineThemeSelector.shared.currentTheme.dateAndTimeStyle.soon
        } else {
            return OutlineThemeSelector.shared.currentTheme.dateAndTimeStyle.overtime
        }
    }
    
    public static func planningStyle(isFinished: Bool) -> ButtonStyle {
        if isFinished {
            return OutlineThemeSelector.shared.currentTheme.planningStyle.finished
        } else {
            return OutlineThemeSelector.shared.currentTheme.planningStyle.unfinished
        }
    }
    
    public static func priorityStyle(_ priority: String) -> ButtonStyle {
        switch priority {
        case "[#A]": return OutlineThemeSelector.shared.currentTheme.priorityStyle.a
        case "[#B]": return OutlineThemeSelector.shared.currentTheme.priorityStyle.b
        case "[#C]": return OutlineThemeSelector.shared.currentTheme.priorityStyle.c
        case "[#D]": return OutlineThemeSelector.shared.currentTheme.priorityStyle.d
        case "[#E]": return OutlineThemeSelector.shared.currentTheme.priorityStyle.e
        case "[#F]": return OutlineThemeSelector.shared.currentTheme.priorityStyle.f
        default: return OutlineThemeSelector.shared.currentTheme.priorityStyle.a
        }
    }
    
    public static var paragraphStyle: TextStyle {
        return OutlineThemeSelector.shared.currentTheme.paragraphStyle
    }
    
    public static var markStyle: TextStyle {
        return OutlineThemeSelector.shared.currentTheme.markStyle
    }
    
    public static var checkboxStyle: TextStyle {
        return OutlineThemeSelector.shared.currentTheme.checkboxStyle
    }
    
    public static var linkStyle: TextStyle {
        return OutlineThemeSelector.shared.currentTheme.linkStyle
    }
    
    public static var orderdedListStyle: TextStyle {
        return OutlineThemeSelector.shared.currentTheme.orderdedListStyle
    }
    
    public static var unorderdedListStyle: TextStyle {
        return OutlineThemeSelector.shared.currentTheme.unorderdedListStyle
    }
    
    public static var codeBlockStyle: CodeBlockStyle {
        return OutlineThemeSelector.shared.currentTheme.codeBlockStyle
    }
    
    public static var quoteBlockStyle: QuoteBlockStyle {
        return OutlineThemeSelector.shared.currentTheme.quoteBlockStyle
    }
    
    public static func headingStyle(level: Int) -> TextStyle {
        let defaultStyle = OutlineThemeSelector.shared.currentTheme.headingStyle
        let textStyle = TextStyle(font: defaultStyle.font, color: defaultStyle.color)
        return textStyle
    }
    
    public static var tagStyle: ButtonStyle {
        return OutlineThemeSelector.shared.currentTheme.tagStyle
    }
    
    public static var seperatorStyle: UIColor {
        return OutlineThemeSelector.shared.currentTheme.seperatorStyle
    }
}

public protocol OutlineThemeConfigProtocol {
    var textMarkStyle: TextMarkStyle { get }
    var dateAndTimeStyle: DateAndTimeStyle { get }
    var planningStyle: PlanningStyle { get }
    var priorityStyle: PriorityStyle { get }
    var tagStyle: ButtonStyle { get }
    var paragraphStyle: TextStyle { get }
    var markStyle: TextStyle { get }
    var linkStyle: TextStyle { get }
    var checkboxStyle: TextStyle { get }
    var orderdedListStyle: TextStyle { get }
    var unorderdedListStyle: TextStyle { get }
    var codeBlockStyle: CodeBlockStyle { get }
    var quoteBlockStyle: QuoteBlockStyle { get }
    var headingStyle: TextStyle { get }
    var seperatorStyle: UIColor { get }
}

public struct OutlineThemeStyle: OutlineThemeConfigProtocol {
    public init(theme: InterfaceThemeProtocol) {
        let blockParagraph = NSMutableParagraphStyle()
        blockParagraph.headIndent = 20
        blockParagraph.firstLineHeadIndent = 20
        
        self.seperatorStyle = theme.color.secondaryDescriptive
        self.headingStyle = TextStyle(font: UIFont.boldSystemFont(ofSize: theme.font.body.pointSize) , color: theme.color.interactive)
        self.orderdedListStyle = TextStyle(font: theme.font.title, color: theme.color.secondaryDescriptive)
        self.unorderdedListStyle = TextStyle(font: theme.font.title, color: theme.color.secondaryDescriptive)
        self.checkboxStyle = TextStyle(font: theme.font.title, color: theme.color.spotlight)
        self.linkStyle = TextStyle(font: theme.font.body, color: theme.color.spotlight)
        self.markStyle = TextStyle(font: theme.font.footnote, color: theme.color.secondaryDescriptive.withAlphaComponent(0.3))
        self.paragraphStyle = TextStyle(font: theme.font.body, color: theme.color.interactive)
        self.codeBlockStyle = CodeBlockStyle(textStyle: TextStyle(font: theme.font.body,
                                                                  color: theme.color.interactive,
                                                                  otherAttributes: [NSAttributedString.Key.paragraphStyle: blockParagraph]),
                                             backgroundColor: theme.color.background2)
        self.quoteBlockStyle = QuoteBlockStyle(textStyle: TextStyle(font: theme.font.body,
                                                                    color: theme.color.descriptive,
                                                                    otherAttributes: [NSAttributedString.Key.paragraphStyle: blockParagraph]),
                                               backgroundColor: theme.color.background2)
        self.textMarkStyle = TextMarkStyle(bold: TextStyle(font: theme.font.title, color: theme.color.interactive),
                                           italic: TextStyle(font: theme.font.italic, color: theme.color.descriptive),
                                           underscore: TextStyle(font: theme.font.body, color: theme.color.descriptive,
                                                                 otherAttributes: [NSAttributedString.Key.underlineStyle: 1]),
                                           strikethrought: TextStyle(font: theme.font.body, color: theme.color.secondaryDescriptive,
                                                                     otherAttributes: [NSAttributedString.Key.strikethroughStyle: 1]),
                                           verbatim: TextStyle(font: theme.font.body, color: theme.color.descriptive),
                                           highlight: TextStyle(font: theme.font.body, color: theme.color.interactive))
     /// 目前没有使用 button color, 因为 button 显示有问题
       self.dateAndTimeStyle = DateAndTimeStyle(normal: ButtonStyle(buttonColor: theme.color.finished,
                                                                     textStyle: TextStyle(font: theme.font.footnote,
                                                                                          color: theme.color.finished)),
                                                 soon: ButtonStyle(buttonColor: theme.color.unfinished,
                                                                   textStyle: TextStyle(font: theme.font.footnote,
                                                                                        color: theme.color.unfinished)),
                                                 overtime: ButtonStyle(buttonColor: theme.color.warning,
                                                                       textStyle: TextStyle(font: theme.font.footnote,
                                                                                            color: theme.color.warning)),
                                                 finished: ButtonStyle(buttonColor: theme.color.background3,
                                                                       textStyle: TextStyle(font: theme.font.footnote,
                                                                                            color: theme.color.descriptive)))
        self.planningStyle = PlanningStyle(finished: ButtonStyle(buttonColor: theme.color.finished,
                                                                 textStyle: TextStyle(font: theme.font.footnote,
                                                                                      color: theme.color.background3)),
                                           unfinished: ButtonStyle(buttonColor: theme.color.unfinished,
                                                                   textStyle: TextStyle(font: theme.font.footnote,
                                                                                        color: theme.color.background3)))
        self.tagStyle = ButtonStyle(buttonColor: theme.color.background3,
                                    textStyle: TextStyle(font: theme.font.footnote, color: theme.color.interactive))
        self.priorityStyle = PriorityStyle(a: ButtonStyle(buttonColor: theme.color.warning,
                                                          textStyle: TextStyle(font: theme.font.footnote,
                                                                               color: theme.color.background3)),
                                           b: ButtonStyle(buttonColor: theme.color.warning,
                                                          textStyle: TextStyle(font: theme.font.footnote,
                                                                               color: theme.color.background3)),
                                           c: ButtonStyle(buttonColor: theme.color.unfinished,
                                                          textStyle: TextStyle(font: theme.font.footnote,
                                                                               color: theme.color.background3)),
                                           d: ButtonStyle(buttonColor: theme.color.unfinished,
                                                          textStyle: TextStyle(font: theme.font.footnote,
                                                                               color: theme.color.background3)),
                                           e: ButtonStyle(buttonColor: theme.color.finished,
                                                          textStyle: TextStyle(font: theme.font.footnote,
                                                                               color: theme.color.background3)),
                                           f: ButtonStyle(buttonColor: theme.color.finished,
                                                          textStyle: TextStyle(font: theme.font.footnote,
                                                                               color: theme.color.background3)))
    }
    
    public let seperatorStyle: UIColor
    public let headingStyle: TextStyle
    public let orderdedListStyle: TextStyle
    public let unorderdedListStyle: TextStyle
    public let checkboxStyle: TextStyle
    public let linkStyle: TextStyle
    public let markStyle: TextStyle
    public let paragraphStyle: TextStyle
    public let codeBlockStyle: CodeBlockStyle
    public let quoteBlockStyle: QuoteBlockStyle
    public let textMarkStyle: TextMarkStyle
    public let dateAndTimeStyle: DateAndTimeStyle
    public let planningStyle: PlanningStyle
    public let tagStyle: ButtonStyle
    public let priorityStyle: PriorityStyle
}

public struct CodeBlockStyle {
    public let textStyle: TextStyle
    public let backgroundColor: UIColor
    
    public var attributes: [NSAttributedString.Key: Any] {
        return textStyle.attributes
    }
}

public struct QuoteBlockStyle {
    public let textStyle: TextStyle
    public let backgroundColor: UIColor
    
    public var attributes: [NSAttributedString.Key: Any] {
        return textStyle.attributes
    }
}

public struct PriorityStyle {
    public let a: ButtonStyle
    public let b: ButtonStyle
    public let c: ButtonStyle
    public let d: ButtonStyle
    public let e: ButtonStyle
    public let f: ButtonStyle
}

public struct PlanningStyle {
    public let finished: ButtonStyle
    public let unfinished: ButtonStyle
}

public struct DateAndTimeStyle {
    public let normal: ButtonStyle
    public let soon: ButtonStyle
    public let overtime: ButtonStyle
    public let finished: ButtonStyle
}

public struct TextMarkStyle {
    public let bold: TextStyle
    public let italic: TextStyle
    public let underscore: TextStyle
    public let strikethrought: TextStyle
    public let verbatim: TextStyle
    public let highlight: TextStyle
}

public struct TextStyle {
    public let font: UIFont
    public let color: UIColor
    public let otherAttributes: [NSAttributedString.Key: Any]?
    
    public init(font: UIFont, color: UIColor, otherAttributes: [NSAttributedString.Key: Any]? = nil) {
        self.font = font
        self.color = color
        self.otherAttributes = otherAttributes
    }
    
    public var attributes: [NSAttributedString.Key: Any] {
        if var otherAttributes = self.otherAttributes {
            otherAttributes[NSAttributedString.Key.foregroundColor] = self.color
            otherAttributes[NSAttributedString.Key.font] = self.font
            return otherAttributes
        } else {
            return [NSAttributedString.Key.foregroundColor: self.color,
                    NSAttributedString.Key.font: self.font]
        }
    }
}

public struct ButtonStyle {
    public let buttonColor: UIColor
    public let textStyle: TextStyle
}
