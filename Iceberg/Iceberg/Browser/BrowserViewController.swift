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
import Core

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
        self.recentViewController.view.sizeAnchor(height: 120)
        self.addChild(self.recentViewController)
        self.recentViewController.didMove(toParent: self)
        
        let nav = Coordinator.createDefaultNavigationControlller()
        nav.pushViewController(self.browserFolderViewController, animated: false)
        self.view.addSubview(nav.view)
        nav.view.sideAnchor(for: [.left, .bottom, .right], to: self.view, edgeInset: 0)
        self.recentViewController.view.columnAnchor(view: nav.view, space: 20, alignment: .centerX)
        self.addChild(nav)
        nav.didMove(toParent: self)
                
        self.interface { [weak self] (me, theme) in
            self?.view.backgroundColor = theme.color.background1
            nav.navigationBar.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background1, size: .singlePoint), for: .default)
        }
        
        NotificationCenter.default
        .rx
        .notification(UIDocument.stateChangedNotification)
        .takeUntil(self.rx.deallocated)
        .subscribe(onNext: { notification in
            if case let document? = notification.object as? Document, document.documentState.contains(.savingError) {
                self.toastError(title: "fail to save document", subTitle: document.fileURL.lastPathComponent)
            }
        })
        .disposed(by: self.disposeBag)
        
        // add activity
        let activity = Document.createDocumentActivity()
        self.userActivity = activity
        activity.becomeCurrent()
        
        let rightItem = UIBarButtonItem(title: L10n.General.help, style: .plain, target: nil, action: nil)
        rightItem.rx.tap.subscribe(onNext: {
            HelpPage.documentManagement.open(from: self)
        }).disposed(by: self.disposeBag)
        self.navigationItem.rightBarButtonItem = rightItem
    }
}
