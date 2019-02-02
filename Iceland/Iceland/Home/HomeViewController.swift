//
//  HomeViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public class HomeViewController: UIViewController {
    internal var currentChildViewController: UIViewController?
    
    private let masterViewWidth: CGFloat = UIScreen.main.bounds.width * 3 / 4
    
    public var isShowingMaster: Bool = false
    
    public var masterViewController: UIViewController
    
    public override func viewDidLoad() {
        self.setupUI()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(didPan(gesture:)))
        pan.delegate = self
        self.view.addGestureRecognizer(pan)
    }
    
    public init(masterViewController: UIViewController) {
        self.masterViewController = masterViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private func setupUI() {
        self.view.addSubview(self.masterViewController.view)
        self.masterViewController.view.frame = CGRect(x: -masterViewWidth, y: 0, width: masterViewWidth, height: self.view.bounds.height)
        
        self.masterViewController.view.setBorder(position: Border.Position.right, color: InterfaceTheme.Color.background3, width: 0.5)
    }
    
    internal func showChildViewController(_ viewController: UIViewController) {
        if let current = self.currentChildViewController {
            current.removeFromParent()
            current.view.removeFromSuperview()
        }
        
        self.addChild(viewController)
        self.currentChildViewController = viewController
        self.view.insertSubview(viewController.view, at: 0)
    }
    
    private var beginPoint: CGPoint = .zero
    @objc private func didPan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.beginPoint = self.view.bounds.origin
            
            if !self.isShowingMaster {
                self.addCoverIfNeeded()
            }
        case .changed:
            let newLocation = self.beginPoint.x - gesture.translation(in: self.view!).x
            if newLocation < 0
            && newLocation > -masterViewWidth {
                self.view.bounds = CGRect(x: newLocation, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
            }
            self.updateCoverAlpha(offset: -newLocation)
        case .ended: fallthrough
        case .cancelled:
            if self.view.bounds.origin.x >= -self.masterViewWidth / 3
                || gesture.velocity(in: self.view!).x < -0.5 {
                self.showChildView()
                self.removeCover()
            } else {
                self.showMasterView()
            }
        default: break
        }
    }
    
    @objc internal func showChildView() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.view.bounds = CGRect(origin: .zero, size: self.view.bounds.size)
            self.updateCoverAlpha(offset: 0)
        }, completion: { _ in
            self.currentChildViewController?.becomeFirstResponder()
            self.isShowingMaster = false
        })
    }
    
    @objc private func showMasterView() {
        self.addCoverIfNeeded()
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.view.bounds = CGRect(origin: .init(x: -self.masterViewWidth, y: 0), size: self.view.bounds.size)
            self.updateCoverAlpha(offset: self.masterViewWidth)
        }, completion: { _ in
            self.currentChildViewController?.resignFirstResponder()
            self.isShowingMaster = true
        })
    }

    private lazy var cover: UIView = {
        let view = UIView()
        view.backgroundColor = InterfaceTheme.Color.background1
            .withAlphaComponent(0.7)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChildView)))
        return view
    }()
    
    private func addCoverIfNeeded() {
        if self.cover.superview == nil {
            self.view.addSubview(self.cover)
            self.cover.frame = self.view.bounds
            self.cover.alpha = 0
        }
    }
    
    private func updateCoverAlpha(offset: CGFloat) {
        let alphaComponent = offset / self.masterViewWidth
        self.cover.alpha = alphaComponent
    }
    
    private func removeCover() {
        self.cover.removeFromSuperview()
    }
}


extension HomeViewController: UIGestureRecognizerDelegate {
    
}
