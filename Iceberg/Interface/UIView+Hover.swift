//
//  UIButton+Hover.swift
//  Interface
//
//  Created by ian luo on 2021/1/9.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

private var disposeBagKey: Void?

extension UIButton {
    public func enableHover(callback: @escaping (Bool) -> Void) {
        if #available(iOS 13, *) {
            let hover = UIHoverGestureRecognizer()
            hover.rx.event.subscribe(onNext: { event in
                switch event.state {
                case .began, .changed:
                    callback(true)
                default:
                    callback(false)
                }
            }).disposed(by: super.disposeBag)
            self.addGestureRecognizer(hover)
        }
    }
}

extension UIView {
    fileprivate var disposeBag: DisposeBag {
        get {
            if let bag = objc_getAssociatedObject(self, &disposeBagKey) as? DisposeBag {
                return bag
            } else {
                let bag = DisposeBag()
                objc_setAssociatedObject(self, &disposeBagKey, bag, .OBJC_ASSOCIATION_RETAIN)
                return bag
            }
        }
    }
    
    public func enableHover(on view: UIView, hoverColor: UIColor = InterfaceTheme.Color.background3) {
        class Background: UIView {
            convenience init(hoverColor: UIColor) {
                self.init(frame: .zero)
                self.backgroundColor = hoverColor
            }
        }
        
        let hoverBackgroundView: () -> UIView? = {
            return view.subviews.filter { $0 is Background }.first
        }
        
        if #available(iOS 13, *) {
            let hover = UIHoverGestureRecognizer()
            hover.rx.event.subscribe(onNext: { event in
                switch event.state {
                case .began, .changed:
                    if hoverBackgroundView() == nil {
                        let background = Background(hoverColor: hoverColor)
                        view.insertSubview(background, at: 0)
                        background.allSidesAnchors(to: view, edgeInset: 0)
                    }
                default:
                    if let hoverView = hoverBackgroundView() {
                        hoverView.removeFromSuperview()
                    }
                }
        }).disposed(by: disposeBag)
            self.addGestureRecognizer(hover)
        }
    }
}
