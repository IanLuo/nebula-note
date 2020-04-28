//
//  MacHomeViewController.swift
//  x3Note
//
//  Created by ian luo on 2020/4/25.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift

public class MacHomeViewController: UIViewController {
    struct Constants {
        static let leftWidth: CGFloat = 300
        static let middleWidth: CGFloat = 375
    }
    
    private var toolBar: UIView = UIView()
    private var leftPart: UIView = UIView()
    private var middlePart: UIView = UIView()
    private var rightPart: UIView = UIView()
    
    private var dashboardViewController: DashboardViewController!
    
    convenience init(dashboardViewController: DashboardViewController) {
        self.init()
        self.dashboardViewController = dashboardViewController
    }
    
    public override func viewDidLoad() {
        self.view.addSubview(self.toolBar)
        self.view.addSubview(self.leftPart)
        self.view.addSubview(self.middlePart)
        self.view.addSubview(self.rightPart)
        
        self.setupUI()
    }
    
    private func setupUI() {
        self.toolBar.sizeAnchor(height: 80)
        self.toolBar.sideAnchor(for: [.left, .top, .right], to: self.view, edgeInset: 0)
        
        self.leftPart.sideAnchor(for: [.left, .bottom], to: self.view, edgeInset: 0)
        self.leftPart.sizeAnchor(width: Constants.leftWidth)
        self.leftPart.topAnchor.constraint(equalTo: self.toolBar.bottomAnchor).isActive = true
        
        self.middlePart.sideAnchor(for: .bottom, to: self.view, edgeInset: 0)
        self.middlePart.sizeAnchor(width: Constants.middleWidth)
        self.middlePart.topAnchor.constraint(equalTo: self.toolBar.bottomAnchor).isActive = true
        self.middlePart.leftAnchor.constraint(equalTo: self.leftPart.rightAnchor).isActive = true
        
        self.rightPart.sideAnchor(for: [.bottom, .right], to: self.view, edgeInset: 0)
        self.rightPart.leftAnchor.constraint(equalTo: self.middlePart.rightAnchor).isActive = true
        
        self.setupToolBar()
        self.setupLeftPart()
        self.setupMiddlePart()
    }
    
    private func setupToolBar() {
        
    }
    
    private func setupLeftPart() {
        self.addChild(self.dashboardViewController)
        self.leftPart.addSubview(self.dashboardViewController.view)
    }
    
    private func setupMiddlePart() {
        
    }
    
    private func showDocument() {
        
    }
    
    public func chooseTab(index: Int, subTab: Int?) {
        
    }
    
    private func toggleLeftPartVisiability(visiable: Bool) {
        if visiable {
            self.leftPart.constraint(for: .width)?.constant = 0
        } else {
            self.leftPart.constraint(for: .width)?.constant = Constants.leftWidth
        }
    }
    
    private func toggleMiddlePartVisiability(visiable: Bool) {
        if visiable {
            self.middlePart.constraint(for: .width)?.constant = 0
        } else {
            self.middlePart.constraint(for: .width)?.constant = Constants.middleWidth
        }
    }
}
