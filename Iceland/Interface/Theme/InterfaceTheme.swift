//
//  InterfaceTheme.swift
//  Interface
//
//  Created by ian luo on 2019/5/22.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public struct Layout {
    public static let edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
    public static let innerViewEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
    public static let backButtonSize: CGSize = CGSize(width: 40, height: 40)
}

@objc public protocol InterfaceThemeProtocol: class {
    @objc var color: InterfaceThemeColorProtocol { get }
    @objc var font: InterfaceThemeFontProtocol { get }
    @objc var statusBarStyle: UIStatusBarStyle { get }
}

@objc public protocol InterfaceThemeColorProtocol: class {
    @objc var interactive: UIColor { get }
    @objc var descriptive: UIColor { get }
    @objc var descriptiveHighlighted: UIColor { get }
    @objc var background1: UIColor { get }
    @objc var background2: UIColor { get }
    @objc var background3: UIColor { get }
    @objc var spotlight: UIColor { get }
    @objc var warning: UIColor { get }
    
    @objc var finished: UIColor { get }
    @objc var unfinished: UIColor { get }
    @objc var level: UIColor { get }
    @objc var spotlitTitle: UIColor { get }
}

@objc public protocol InterfaceThemeFontProtocol: class {
    @objc var largeTitle: UIFont { get }
    @objc var title: UIFont { get }
    @objc var subtitle: UIFont { get }
    @objc var body: UIFont { get }
    @objc var footnote: UIFont { get }
}

@objc public class DarkInterfaceTheme: NSObject, InterfaceThemeProtocol {
    @objc public var color: InterfaceThemeColorProtocol = DarkInterfaceColor()
    @objc public var font: InterfaceThemeFontProtocol = DefaultInterfaceFont()
    @objc public var statusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

@objc public class LightInterfaceTheme: NSObject, InterfaceThemeProtocol {
    @objc public var color: InterfaceThemeColorProtocol = LightInterfaceColor()
    @objc public var font: InterfaceThemeFontProtocol = DefaultInterfaceFont()
    @objc public var statusBarStyle: UIStatusBarStyle {
        return .default
    }
}

@objc public class LightInterfaceColor: NSObject, InterfaceThemeColorProtocol {
    @objc public var spotlitTitle: UIColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.00)
    @objc public var level: UIColor = UIColor(red:0.08, green:0.49, blue:0.98, alpha:1.00)
    @objc public var finished: UIColor = UIColor(red:0.14, green:0.87, blue:0.41, alpha:1.00)
    @objc public var unfinished: UIColor = UIColor(red:0.94, green:0.64, blue:0.28, alpha:1.00)
    
    @objc public let interactive: UIColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:1.00)
    @objc public let descriptive: UIColor = UIColor(red:0.58, green:0.58, blue:0.58, alpha:1.00)
    @objc public let descriptiveHighlighted: UIColor = UIColor(red:0.58, green:0.58, blue:0.58, alpha:1.00)
    @objc public let background1: UIColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.00)
    @objc public let background2: UIColor = UIColor(red:0.95, green:0.95, blue:0.96, alpha:1.00)
    @objc public let background3: UIColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.00)
    @objc public let spotlight: UIColor = UIColor(red:0.08, green:0.49, blue:0.98, alpha:1.00)
    @objc public let warning: UIColor = UIColor(red:0.99, green:0.24, blue:0.22, alpha:1.00)
}

@objc public class DarkInterfaceColor: NSObject, InterfaceThemeColorProtocol {
    @objc public var spotlitTitle: UIColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.00)
    @objc public var level: UIColor = UIColor(red:0.08, green:0.49, blue:0.98, alpha:1.00)
    @objc public var finished: UIColor = UIColor(red:0.14, green:0.87, blue:0.41, alpha:1.00)
    @objc public var unfinished: UIColor = UIColor(red:0.94, green:0.64, blue:0.28, alpha:1.00)
    
    @objc public let interactive: UIColor = UIColor(red:0.97, green:0.97, blue:0.97, alpha:1.00)
    @objc public let descriptive: UIColor = UIColor(red:0.27, green:0.27, blue:0.27, alpha:1.00)
    @objc public let descriptiveHighlighted: UIColor = UIColor(red:0.41, green:0.41, blue:0.41, alpha:1.00)
    @objc public let background1: UIColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:1.00)
    @objc public let background2: UIColor = UIColor(red:0.11, green:0.11, blue:0.12, alpha:1.00)
    @objc public let background3: UIColor = UIColor(red:0.22, green:0.22, blue:0.22, alpha:1.00)
    @objc public let spotlight: UIColor = UIColor(red:0.08, green:0.49, blue:0.98, alpha:1.00)
    @objc public let warning: UIColor = UIColor(red:0.99, green:0.24, blue:0.22, alpha:1.00)
}

@objc public class DefaultInterfaceFont: NSObject, InterfaceThemeFontProtocol {
    public let largeTitle: UIFont = UIFont.systemFont(ofSize: 40)
    public let title: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
    public let subtitle: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.subheadline)
    public let body: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
    public let footnote: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.footnote)
}

public class InterfaceThemeSelector {
    private static let _instance: InterfaceThemeSelector =  {
        return InterfaceThemeSelector(theme: LightInterfaceTheme())
    }()
    
    private let _registerMap: NSMapTable<AnyObject, AnyObject> = NSMapTable.weakToStrongObjects()
    
    fileprivate var currentTheme: InterfaceThemeProtocol
    
    private init(theme: InterfaceThemeProtocol) {
        self.currentTheme = theme
    }
    
    public static var shared: InterfaceThemeSelector {
        return _instance
    }
    
    public func changeTheme(_ theme: InterfaceThemeProtocol) {
        InterfaceThemeSelector.shared.currentTheme = theme
        
        for key in self._registerMap.keyEnumerator().allObjects {
            (self._registerMap.object(forKey: key as AnyObject) as? (InterfaceThemeProtocol) -> Void)?(theme)
        }
    }
    
    public func register(observer key: AnyObject, changeAction: @escaping (InterfaceThemeProtocol) -> Void) {
        self._registerMap.setObject(changeAction as AnyObject, forKey: key)
        
        changeAction(self.currentTheme)
    }
}

@objc public class InterfaceTheme: NSObject {
    @objc public static var Color: InterfaceThemeColorProtocol {
        return InterfaceThemeSelector.shared.currentTheme.color
    }
    
    @objc public static var Font: InterfaceThemeFontProtocol {
        return InterfaceThemeSelector.shared.currentTheme.font
    }
    
    @objc public static var statusBarStyle: UIStatusBarStyle {
        return InterfaceThemeSelector.shared.currentTheme.statusBarStyle
    }
}

extension UIViewController {
    public func interface(_ action: @escaping (UIViewController, InterfaceThemeProtocol) -> Void) {
        InterfaceThemeSelector.shared.register(observer: self) { [unowned self] theme in
            action(self, theme)
        }
    }
}

extension UIView {
    public func interface(_ action: @escaping (UIView, InterfaceThemeProtocol) -> Void) {
        InterfaceThemeSelector.shared.register(observer: self) { [unowned self] theme in
            action(self, theme)
        }
    }
}
