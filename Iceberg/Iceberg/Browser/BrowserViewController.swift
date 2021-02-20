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
import RxCocoa
import Core

fileprivate enum ViewType {
    case recent, documents
}

fileprivate struct Model {
    var viewType: BehaviorRelay<ViewType>
    var browserFolderViewController: UIViewController
    var recentViewController: UIViewController
    var shouldShowRecentView: Bool
    var shouldShowHelpButton: Bool
    var usage: BrowserCoordinator.Usage
}

public class BrowserViewController: UIViewController {
    
    public struct Output {
        public let canceld: PublishSubject<Void> = PublishSubject()
    }
    
    private var recentViewController: BrowserFolderViewController!
    private var browserFolderViewController: BrowserFolderViewController!
    public let output: Output = Output()
    private let disposeBag = DisposeBag()
    
    private var model: Model!
    
    private lazy var viewTypeSegmented: UISegmentedControl = {
        let seg = UISegmentedControl()
        seg.insertSegment(withTitle: "Recent", at: 0, animated: false)
        seg.insertSegment(withTitle: "Documents", at: 1, animated: false)
        seg.selectedSegmentIndex = 1
        
        seg.interface { (view, theme) in
            let seg = view as! UISegmentedControl
            if #available(iOS 13.0, *) {
                seg.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : theme.color.spotlitTitle], for: .selected)
                seg.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : theme.color.interactive], for: .normal)
                seg.selectedSegmentTintColor = theme.color.spotlight
            } else {
                seg.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : theme.color.spotlight], for: .normal)
            }
        }
        
        seg.rx.value.asDriver().drive(onNext: { selectedIndex in
            let newValue = selectedIndex == 0 ? ViewType.recent : ViewType.documents
            self.model.viewType.accept(newValue)
        }).disposed(by: self.disposeBag)
    
        return seg
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        
        button.interface { (me, theme) in
            guard let button = me as? UIButton else { return }
            button.setImage(Asset.SFSymbols.chevronDown.image.fill(color: theme.color.interactive), for: .normal)
        }
        
        return button
    }()
    
    public convenience init(recentViewController: BrowserFolderViewController,
                            browserFolderViewController: BrowserFolderViewController,
                            coordinator: BrowserCoordinator) {
        
        self.init()
        
        self.model = Model(viewType: BehaviorRelay<ViewType>(value: .documents),
                           browserFolderViewController: Coordinator.createDefaultNavigationControlller(root: browserFolderViewController, transparentBar: true),
                           recentViewController: Coordinator.createDefaultNavigationControlller(root: recentViewController, transparentBar: true),
                           shouldShowRecentView: true,
                           shouldShowHelpButton: true,
                           usage: coordinator.usage)
        
        switch coordinator.usage {
        case .browseDocument, .chooseHeader:
            self.model.shouldShowRecentView = true
            self.model.shouldShowHelpButton = true
        case .favoriate:
            self.model.shouldShowRecentView = false
            self.model.shouldShowHelpButton = false
        }
        
        self.recentViewController = recentViewController
        self.browserFolderViewController = browserFolderViewController
        
        switch coordinator.usage {
        case .favoriate:
            self.title = L10n.Browser.Favorite.title
            self.tabBarItem = UITabBarItem(title: "", image: Asset.SFSymbols.star.image, tag: 0)
        default:
            self.title = L10n.Browser.title
            self.navigationItem.titleView = self.viewTypeSegmented
            self.tabBarItem = UITabBarItem(title: "", image: Asset.SFSymbols.doc.image, tag: 0)
        }
    }
    
    public override func viewDidLoad() {
        let shouldShowCloseButton = self.presentingViewController != nil
        
        if shouldShowCloseButton {
            let closeItem =  UIBarButtonItem(image: Asset.SFSymbols.chevronDown.image, style: .plain, target: nil, action: nil)
            closeItem.rx.tap.subscribe(onNext: { [weak self] _ in
                self?.output.canceld.onNext(())
            }).disposed(by: self.disposeBag)
            
            self.navigationItem.leftBarButtonItem = closeItem
        }
        
        self.interface { (vc, theme) in
            vc.view.backgroundColor = theme.color.background1
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
        
        self.model.viewType.subscribe(onNext: { [weak self] mode in
            guard let strongSelf = self else { return }
            strongSelf.view.subviews.forEach { $0.removeFromSuperview() }
            
            switch mode {
            case .documents:
                strongSelf.view.addSubview(strongSelf.model.browserFolderViewController.view)
                strongSelf.model.browserFolderViewController.view.allSidesAnchors(to: strongSelf.view, edgeInset: 0, considerSafeArea: true)
            case .recent:
                strongSelf.view.addSubview(strongSelf.model.recentViewController.view)
                strongSelf.model.recentViewController.view.allSidesAnchors(to: strongSelf.view, edgeInset: 0, considerSafeArea: true)
            }
        }).disposed(by: self.disposeBag)
        
        // add activity
        let activity = Document.createDocumentActivity()
        self.userActivity = activity
        activity.becomeCurrent()
        
        let rightItem = UIBarButtonItem(title: L10n.General.help, style: .plain, target: nil, action: nil)
        rightItem.rx.tap.subscribe(onNext: {
            HelpPage.documentManagement.open(from: self)
        }).disposed(by: self.disposeBag)
        
        if self.model.shouldShowHelpButton {
            self.navigationItem.rightBarButtonItem = rightItem
        }
    }
}
