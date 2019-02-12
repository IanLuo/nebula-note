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
    public static let edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 80, left: 30, bottom: 80, right: 30)
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
        @objc public static let interactive: UIColor = .white
        @objc public static let descriptive: UIColor = UIColor(red:0.29, green:0.29, blue:0.29, alpha:1.00)
        @objc public static let enphersizedDescriptive: UIColor = UIColor(red:0.39, green:0.39, blue:0.39, alpha:1.00)
        @objc public static let spotLight: UIColor = UIColor(red:0.32, green:0.87, blue:0.73, alpha:1.00)
        @objc public static let background1: UIColor = UIColor(red:0.03, green:0.03, blue:0.03, alpha:1.00)
        @objc public static let background2: UIColor = UIColor(red:0.12, green:0.12, blue:0.12, alpha:1.00)
        @objc public static let background3: UIColor = UIColor(red:0.20, green:0.21, blue:0.22, alpha:1.00)
        @objc public static let backgroundHighlight: UIColor = UIColor(red:0.21, green:0.51, blue:0.44, alpha:1.00)
        @objc public static let backgroundWarning: UIColor = UIColor(red:0.51, green:0.13, blue:0.17, alpha:1.00)
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

extension UIColor {
    public class func hexString(_ hexString: String) -> UIColor? {
        if hexString.count > 7 || hexString.count < 7 {
            return nil
        } else {
            
            let hexInt = Int(hexString.substring(from: hexString.index(hexString.startIndex, offsetBy: 1)), radix: 16)
            if let hex = hexInt {
                let components = (
                    R: CGFloat((hex >> 16) & 0xff) / 255,
                    G: CGFloat((hex >> 08) & 0xff) / 255,
                    B: CGFloat((hex >> 00) & 0xff) / 255
                )
                return UIColor(red: components.R, green: components.G, blue: components.B, alpha: 1)
            } else {
                return nil
            }
        }
    }
}
