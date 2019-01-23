//
//  OutlineTheme.swift
//  Iceland
//
//  Created by ian luo on 2018/11/22.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIFont

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

@objc public class InterfaceTheme: NSObject {
    @objc public class Font: NSObject {
        @objc public static let largeTitle: UIFont = UIFont.systemFont(ofSize: 40)
        @objc public static let title: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
        @objc public static let subTitle: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.subheadline)
        @objc public static let body: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
        @objc public static let footnote: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.footnote)
    }
    
    @objc public class Color: NSObject {
        @objc public static let interactive: UIColor = .white
        @objc public static let descriptive: UIColor = .darkGray
        @objc public static let enphersizedDescriptive: UIColor = .lightGray
        @objc public static let spotLight: UIColor = UIColor(red:0.13, green:0.82, blue:0.41, alpha:1.00)
        @objc public static let background1: UIColor = .black
        @objc public static let background2: UIColor = UIColor(red:0.12, green:0.12, blue:0.12, alpha:1.00)
        @objc public static let background3: UIColor = UIColor(red:0.18, green:0.18, blue:0.18, alpha:1.00)
        @objc public static let backgroundHighlight: UIColor = UIColor(red:0.13, green:0.82, blue:0.41, alpha:1.00)
        @objc public static let backgroundWarning: UIColor = UIColor(red:0.99, green:0.20, blue:0.44, alpha:1.00)
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

