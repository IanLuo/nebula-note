//
//  MaterialsViewController.swift
//  x3Note
//
//  Created by ian luo on 2021/6/25.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface
import RxSwift

public class MaterialsViewController: UIViewController {
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.title = L10n.Material.title
        self.tabBarItem.image = TabIndex.idea.icon
    }
    
    var viewControllers: [UIViewController]?
    private var switcher: UISegmentedControl!
    
    private let disposeBag = DisposeBag()
    
    convenience init(viewControllers: [UIViewController]) {
        self.init()
        self.switcher = UISegmentedControl(items: viewControllers.map { $0.title ?? "" })
        self.viewControllers = viewControllers
    }
    
    public required init?(coder: NSCoder) {
        fatalError("")
    }
    
    public override func viewDidLoad() {
        switcher.interface { me, theme in
            let seg = me as! UISegmentedControl
            if #available(iOS 13.0, *) {
                seg.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : theme.color.spotlitTitle], for: .selected)
                seg.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : theme.color.interactive], for: .normal)
                seg.selectedSegmentTintColor = theme.color.spotlight
            } else {
                seg.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : theme.color.spotlight], for: .normal)
            }
        }
        
        switcher.rx.value.asDriver().drive(onNext: {index in
            guard index >= 0 && index < (self.viewControllers?.count ?? 0) else { return }
            self.select(index: index)
        }).disposed(by: self.disposeBag)
        
        self.select(index: 0)
    }
    
    private func select(index: Int) {
        self.switcher.selectedSegmentIndex = index
        
        self.children.forEach {
            $0.removeFromParent()
            $0.view.removeFromSuperview()
        }
        
        guard let viewController = self.viewControllers?[index] else { return }
        viewController.navigationItem.titleView = self.switcher
        let nav = Application.createDefaultNavigationControlller(root: viewController)
        self.addChildViewController(nav)
        self.view.addSubview(nav.view)
        nav.view.allSidesAnchors(to: self.view, edgeInset: 0)
    }
}
