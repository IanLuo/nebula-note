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
    
    private let masterViewWidth: CGFloat = UIScreen.main.bounds.width * 3 / 4
    
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
    
    public override func viewDidLoad() {
        self.setupUI()

        pan.delegate = self
        self.view.addGestureRecognizer(pan)
        
        
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Asset.Assets.master.image.fill(color: InterfaceTheme.Color.interactive), style: .plain, target: self, action: #selector(showMasterView))
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
        if let current = self.currentDetailViewController {
            current.removeFromParent()
            current.view.removeFromSuperview()
        }
        
        self.addChild(viewController)
        self.currentDetailViewController = viewController
        self.view.insertSubview(viewController.view, at: 0)
        
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
                if let frame = self.navigationController?.navigationBar.frame {
                    self.navigationController?.navigationBar.frame = frame.offsetX(-newLocation)
                }
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
            if let frame = self.navigationController?.navigationBar.frame {
                self.navigationController?.navigationBar.frame = CGRect(origin: CGPoint(x: 0, y: frame.origin.y), size: frame.size)
            }
            self._updateDetailViewAlpha(offset: 0)
        }, completion: { _ in
            self.currentDetailViewController?.becomeFirstResponder()
            self.isShowingMaster = false
        })
    }
    
    @objc private func showMasterView() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.view.bounds = CGRect(origin: .init(x: -self.masterViewWidth, y: 0), size: self.view.bounds.size)
            if let frame = self.navigationController?.navigationBar.frame {
                self.navigationController?.navigationBar.frame = frame.offsetX(-self.view.bounds.origin.x)
            }
            self._updateDetailViewAlpha(offset: self.masterViewWidth)
        }, completion: { _ in
            self.currentDetailViewController?.resignFirstResponder()
            self.isShowingMaster = true
        })
    }

    private func _updateDetailViewAlpha(offset: CGFloat) {
        let alphaComponent = max(0.3, 1 - offset / self.masterViewWidth) // 透明度不小于 0.3
        self.currentDetailViewController?.view.alpha = alphaComponent
        self.navigationController?.navigationBar.alpha = alphaComponent
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
