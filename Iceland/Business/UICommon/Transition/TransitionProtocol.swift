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
    var fromView: UIView? { get }
    
    func didTransiteToShow()
}

extension TransitionProtocol {
    public func didTransiteToShow() {}
}

public protocol AnimatorProtocol {
    init(isPresenting: Bool)
    var isPresenting: Bool { get set }
}
