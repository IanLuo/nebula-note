//
//  OutlineTheme.swift
//  Iceland
//
//  Created by ian luo on 2018/11/22.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

private struct ThemeConfig {
    private static let data: [String: AnyObject] = defaultTheme
    public static var shared: [String: AnyObject] { return ThemeConfig.data }
    
    private static let defaultTheme: [String: AnyObject] = [
        "FONT": UIFont.preferredFont(forTextStyle: .body),
        OutlineParser.Key.Element.TextMark.bold: UIFont.boldSystemFont(ofSize: 14),
        OutlineParser.Key.Element.TextMark.italic: UIFont.italicSystemFont(ofSize: 14),
        OutlineParser.Key.Element.TextMark.underscore: NSNumber(value: 1),
        OutlineParser.Key.Element.TextMark.strikeThough: NSNumber(value: 1),
        OutlineParser.Key.Element.TextMark.verbatim: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title1),
        OutlineParser.Key.Element.TextMark.code: UIColor.gray
    ]
}

public struct Layout {
    public static let edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 30, left: 30, bottom: 80, right: 30)
    public static let backButtonSize: CGSize = CGSize(width: 40, height: 40)
}

@objc public class InterfaceTheme: NSObject {
    @objc public class Font: NSObject {
        @objc public static let largeTitle: UIFont = UIFont.systemFont(ofSize: 40)
        @objc public static let title: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
        @objc public static let subTitle: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.subheadline)
        @objc public static let body: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
        @objc public static let footnote: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.footnote)
    }
    
    @objc public class Color: NSObject {
        @objc public static let interactive: UIColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.00)
        @objc public static let descriptive: UIColor = UIColor(red:0.27, green:0.27, blue:0.27, alpha:1.00)
        @objc public static let enphersizedDescriptive: UIColor = UIColor(red:0.41, green:0.41, blue:0.41, alpha:1.00)
        @objc public static let spotLight: UIColor = UIColor(red:0.07, green:0.37, blue:0.98, alpha:1.00)
        @objc public static let background1: UIColor = UIColor(red:0.09, green:0.09, blue:0.09, alpha:1.00)
        @objc public static let background2: UIColor = UIColor(red:0.12, green:0.12, blue:0.12, alpha:1.00)
        @objc public static let background3: UIColor = UIColor(red:0.19, green:0.20, blue:0.26, alpha:1.00)
        @objc public static let backgroundHighlight: UIColor = UIColor(red:0.29, green:0.59, blue:0.98, alpha:1.00)
        @objc public static let backgroundWarning: UIColor = UIColor(red:1.00, green:0.13, blue:0.10, alpha:1.00)
    }
}

@objc public class OutlineTheme: NSObject {
    @objc public class Attributes: NSObject {
        @objc public static let bold = [NSAttributedString.Key.font: ThemeConfig.shared["FONT"]!]
        
        @objc public class TextMark: NSObject {
            @objc public static let bold = [NSAttributedString.Key.font: ThemeConfig.shared[OutlineParser.Key.Element.TextMark.bold]!]
            @objc public static let italic = [NSAttributedString.Key.font: ThemeConfig.shared[OutlineParser.Key.Element.TextMark.italic]!]
            @objc public static let underscore = [NSAttributedString.Key.underlineStyle: ThemeConfig.shared[OutlineParser.Key.Element.TextMark.underscore]!]
            @objc public static let strikeThough = [NSAttributedString.Key.strikethroughStyle: ThemeConfig.shared[OutlineParser.Key.Element.TextMark.strikeThough]!]
            @objc public static let verbatim = [NSAttributedString.Key.font: ThemeConfig.shared[OutlineParser.Key.Element.TextMark.verbatim]!]
            @objc public static let code = [NSAttributedString.Key.backgroundColor: ThemeConfig.shared[OutlineParser.Key.Element.TextMark.code]!]
        }
    }
}
