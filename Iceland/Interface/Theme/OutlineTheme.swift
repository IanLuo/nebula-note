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
    private static let _instance: OutlineThemeSelector = OutlineThemeSelector(theme: DefaultOutlineTheme())
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
        if datesFromToday > 3 {
            return OutlineThemeSelector.shared.currentTheme.dateAndTimeStyle.normal
        } else if datesFromToday <= 3 && datesFromToday >= 0 {
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
    
    public static var headingStyle: TextStyle {
        return OutlineThemeSelector.shared.currentTheme.headingStyle
    }
    
    public static var tagStyle: ButtonStyle {
        return OutlineThemeSelector.shared.currentTheme.tagStyle
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
}

private struct DefaultOutlineTheme: OutlineThemeConfigProtocol {
    var headingStyle: TextStyle = TextStyle(font: InterfaceTheme.Font.title, color: InterfaceTheme.Color.interactive)
    
    var orderdedListStyle: TextStyle = TextStyle(font: InterfaceTheme.Font.body, color: InterfaceTheme.Color.descriptive)
    
    var unorderdedListStyle: TextStyle = TextStyle(font: InterfaceTheme.Font.body, color: InterfaceTheme.Color.descriptive)
    
    var checkboxStyle: TextStyle = TextStyle(font: InterfaceTheme.Font.body, color: InterfaceTheme.Color.spotlight)
    
    var linkStyle: TextStyle = TextStyle(font: InterfaceTheme.Font.body, color: InterfaceTheme.Color.spotlight)
    
    var markStyle: TextStyle = TextStyle(font: InterfaceTheme.Font.footnote, color: InterfaceTheme.Color.descriptive)
    
    var paragraphStyle: TextStyle = TextStyle(font: InterfaceTheme.Font.body, color: InterfaceTheme.Color.interactive)
    
    var codeBlockStyle: CodeBlockStyle = CodeBlockStyle(textStyle: TextStyle(font: InterfaceTheme.Font.body, color: InterfaceTheme.Color.interactive))
    
    var quoteBlockStyle: QuoteBlockStyle = QuoteBlockStyle(textStyle: TextStyle(font: InterfaceTheme.Font.body, color: InterfaceTheme.Color.interactive))
    
    var textMarkStyle: TextMarkStyle = TextMarkStyle(bold: TextStyle(font: InterfaceTheme.Font.body, color: InterfaceTheme.Color.interactive),
                                                     italic: TextStyle(font: InterfaceTheme.Font.body, color: InterfaceTheme.Color.interactive),
                                                     underscore: TextStyle(font: InterfaceTheme.Font.body, color: InterfaceTheme.Color.interactive),
                                                     strikethrought: TextStyle(font: InterfaceTheme.Font.body, color: InterfaceTheme.Color.interactive),
                                                     verbatim: TextStyle(font: InterfaceTheme.Font.body, color: InterfaceTheme.Color.interactive),
                                                     code: TextStyle(font: InterfaceTheme.Font.body, color: InterfaceTheme.Color.interactive))
    
    var dateAndTimeStyle: DateAndTimeStyle = DateAndTimeStyle(normal: ButtonStyle(buttonColor: InterfaceTheme.Color.interactive,
                                                                                  textStyle: TextStyle(font: InterfaceTheme.Font.body,
                                                                                                       color: InterfaceTheme.Color.interactive)),
                                                              soon: ButtonStyle(buttonColor: UIColor.yellow,
                                                                                textStyle: TextStyle(font: InterfaceTheme.Font.body,
                                                                                                     color: InterfaceTheme.Color.interactive)),
                                                              overtime: ButtonStyle(buttonColor: UIColor.red,
                                                                                    textStyle: TextStyle(font: InterfaceTheme.Font.body,
                                                                                                         color: InterfaceTheme.Color.interactive)))
    
    var planningStyle: PlanningStyle = PlanningStyle(finished: ButtonStyle(buttonColor: UIColor.green,
                                                                           textStyle: TextStyle(font: InterfaceTheme.Font.body,
                                                                                                color: InterfaceTheme.Color.interactive)),
                                                     unfinished: ButtonStyle(buttonColor: UIColor.yellow,
                                                                             textStyle: TextStyle(font: InterfaceTheme.Font.body,
                                                                                                  color: InterfaceTheme.Color.interactive)))
    var tagStyle: ButtonStyle = ButtonStyle(buttonColor: InterfaceTheme.Color.descriptive,
                                            textStyle: TextStyle(font: InterfaceTheme.Font.footnote, color: InterfaceTheme.Color.interactive))
    
    var priorityStyle: PriorityStyle = PriorityStyle(a: ButtonStyle(buttonColor: UIColor.darkGray,
                                                                    textStyle: TextStyle(font: InterfaceTheme.Font.footnote,
                                                                                         color: InterfaceTheme.Color.interactive)),
                                                     b: ButtonStyle(buttonColor: UIColor.lightGray,
                                                                    textStyle: TextStyle(font: InterfaceTheme.Font.footnote,
                                                                                         color: InterfaceTheme.Color.interactive)),
                                                     c: ButtonStyle(buttonColor: UIColor.yellow,
                                                                    textStyle: TextStyle(font: InterfaceTheme.Font.footnote,
                                                                                         color: InterfaceTheme.Color.interactive)),
                                                     d: ButtonStyle(buttonColor: UIColor.blue,
                                                                    textStyle: TextStyle(font: InterfaceTheme.Font.footnote,
                                                                                         color: InterfaceTheme.Color.interactive)),
                                                     e: ButtonStyle(buttonColor: UIColor.purple,
                                                                    textStyle: TextStyle(font: InterfaceTheme.Font.footnote,
                                                                                         color: InterfaceTheme.Color.interactive)),
                                                     f: ButtonStyle(buttonColor: UIColor.red,
                                                                    textStyle: TextStyle(font: InterfaceTheme.Font.footnote,
                                                                                         color: InterfaceTheme.Color.interactive)))
}

public struct CodeBlockStyle {
    public let textStyle: TextStyle
    
    public var attributes: [NSAttributedString.Key: Any] {
        return textStyle.attributes
    }
}

public struct QuoteBlockStyle {
    public let textStyle: TextStyle
    
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
}

public struct TextMarkStyle {
    public let bold: TextStyle
    public let italic: TextStyle
    public let underscore: TextStyle
    public let strikethrought: TextStyle
    public let verbatim: TextStyle
    public let code: TextStyle
}

public struct TextStyle {
    public let font: UIFont
    public let color: UIColor
    
    public var attributes: [NSAttributedString.Key: Any] {
        return [NSAttributedString.Key.foregroundColor: self.color,
                NSAttributedString.Key.font: self.font]
    }
}

public struct ButtonStyle {
    public let buttonColor: UIColor
    public let textStyle: TextStyle
}
