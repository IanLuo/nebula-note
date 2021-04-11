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
import Core
import Interface
import StoreKit
import Doorbell

public class DesktopHomeViewController: UIViewController {
    struct Constants {
        static let leftWidth: CGFloat = 300
    }
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    private var toolBar: UIView = {
        let view = UIView()
        
        view.interface { (me, theme) in
            me.backgroundColor = InterfaceTheme.Color.background1
        }
        return view
    }()
    
    private var leftPart: UIView = UIView()
    private var middlePart: UIView = UIView()
    private let toggleLeftPartButton = UIButton()
    private var dashboardViewController: DashboardViewController!
    
    private weak var coordinator: HomeCoordinator?
    
    convenience init(dashboardViewController: DashboardViewController, coordinator: HomeCoordinator) {
        self.init()
        self.dashboardViewController = dashboardViewController
        self.coordinator = coordinator
    }
    
    public override func viewDidLoad() {
        self.navigationController?.navigationBar.isHidden = true
        self.view.addSubview(self.toolBar)
        self.view.addSubview(self.middlePart)
        self.view.addSubview(self.leftPart)
        
        self.setupUI()
        
        self.toggleLeftPartVisiability(visiable: true, animated: false)
    }
    
    private func setupUI() {
        self.toolBar.sizeAnchor(height: 100)
        self.toolBar.sideAnchor(for: [.left, .top, .right], to: self.view, edgeInset: 0)
        
        self.leftPart.sideAnchor(for: [.left, .bottom], to: self.view, edgeInset: 0)
        self.leftPart.sizeAnchor(width: Constants.leftWidth)
        self.leftPart.topAnchor.constraint(equalTo: self.toolBar.bottomAnchor).isActive = true
        
        self.middlePart.sideAnchor(for: [.bottom, .right], to: self.view, edgeInset: 0)
        
        self.toolBar.columnAnchor(view: self.middlePart, alignment: .none)
        self.leftPart.rowAnchor(view: self.middlePart)
        
        self.middlePart.backgroundColor = InterfaceTheme.Color.background1
        self.setupToolBar()
        self.setupLeftPart()
        
        if #available(iOS 13.0, *) {
            let binding = KeyBinding()
            if isPad {
                KeyAction.allCases.filter({ $0.isGlobal }).forEach {
                    self.addKeyCommand(binding.create(for: $0))
                }
            }

            self.coordinator?.enableGlobalNavigateKeyCommands()
        }
    }
    
    @available(iOS 13.0, *)
    public override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        self.keyCommands?.forEach({ command in
            builder.insertChild(UIMenu(title: command.title, image: nil, identifier: UIMenu.Identifier(command.title), options: .displayInline, children: [command]), atEndOfMenu: .file)
        })
    }
    
    private func setupToolBar() {
        let stackView = UIStackView()
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        
        let ideasButton = UIButton()
        ideasButton.interface { (me, interface) in
            let ideasButton = me as! UIButton
            ideasButton.setImage(Asset.SFSymbols.lightbulb.image.fill(color: interface.color.spotlitTitle), for: .normal)
            ideasButton.setBackgroundImage(UIImage.create(with: interface.color.spotlight, size: .singlePoint), for: .normal)
        }
        ideasButton.sizeAnchor(width: 44, height: 44)
        ideasButton.roundConer(radius: Layout.cornerRadius)
        ideasButton.rx.tap.subscribe(onNext: { [weak ideasButton] in
            self.coordinator?.showCaptureEntrance(at: ideasButton)
        }).disposed(by: self.disposeBag)
        
        let iconButton = UIButton()
        iconButton.roundConer(radius: Layout.cornerRadius)
        iconButton.setImage(UIImage(named: "AppIcon")?.resize(upto: CGSize(width: 44, height: 44)), for: .normal)
        iconButton.sizeAnchor(width: 44, height: 44)
        iconButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?._showFeedbackOptions(from: iconButton)
        }).disposed(by: self.disposeBag)
        
        self.toggleLeftPartButton.interface { (me, theme) in
            let button = me as! UIButton
            button.setImage(Asset.Assets.leftPart.image.fill(color: theme.color.interactive), for: .normal)
            button.setImage(Asset.Assets.leftPart.image.fill(color: theme.color.descriptive), for: .selected)
        }

        self.toggleLeftPartButton.rx.tap.subscribe(onNext: { [weak self, unowned toggleLeftPartButton] in
            self?.toggleLeftPartVisiability(visiable: !toggleLeftPartButton.isSelected)
        }).disposed(by: self.disposeBag)
                
        let actionsStack = UIStackView()
        actionsStack.spacing = 20
        actionsStack.addArrangedSubview(iconButton)
        actionsStack.addArrangedSubview(toggleLeftPartButton)
        
        let otherStack = UIStackView()
        otherStack.spacing = 20
        otherStack.alignment = .center
        otherStack.addArrangedSubview(ideasButton)
        
        stackView.addArrangedSubview(actionsStack)
        stackView.addArrangedSubview(otherStack)
        
        self.toolBar.addSubview(stackView)
        stackView.sideAnchor(for: [.left, .right], to: self.toolBar, edgeInset: 30)
        stackView.centerAnchors(position: .centerY, to: self.toolBar)
        stackView.sizeAnchor(height: 80)
    }
    
    public func hideLeftAndMiddlePart() {
        self.toggleLeftPartVisiability(visiable: false)
    }
    
    private func setupLeftPart() {
        let nav = Application.createDefaultNavigationControlller(root: self.dashboardViewController, transparentBar: true)
        nav.isNavigationBarHidden = true
        self.addChildViewController(nav)
        self.leftPart.addSubview(nav.view)
        nav.view.allSidesAnchors(to: self.leftPart, edgeInset: 0)
    }
    
    internal func toggleLeftPartVisiability(visiable: Bool, animated: Bool = true) {
        self.toggleLeftPartButton.isSelected = visiable
        
        if visiable {
            self.leftPart.constraint(for: .left)?.constant = 0
        } else {
            self.leftPart.constraint(for: .left)?.constant = -Constants.leftWidth
        }
        
        self.toggleLeftPartButton.isSelected = visiable
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        } else {
            self.view.layoutIfNeeded()
        }
    }
    
    internal var isLeftPartVisiable: Bool {
        return self.leftPart.constraint(for: .left)?.constant == 0
    }
        
    public func showInMiddlePart(viewController: UIViewController) {
        if let lastChildViewController = lastChildViewController {
            lastChildViewController.removeFromParent()
            lastChildViewController.view.removeFromSuperview()
        }
        
        self.addChildViewController(viewController)
        self.middlePart.addSubview(viewController.view)
        viewController.view.allSidesAnchors(to: self.middlePart, edgeInset: 0)
        lastChildViewController = viewController
        
    }
    
    private func _showFeedbackOptions(from: UIView) {
        let selector = SelectorViewController()
        selector.title = L10n.Setting.Feedback.title
        selector.addItem(title: L10n.Setting.feedback)
        selector.addItem(title: L10n.Setting.Feedback.rate)
        selector.addItem(title: L10n.Setting.Feedback.promot)
        selector.addItem(title: L10n.Setting.Feedback.forum)
        selector.onCancel = { viewController in
            viewController.dismiss(animated: true)
        }
        
        selector.onSelection = { selection, viewController in
            switch selection {
            case 0:
                let appId = "11641"
                let appKey = "k2q6pHh2ekAbQjELagm2VZ3rHJFHEj3bl1GI529FjaDO29hfwLcn5sJ9jBSVA24Q"
                
                viewController.dismiss(animated: true) {
                    let feedback = Doorbell.init(apiKey: appKey, appId: appId)
                    feedback!.showFeedbackDialog(in: self, completion: { (error, cancelled) -> Void in
                        if (error?.localizedDescription != nil) {
                            print(error!.localizedDescription);
                        }
                    })
                }
            case 1:
                SKStoreReviewController.requestReview()
            case 2:
                if let name = URL(string: "https://itunes.apple.com/app/id1501111134"), !name.absoluteString.isEmpty {
                    let objectsToShare = [name]
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                    activityVC.popoverPresentationController?.sourceView = viewController.view
                    activityVC.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 500, height: 600)
                    viewController.present(activityVC, animated: true, completion: nil)
                }
            case 3:
                UIApplication.shared.open(URL(string: "https://forum.nebulaapp.net/")!, options: [:], completionHandler: nil)
            default: break
            }
        }
        
        selector.present(from: self, at: from)
    }
}

var lastChildViewController: UIViewController?
