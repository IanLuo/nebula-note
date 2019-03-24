//
//  OutlineTheme.swift
//  Iceland
//
//  Created by ian luo on 2018/11/22.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol InterfaceThemeProtocol {
    var color: InterfaceThemeColorProtocol { get }
    var font: InterfaceThemeFontProtocol { get }
}

public protocol InterfaceThemeColorProtocol {
    var interactive: UIColor { get }
    var descriptive: UIColor { get }
    var descriptiveHighlighted: UIColor { get }
    var background1: UIColor { get }
    var background2: UIColor { get }
    var background3: UIColor { get }
    var spotlight: UIColor { get }
    var warning: UIColor { get }
}

public protocol InterfaceThemeFontProtocol {
    var largeTitle: UIFont { get }
    var title: UIFont { get }
    var subtitle: UIFont { get }
    var body: UIFont { get }
    var footnote: UIFont { get }
}

public struct DefaultInterfaceTheme: InterfaceThemeProtocol {
    public var color: InterfaceThemeColorProtocol = DefaultInterfaceColor()
    public var font: InterfaceThemeFontProtocol = DefaultInterfaceFont()
}

public struct DefaultInterfaceColor: InterfaceThemeColorProtocol {
    public let interactive: UIColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.00)
    public let descriptive: UIColor = UIColor(red:0.27, green:0.27, blue:0.27, alpha:1.00)
    public let descriptiveHighlighted: UIColor = UIColor(red:0.41, green:0.41, blue:0.41, alpha:1.00)
    public let background1: UIColor = UIColor(red:0.09, green:0.10, blue:0.11, alpha:1.00)
    public let background2: UIColor = UIColor(red:0.13, green:0.13, blue:0.15, alpha:1.00)
    public let background3: UIColor = UIColor(red:0.19, green:0.20, blue:0.26, alpha:1.00)
    public let spotlight: UIColor = UIColor(red:0.20, green:0.34, blue:0.97, alpha:1.00)
    public let warning: UIColor = UIColor(red:1.00, green:0.24, blue:0.51, alpha:1.00)
}

public struct DefaultInterfaceFont: InterfaceThemeFontProtocol {
    public let largeTitle: UIFont = UIFont.systemFont(ofSize: 40)
    public let title: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
    public let subtitle: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.subheadline)
    public let body: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
    public let footnote: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.footnote)
}

public class ThemeSelector {
    private static let _instance: ThemeSelector = ThemeSelector(theme: DefaultInterfaceTheme())
    fileprivate var currentTheme: InterfaceThemeProtocol
    
    private init(theme: InterfaceThemeProtocol) {
        self.currentTheme = theme
    }
    
    public static var shared: ThemeSelector {
        return _instance
    }
    
    public func changeTheme(_ theme: InterfaceThemeProtocol) {
        ThemeSelector.shared.currentTheme = theme
    }
}

public struct InterfaceTheme {
    public static var Color: InterfaceThemeColorProtocol {
        return ThemeSelector.shared.currentTheme.color
    }
    
    public static var Font: InterfaceThemeFontProtocol {
        return ThemeSelector.shared.currentTheme.font
    }
}

public struct Layout {
    public static let edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 30, left: 30, bottom: 80, right: 30)
    public static let innerViewEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
    public static let backButtonSize: CGSize = CGSize(width: 40, height: 40)
}


private struct OutlineThemeConfig {
    private static let data: [String: AnyObject] = defaultTheme
    public static var shared: [String: AnyObject] { return OutlineThemeConfig.data }
    
    private static let defaultTheme: [String: AnyObject] = [
        "FONT": UIFont.preferredFont(forTextStyle: .body),
        "BOLD": UIFont.boldSystemFont(ofSize: 14),
        "ITALIC": UIFont.italicSystemFont(ofSize: 14),
        "UNDERSCORE": NSNumber(value: 1),
        "STRIKETHOUGH": NSNumber(value: 1),
        "VERBATIM": UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title1),
        "CODE": UIColor.gray
    ]
}


@objc public class OutlineTheme: NSObject {
    @objc public class Attributes: NSObject {
        @objc public static let bold = [NSAttributedString.Key.font: OutlineThemeConfig.shared["FONT"]!]
        
        @objc public class TextMark: NSObject {
            @objc public static let bold = [NSAttributedString.Key.font: OutlineThemeConfig.shared["BOLD"]!]
            @objc public static let italic = [NSAttributedString.Key.font: OutlineThemeConfig.shared["ITALIC"]!]
            @objc public static let underscore = [NSAttributedString.Key.underlineStyle: OutlineThemeConfig.shared["UNDERSCORE"]!]
            @objc public static let strikeThough = [NSAttributedString.Key.strikethroughStyle: OutlineThemeConfig.shared["STRIKETHOUGH"]!]
            @objc public static let verbatim = [NSAttributedString.Key.font: OutlineThemeConfig.shared["VERBATIM"]!]
            @objc public static let code = [NSAttributedString.Key.backgroundColor: OutlineThemeConfig.shared["CODE"]!]
        }
    }
}
