//
//  FadeBackgroundAnimtor.swift
//  Business
//
//  Created by ian luo on 2019/2/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class MoveInAnimtor: NSObject, Animator {
    public enum From {
        case bottom
        case right
        case top
    }
    
    public var from: From = .bottom
    public var isPresenting: Bool
    
    required public init(isPresenting: Bool = true) {
        self.isPresenting = isPresenting
    }
    
    public convenience init(from: From) {
        self.init()
        self.from = from
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
                containner.addSubview(transitionViewController.view)
                transitionViewController.view.frame = containner.bounds
                transitionViewController.view.layoutIfNeeded()
                transitionViewController.didTransiteToShow()
                transitionViewController.view.backgroundColor = .clear
                transitionViewController.view.layoutIfNeeded()
                let toRect = transitionViewController.contentView.frame
                
                switch self.from {
                case .bottom:
                    transitionViewController.contentView.frame = CGRect(x: transitionViewController.contentView.frame.origin.x,
                                                                        y: transitionViewController.view.bounds.height,
                                                                        width: transitionViewController.contentView.bounds.width,
                                                                        height: transitionViewController.contentView.bounds.height)
                case .right:
                    transitionViewController.contentView.frame = CGRect(x: transitionViewController.view.bounds.width,
                                                                        y: toRect.origin.y,
                                                                        width: transitionViewController.contentView.bounds.width,
                                                                        height: transitionViewController.contentView.bounds.height)

                case .top:
                    transitionViewController.contentView.frame = CGRect(x: transitionViewController.contentView.frame.origin.x,
                                                                        y: -toRect.height,
                                                                        width: transitionViewController.contentView.bounds.width,
                                                                        height: transitionViewController.contentView.bounds.height)
                }
                
                UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0.0, options: .curveEaseInOut, animations: ({
                    transitionViewController.contentView.frame = toRect
                    transitionViewController.view.backgroundColor = InterfaceTheme.Color.interactive.withAlphaComponent(0.1)
                }), completion: { completeion in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                })
            } else {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            if let transitionViewController = from as? TransitionViewController {
                // create an image view to show animation
                let animatingImageView = UIImageView(frame: transitionViewController.contentView.frame)
                animatingImageView.image = transitionViewController.contentView.snapshot
                containner.addSubview(animatingImageView)
                
                // hide the real content view which will not be animated, because with autolayout, animation won't work very well
                transitionViewController.contentView.alpha = 0.0
                
                UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0, options: .curveEaseInOut, animations: ({
                    transitionViewController.view.backgroundColor = .clear
                    switch self.from {
                    case .bottom:
                        animatingImageView.frame = CGRect(x: transitionViewController.contentView.frame.origin.x,
                                                          y: transitionViewController.view.bounds.height,
                                                          width: transitionViewController.contentView.bounds.width,
                                                          height: transitionViewController.contentView.bounds.height)
                    case .right:
                        animatingImageView.frame = CGRect(x: transitionViewController.view.bounds.width,
                                                          y: transitionViewController.contentView.frame.origin.y,
                                                          width: transitionViewController.contentView.bounds.width,
                                                          height: transitionViewController.contentView.bounds.height)
                    case .top:
                        animatingImageView.frame = CGRect(x: transitionViewController.contentView.frame.origin.x,
                                                          y: -transitionViewController.contentView.bounds.height,
                                                          width: transitionViewController.contentView.bounds.width,
                                                          height: transitionViewController.contentView.bounds.height)
                    }
                }), completion: { completeion in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                })
            } else {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

