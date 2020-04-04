//
//  UIView+Processing.swift
//  Business
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

private class ProcessingView: UIView {
    private let indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.white)

    public func start() {
        if indicator.superview == nil {
            self.addSubview(self.indicator)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.centerAnchors(position: [.centerX, .centerY], to: self)
        }
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        self.isUserInteractionEnabled = false
        
        indicator.startAnimating()
    }
}

extension UIView {
    public func showProcessingAnimation() {
        guard self.getPrecessingAnimationView() == nil else {
            return
        }
        
        let view = self.createProcessingAnimationView()
        self.addSubview(view)
        view.allSidesAnchors(to: self, edgeInset: 0)
        view.alpha = 0
        
        UIView.animate(withDuration: 0.1, animations: {
            view.alpha = 1
        }, completion: {
            if $0 {
                view.start()
            }
        })
    }
    
    public func hideProcessingAnimation() {
        if let view = self.getPrecessingAnimationView() {
            UIView.animate(withDuration: 0.1, animations: {
                view.alpha = 0
            }, completion: {
                if $0 {
                    view.removeFromSuperview()
                }
            })
        }
    }
    
    private func getPrecessingAnimationView() -> ProcessingView? {
        return self.subviews.filter { ($0 as? ProcessingView) != nil }.first as? ProcessingView
    }
    
    private func createProcessingAnimationView() -> ProcessingView {
        let view = ProcessingView()
        return view
    }
}
