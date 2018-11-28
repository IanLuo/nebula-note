//
//  OutlineTheme.swift
//  Iceland
//
//  Created by ian luo on 2018/11/22.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIFont

public struct ThemeConfig {
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

