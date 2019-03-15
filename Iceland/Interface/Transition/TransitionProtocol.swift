//
//  TransitionProtocol.swift
//  Business
//
//  Created by ian luo on 2019/2/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public typealias TransitionViewController = UIViewController & TransitionProtocol

public typealias Animator = UIViewControllerAnimatedTransitioning & AnimatorProtocol

public protocol TransitionProtocol {
    var contentView: UIView { get }
    var fromView: UIView? { get set }
    
    func didTransiteToShow()
}

// 显示 navigation controller 的时候，使用第一个 viewController 的 transition delegate
extension UINavigationController: TransitionProtocol {
    public var contentView: UIView {
        if let rootViewController = self.topViewController as? TransitionProtocol {
            return rootViewController.contentView
        } else {
            return self.topViewController?.view ?? self.view
        }
    }
    
    public var fromView: UIView? {
        get {
            if let rootViewController = self.topViewController as? TransitionProtocol {
                return rootViewController.fromView
            } else {
                return nil
            }
        }
        
        set {
            if var rootViewController = self.topViewController as? TransitionProtocol {
                 rootViewController.fromView = newValue
            }
        }
    }
}

extension TransitionProtocol {
    public func didTransiteToShow() {}
}

public protocol AnimatorProtocol {
    init(isPresenting: Bool)
    var isPresenting: Bool { get set }
}
