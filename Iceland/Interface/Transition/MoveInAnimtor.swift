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
    }
    
    public var from: From = .bottom
    public var isPresenting: Bool
    
    required public init(isPresenting: Bool = true) {
        self.isPresenting = isPresenting
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containner = transitionContext.containerView
        guard let to = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else { return }
        guard let from = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else { return }
        
        if self.isPresenting {
            if let transitionViewController = to as? TransitionViewController {
                containner.addSubview(transitionViewController.view)
                transitionViewController.view.layoutIfNeeded()
                transitionViewController.didTransiteToShow()
                transitionViewController.view.backgroundColor = .clear
                transitionViewController.view.layoutIfNeeded()
                let toRect = transitionViewController.contentView.frame
                
                switch self.from {
                case .bottom:
                    transitionViewController.contentView.frame = CGRect(x: 0,
                                                                        y: transitionViewController.view.bounds.height,
                                                                        width: transitionViewController.contentView.bounds.width,
                                                                        height: transitionViewController.contentView.bounds.height)
                case .right:
                    transitionViewController.contentView.frame = CGRect(x: transitionViewController.view.bounds.width,
                                                                        y: toRect.origin.y,
                                                                        width: transitionViewController.contentView.bounds.width,
                                                                        height: transitionViewController.contentView.bounds.height)

                }
                
                UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0.0, options: .curveEaseInOut, animations: ({
                    transitionViewController.contentView.frame = toRect
                    transitionViewController.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                }), completion: { completeion in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                })
            } else {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            if let transitionViewController = from as? TransitionViewController {
                UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0, options: .curveEaseInOut, animations: ({
                    transitionViewController.view.backgroundColor = .clear
                    switch self.from {
                    case .bottom:
                        transitionViewController.contentView.frame = CGRect(x: 0,
                                                                            y: transitionViewController.view.bounds.height,
                                                                            width: transitionViewController.contentView.bounds.width,
                                                                            height: transitionViewController.contentView.bounds.height)
                    case .right:
                        transitionViewController.contentView.frame = CGRect(x: transitionViewController.view.bounds.width,
                                                                            y: 0,
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

