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
    
    private let disposeBag = DisposeBag()
    
    convenience init(viewControllers: [UIViewController]) {
        self.init()
        self.viewControllers = viewControllers
        
        viewControllers.forEach {
            self.addChildViewController($0)
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("")
    }
    
    public override func viewDidLoad() {
        let switcher = UISegmentedControl(items: self.viewControllers?.map { $0.title ?? "" })

        self.navigationItem.titleView = switcher
        
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
        
        switcher.rx.value.asDriver().drive(onNext: { [switcher] index in
            guard index >= 0 && index < (self.viewControllers?.count ?? 0) else { return }
            self.select(switcher: switcher, index: index)
        }).disposed(by: self.disposeBag)
        
        self.select(switcher: switcher, index: 0)
    }
    
    private func select(switcher: UISegmentedControl, index: Int) {
        switcher.selectedSegmentIndex = index
        self.view.subviews.forEach { $0.removeFromSuperview() }
        
        guard let view = self.viewControllers?[index].view else { return }
        self.view.addSubview(view)
        view.allSidesAnchors(to: self.view, edgeInset: 0)
    }
}
