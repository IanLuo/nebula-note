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
    private static let data: [String: Any] = defaultTheme
    public static var shared: [String: Any] { return ThemeConfig.data }
    
    private static let defaultTheme: [String: Any] = [
        "FONT": UIFont.preferredFont(forTextStyle: .body),
        OutlineParser.Key.Element.TextMark.bold: UIFont.boldSystemFont(ofSize: 14),
        OutlineParser.Key.Element.TextMark.italic: UIFont.italicSystemFont(ofSize: 14),
        OutlineParser.Key.Element.TextMark.underscore: 1,
        OutlineParser.Key.Element.TextMark.strikeThough: 1,
        OutlineParser.Key.Element.TextMark.verbatim: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title1),
        OutlineParser.Key.Element.TextMark.code: UIColor.gray
    ]
}

public struct InterfaceTheme {
    public struct Font {
        public static let largeTitle: UIFont = UIFont.systemFont(ofSize: 40)
        public static let title: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
        public static let subTitle: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.subheadline)
        public static let body: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
        public static let footnote: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.footnote)
    }
    
    public struct Color {
        public static let interactive: UIColor = .white
        public static let descriptive: UIColor = .gray
        public static let enphersizedDescriptive: UIColor = .lightGray
        public static let spotLight: UIColor = .green
        public static let background1: UIColor = .black
        public static let background2: UIColor = UIColor(red:0.12, green:0.12, blue:0.12, alpha:1.00)
        public static let background3: UIColor = UIColor(red:0.18, green:0.18, blue:0.18, alpha:1.00)
        public static let backgroundHighlight: UIColor = UIColor(red:0.13, green:0.82, blue:0.41, alpha:1.00)
        public static let backgroundWarning: UIColor = UIColor(red:0.99, green:0.20, blue:0.44, alpha:1.00)
    }
}

public struct OutlineTheme {
    public struct Attributes {
        public static let bold = [NSAttributedString.Key.font: ThemeConfig.shared["FONT"]]
        public struct TextMark {
            public static let bold = [NSAttributedString.Key.font: ThemeConfig.shared[OutlineParser.Key.Element.TextMark.bold]!]
            public static let italic = [NSAttributedString.Key.font: ThemeConfig.shared[OutlineParser.Key.Element.TextMark.italic]!]
            public static let underscore = [NSAttributedString.Key.underlineStyle: ThemeConfig.shared[OutlineParser.Key.Element.TextMark.underscore]!]
            public static let strikeThough = [NSAttributedString.Key.strikethroughStyle: ThemeConfig.shared[OutlineParser.Key.Element.TextMark.strikeThough]!]
            public static let verbatim = [NSAttributedString.Key.font: ThemeConfig.shared[OutlineParser.Key.Element.TextMark.verbatim]!]
            public static let code = [NSAttributedString.Key.backgroundColor: ThemeConfig.shared[OutlineParser.Key.Element.TextMark.code]!]
        }
    }
}

