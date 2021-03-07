//
//  InterfaceTheme.swift
//  Interface
//
//  Created by ian luo on 2019/5/22.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import JAMSVGImage

public struct Layout {
    public static let cornerRadius: CGFloat = 8
    public static let edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
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
    @objc var secondaryDescriptive: UIColor { get }
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
    @objc var italic: UIFont { get }
    @objc var callout: UIFont { get }
    @objc var caption1: UIFont { get }
    @objc var caption2: UIFont { get }
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
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }
}

@objc public class LightInterfaceColor: NSObject, InterfaceThemeColorProtocol {
    @objc public var spotlitTitle: UIColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.00)
    @objc public var level: UIColor = UIColor(88, 86, 214)
    @objc public var finished: UIColor = UIColor(52, 199, 89)
    @objc public var unfinished: UIColor = UIColor(red:0.87, green:0.69, blue:0.15, alpha:1.00)
    
    @objc public let interactive: UIColor = UIColor(82, 81, 82)
    @objc public let descriptive: UIColor = UIColor(112, 109, 107)
    @objc public let secondaryDescriptive: UIColor = UIColor(183, 181, 178)
    @objc public let background1: UIColor = UIColor(249, 248, 246)
    @objc public let background2: UIColor = UIColor(237, 233, 229)
    @objc public let background3: UIColor = UIColor(220, 215, 214)
    @objc public let spotlight: UIColor = UIColor(199, 173, 124)
    @objc public let warning: UIColor = UIColor(194, 81, 76)
}

@objc public class DarkInterfaceColor: NSObject, InterfaceThemeColorProtocol {
    @objc public var spotlitTitle: UIColor = UIColor(87, 84, 83)
    @objc public var level: UIColor = UIColor(10, 132, 255)
    @objc public var finished: UIColor = UIColor(148, 201, 113)
    @objc public var unfinished: UIColor = UIColor(red:1.00, green:0.77, blue:0.25, alpha:1.00)
    
    @objc public let interactive: UIColor = UIColor(242, 242, 247)
    @objc public let descriptive: UIColor = UIColor(145, 145, 146)
    @objc public let secondaryDescriptive: UIColor = UIColor(124, 124, 123)
    @objc public let background1: UIColor = UIColor(55, 54, 53)
    @objc public let background2: UIColor = UIColor(63, 61, 60)
    @objc public let background3: UIColor = UIColor(81, 80, 75)
    @objc public let spotlight: UIColor = UIColor(199, 173, 124)
    @objc public let warning: UIColor = UIColor(194, 81, 76)
}

@objc public class DefaultInterfaceFont: NSObject, InterfaceThemeFontProtocol {
    public var caption1: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption1)
    
    public var caption2: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption2)
    
    public var callout: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.callout)
    
    public var italic: UIFont = UIFont.italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body).pointSize)
    public let largeTitle: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title1)
    public let title: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
    public let subtitle: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.subheadline)
    public let body: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
    public let footnote: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.footnote)
}

public class InterfaceThemeSelector {
    private static let _instance: InterfaceThemeSelector =  {
        return InterfaceThemeSelector(theme: DarkInterfaceTheme())
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
        
        self._themeObservable.onNext(theme)
    }
    
    public func register(observer key: NSObject, changeAction: @escaping (InterfaceThemeProtocol) -> Void) {
//        self._registerMap.setObject(changeAction as AnyObject, forKey: key)

        _ = self._themeObservable.takeUntil(key.rx.deallocated).subscribe(onNext: { theme in
            changeAction(theme)
        })
        
        changeAction(self.currentTheme)
    }
    
    fileprivate let _themeObservable: PublishSubject<InterfaceThemeProtocol> = PublishSubject()
}

@objc public class InterfaceTheme: NSObject {
    @objc public static var isDartMode: Bool {
        return InterfaceThemeSelector.shared.currentTheme is DarkInterfaceTheme
    }
    
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
    @discardableResult
    public func interface(_ action: @escaping (UIViewController, InterfaceThemeProtocol) -> Void) -> Self {
        InterfaceThemeSelector.shared.register(observer: self) { [unowned self] theme in
            action(self, theme)
        }
        
        return self
    }
}

extension UIView {
    @discardableResult
    public func interface(_ action: @escaping (UIView, InterfaceThemeProtocol) -> Void) -> Self {
        InterfaceThemeSelector.shared.register(observer: self) { [unowned self] theme in
            action(self, theme)
        }
        
        return self
    }
}

extension UIColor {
    public convenience init(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
    }
}
