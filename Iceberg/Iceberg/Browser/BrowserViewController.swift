//
//  BrwoserViewController.swift
//  Iceberg
//
//  Created by ian luo on 2019/10/1.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface
import RxSwift

public class BrowserViewController: UIViewController {
    
    public struct Output {
        public let canceld: PublishSubject<Void> = PublishSubject()
    }
    
    private var recentViewController: BrowserRecentViewController!
    private var browserFolderViewController: BrowserFolderViewController!
    public let output: Output = Output()
    private let disposeBag = DisposeBag()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        
        button.interface { (me, theme) in
            guard let button = me as? UIButton else { return }
            button.setImage(Asset.Assets.down.image.fill(color: theme.color.interactive), for: .normal)
        }
        
        return button
    }()
    
    public convenience init(recentViewController: BrowserRecentViewController,
                            browserFolderViewController: BrowserFolderViewController) {
        self.init()
        self.recentViewController = recentViewController
        self.browserFolderViewController = browserFolderViewController
        
        self.title = L10n.Browser.title
        self.tabBarItem = UITabBarItem(title: "", image: Asset.Assets.document.image, tag: 0)
    }
    
    public override func viewDidLoad() {
        let shouldShowCloseButton = self.presentingViewController != nil
        
        if shouldShowCloseButton {
            let closeItem =  UIBarButtonItem(image: Asset.Assets.down.image, style: .plain, target: nil, action: nil)
            closeItem.rx.tap.subscribe(onNext: { [weak self] _ in
                self?.output.canceld.onNext(())
            }).disposed(by: self.disposeBag)
            
            self.navigationItem.leftBarButtonItem = closeItem
        }
                
        self.view.addSubview(self.recentViewController.view)
        self.recentViewController.view.sideAnchor(for: [.left, .top, .right], to: self.view, edgeInsets: .init(top: 20, left: 10, bottom: 0, right: -10), considerSafeArea: true)
        self.recentViewController.view.sizeAnchor(height: 100)
        self.addChild(self.recentViewController)
        self.recentViewController.didMove(toParent: self)
        
        
        let nav = Coordinator.createDefaultNavigationControlller()
        nav.pushViewController(self.browserFolderViewController, animated: false)
        self.view.addSubview(nav.view)
        nav.view.sideAnchor(for: [.left, .bottom, .right], to: self.view, edgeInset: 0)
        self.recentViewController.view.columnAnchor(view: nav.view, space: 20)
        self.addChild(nav)
        nav.didMove(toParent: self)
        
        self.recentViewController.view.roundConer(radius: 10)
        
        self.interface { (me, theme) in
            self.view.backgroundColor = theme.color.background1
            nav.navigationBar.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background1, size: .singlePoint), for: .default)
        }
    }
}
