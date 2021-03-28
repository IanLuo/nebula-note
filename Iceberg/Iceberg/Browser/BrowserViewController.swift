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
    case recent, documents, favorite
}

fileprivate struct Model {
    var viewType: BehaviorRelay<ViewType>
    var browserFolderViewController: UIViewController
    var recentViewController: UIViewController
    var favoriteViewController: UIViewController
    var shouldShowRecentView: Bool
    var shouldShowHelpButton: Bool
    var usage: BrowserCoordinator.Usage
}

public class BrowserViewController: UIViewController {
    
    public struct Output {
        public let canceld: PublishSubject<Void> = PublishSubject()
    }
        
    public let output: Output = Output()
    private let disposeBag = DisposeBag()
    
    private var model: Model!
    
    private lazy var viewTypeSegmented: UISegmentedControl = {
        let seg = UISegmentedControl()
        seg.insertSegment(withTitle: L10n.Browser.Favorite.title, at: 0, animated: false)
        seg.insertSegment(withTitle: L10n.Browser.Recent.title, at: 1, animated: false)
        seg.insertSegment(withTitle: L10n.Browser.title, at: 2, animated: false)
        seg.selectedSegmentIndex = 2
        
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
            switch selectedIndex {
            case 0:
                self.model.viewType.accept(.favorite)
            case 1:
                self.model.viewType.accept(.recent)
            case 2:
                self.model.viewType.accept(.documents)
            default: break
            }
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
                            favoriateViewController: BrowserFolderViewController,
                            coordinator: BrowserCoordinator) {
        
        self.init()
        
        self.model = Model(viewType: BehaviorRelay<ViewType>(value: .documents),
                           browserFolderViewController: Coordinator.createDefaultNavigationControlller(root: browserFolderViewController, transparentBar: true),
                           recentViewController: Coordinator.createDefaultNavigationControlller(root: recentViewController, transparentBar: true),
                           favoriteViewController: Coordinator.createDefaultNavigationControlller(root: favoriateViewController, transparentBar: true),
                           shouldShowRecentView: true,
                           shouldShowHelpButton: true,
                           usage: coordinator.usage)
        
        switch coordinator.usage {
        case .browseDocument, .chooseHeader:
            self.model.shouldShowRecentView = true
            self.model.shouldShowHelpButton = true
        }
                
        self.title = L10n.Browser.title
        self.navigationItem.titleView = self.viewTypeSegmented
        self.tabBarItem = UITabBarItem(title: "", image: Asset.SFSymbols.doc.image, tag: 0)
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
            case .favorite:
                strongSelf.view.addSubview(strongSelf.model.favoriteViewController.view)
                strongSelf.model.favoriteViewController.view.allSidesAnchors(to: strongSelf.view, edgeInset: 0, considerSafeArea: true)
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
