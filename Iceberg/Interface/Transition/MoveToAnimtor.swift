//
//  MoveToAnimtor.swift
//  Business
//
//  Created by ian luo on 2019/2/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class MoveToAnimtor: NSObject, Animator {
    public var isPresenting: Bool
    
    required public init(isPresenting: Bool = true) {
        self.isPresenting = isPresenting
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containner = transitionContext.containerView
        guard let to = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else { return }
        guard let from = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else { return }
        
        
        if self.isPresenting {
            if let transitionViewController = to as? TransitionViewController {
                let fromView = transitionViewController.fromView
                
                containner.addSubview(transitionViewController.view)
                transitionViewController.view.frame = containner.bounds
                transitionViewController.view.layoutIfNeeded()
                transitionViewController.didTransiteToShow()
                transitionViewController.view.backgroundColor = .clear
                transitionViewController.view.layoutIfNeeded()
                let destRect = transitionViewController.contentView.frame
                // 如果没有设置显示位置的 UIView，使用屏幕正中心的点作为显示位置
                let startRect = fromView != nil ? fromView!.convert(fromView!.frame, to: from.view) : CGRect(origin: transitionViewController.view.center, size: .zero)
                let animatableView = UIImageView(frame: startRect)
                animatableView.contentMode = .center
                
                if !isMac && transitionViewController.contentView.bounds != CGRect.zero {
                    let toImage = transitionViewController.contentView.snapshot
                    animatableView.image = toImage
                }
                animatableView.clipsToBounds = true
                animatableView.alpha = 0
                
                containner.addSubview(animatableView)
                transitionViewController.contentView.alpha = 0
                transitionViewController.view.backgroundColor = UIColor.black.withAlphaComponent(0)
                
                UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0.0, options: .curveEaseInOut, animations: ({
                    animatableView.frame = destRect
                    animatableView.alpha = 1
                    transitionViewController.view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                }), completion: { completeion in
                    transitionViewController.contentView.alpha = 1
                    animatableView.removeFromSuperview()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                })
            } else {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            if let transitionViewController = from as? TransitionViewController {
                let toView = transitionViewController.fromView
                
                var fromImage: UIImage? = UIImage()
                if transitionViewController.contentView.bounds != CGRect.zero {
                    fromImage = transitionViewController.contentView.snapshot
                }
                
                transitionViewController.contentView.alpha = 0
                let startRect = transitionViewController.contentView.frame
                // 如果没有设置显示位置的 UIView，使用屏幕正中心的点作为显示位置
                var destRect = toView != nil ? toView!.convert(toView!.frame, to: from.view) : CGRect(origin: transitionViewController.view.center, size: .zero)
                
                // avoid the animation scale, looks bad
                if destRect.width > startRect.width || destRect.height > startRect.height {
                    destRect = startRect
                }
                
                let animatableView = UIImageView(frame: startRect)
                animatableView.backgroundColor = InterfaceTheme.Color.background2
                animatableView.clipsToBounds = true
                animatableView.image = fromImage
                
                
                containner.addSubview(animatableView)
                
                UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0, options: .curveEaseInOut, animations: ({
                    animatableView.frame = destRect
                    animatableView.alpha = 0
                    transitionViewController.view.backgroundColor = UIColor.black.withAlphaComponent(0)
                }), completion: { completeion in
                    animatableView.removeFromSuperview()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                })
            } else {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

