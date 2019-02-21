//
//  FadeBackgroundTransition.swift
//  Business
//
//  Created by ian luo on 2019/2/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

// MARK: - transition
public class FadeBackgroundTransition: NSObject, UIViewControllerTransitioningDelegate {
    public init(animator: Animator) {
        self.animator = animator
    }
    
    private var animator: Animator

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.animator.isPresenting = false
        return self.animator
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.animator.isPresenting = true
        return self.animator
    }
}
