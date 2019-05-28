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

public protocol InterfaceThemeProtocol {
    var color: InterfaceThemeColorProtocol { get }
    var font: InterfaceThemeFontProtocol { get }
    var statusBarStyle: UIStatusBarStyle { get }
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

public struct DarkInterfaceTheme: InterfaceThemeProtocol {
    public init(){}
    public var color: InterfaceThemeColorProtocol = DarkInterfaceColor()
    public var font: InterfaceThemeFontProtocol = DefaultInterfaceFont()
    public var statusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

public struct LightInterfaceTheme: InterfaceThemeProtocol {
    public init(){}
    public var color: InterfaceThemeColorProtocol = LightInterfaceColor()
    public var font: InterfaceThemeFontProtocol = DefaultInterfaceFont()
    public var statusBarStyle: UIStatusBarStyle {
        return .default
    }
}

public struct LightInterfaceColor: InterfaceThemeColorProtocol {
    public let interactive: UIColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.00)
    public let descriptive: UIColor = UIColor(red:0.61, green:0.61, blue:0.61, alpha:1.00)
    public let descriptiveHighlighted: UIColor = UIColor(red:0.71, green:0.71, blue:0.71, alpha:1.00)
    public let background1: UIColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.00)
    public let background2: UIColor = UIColor(red:0.96, green:0.96, blue:0.96, alpha:1.00)
    public let background3: UIColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.00)
    public let spotlight: UIColor = UIColor(red:0.08, green:0.49, blue:0.98, alpha:1.00)
    public let warning: UIColor = UIColor(red:0.98, green:0.39, blue:0.41, alpha:1.00)
}

public struct DarkInterfaceColor: InterfaceThemeColorProtocol {
    public let interactive: UIColor = UIColor(red:0.97, green:0.97, blue:0.97, alpha:1.00)
    public let descriptive: UIColor = UIColor(red:0.27, green:0.27, blue:0.27, alpha:1.00)
    public let descriptiveHighlighted: UIColor = UIColor(red:0.41, green:0.41, blue:0.41, alpha:1.00)
    public let background1: UIColor = UIColor(red:0.13, green:0.12, blue:0.13, alpha:1.00)
    public let background2: UIColor = UIColor(red:0.18, green:0.17, blue:0.18, alpha:1.00)
    public let background3: UIColor = UIColor(red:0.29, green:0.29, blue:0.29, alpha:1.00)
    public let spotlight: UIColor = UIColor(red:0.08, green:0.49, blue:0.98, alpha:1.00)
    public let warning: UIColor = UIColor(red:0.98, green:0.39, blue:0.41, alpha:1.00)
}

public struct DefaultInterfaceFont: InterfaceThemeFontProtocol {
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

public struct InterfaceTheme {
    public static var Color: InterfaceThemeColorProtocol {
        return InterfaceThemeSelector.shared.currentTheme.color
    }
    
    public static var Font: InterfaceThemeFontProtocol {
        return InterfaceThemeSelector.shared.currentTheme.font
    }
    
    public static var statusBarStyle: UIStatusBarStyle {
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
