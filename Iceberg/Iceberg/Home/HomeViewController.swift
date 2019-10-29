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
import Interface

public protocol HomeViewControllerDelegate: class {
    func didShowMasterView()
    func didShowDetailView()
}

public class HomeViewController: UIViewController {
    internal var currentDetailViewController: UIViewController?
    
    private let masterViewWidth: CGFloat = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 3 / 4
    
    public var isShowingMaster: Bool = false {
        didSet {
            if isShowingMaster {
                self.delegate?.didShowMasterView()
            } else {
                self.delegate?.didShowDetailView()
            }
        }
    }
    
    public var masterViewController: UIViewController
    
    public weak var delegate: HomeViewControllerDelegate?
    
    private lazy var pan = UIPanGestureRecognizer(target: self, action: #selector(didPan(gesture:)))
    private lazy var tap = UITapGestureRecognizer(target: self, action: #selector(didTap(gesture:)))
    
    private let moveIndicator: UIView = {
        let view = UIView()
        view.sizeAnchor(width: 10, height: 50)
        view.roundConer(radius: 5)

        return view
    }()
    
    public override func viewDidLoad() {
        self.setupUI()

        pan.delegate = self
        self.view.addGestureRecognizer(pan)
        
        
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        self.interface { [weak self] (me, theme) in
            me.setNeedsStatusBarAppearanceUpdate()
            self?.moveIndicator.backgroundColor = theme.color.background2
        }
    }
    
    public init(masterViewController: UIViewController) {
        self.masterViewController = masterViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.masterViewController.view.frame = CGRect(x: -self.masterViewWidth, y: 0, width: self.masterViewWidth, height: self.view.bounds.height)
        self.currentDetailViewController?.view.frame = CGRect(origin: .zero, size: self.view.bounds.size)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return InterfaceTheme.statusBarStyle
    }
    
    private func setupUI() {
        self.view.addSubview(self.masterViewController.view)
        self._setupFrames()
        
        self.view.addSubview(self.moveIndicator)
        self.moveIndicator.centerAnchors(position: .centerY, to: self.view)
        self.moveIndicator.centerXAnchor.constraint(equalTo: self.masterViewController.view.rightAnchor).isActive = true
    }
    
    private func _setupFrames() {
        self.masterViewController.view.frame = CGRect(x: -masterViewWidth, y: 0, width: masterViewWidth, height: self.view.bounds.height)
    }
    
    internal func showChildViewController(_ viewController: UIViewController) {
        if let current = self.currentDetailViewController {
            current.removeFromParent()
            current.view.removeFromSuperview()
        }
        
        self.addChild(viewController)
        self.currentDetailViewController = viewController
        self.view.insertSubview(viewController.view, at: 0)
        viewController.view.frame = CGRect(origin: .zero, size: self.view.bounds.size)
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
        self.title = viewController.title
    }
    
    private var beginPoint: CGPoint = .zero
    @objc private func didPan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.beginPoint = self.view.bounds.origin
        case .changed:
            let newLocation = self.beginPoint.x - gesture.translation(in: self.view!).x
            if newLocation < 0
            && newLocation > -masterViewWidth {
                self.view.bounds = CGRect(x: newLocation, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
            }
            self._updateDetailViewAlpha(offset: -newLocation)
        case .ended: fallthrough
        case .cancelled:
            if self.view.bounds.origin.x >= -self.masterViewWidth / 3
                || gesture.velocity(in: self.view!).x < -0.5 {
                self.showDetailView()
            } else {
                self.showMasterView()
            }
        default: break
        }
    }
    
    @objc private func didTap(gesture: UIGestureRecognizer) {
        if self.isShowingMaster {
            self.showDetailView()
        }
    }
    
    @objc internal func showDetailView() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.view.bounds = CGRect(origin: .zero, size: self.view.bounds.size)
            self._updateDetailViewAlpha(offset: 0)
        }, completion: { _ in
            self.currentDetailViewController?.becomeFirstResponder()
            self.isShowingMaster = false
        })
    }
    
    @objc private func showMasterView() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.view.bounds = CGRect(origin: .init(x: -self.masterViewWidth, y: 0), size: self.view.bounds.size)
            self._updateDetailViewAlpha(offset: self.masterViewWidth)
        }, completion: { _ in
            self.currentDetailViewController?.resignFirstResponder()
            self.isShowingMaster = true
        })
    }

    private func _updateDetailViewAlpha(offset: CGFloat) {
        let alphaComponent = max(0.3, 1 - offset / self.masterViewWidth) // 透明度不小于 0.3
        self.currentDetailViewController?.view.alpha = alphaComponent
    }
    
    public override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.masterViewController.view.frame = CGRect(x: self.masterViewController.view.frame.origin.x, y: 0, width: self.masterViewWidth, height: self.view.bounds.height)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        self.setupTheme()
    }
}


extension HomeViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.tap {
            return isShowingMaster && gestureRecognizer.location(in: self.view).x > 0
        }
        
        return true
    }
}
