//
//  KanbanViewController.swift
//  x3Note
//
//  Created by ian luo on 2021/3/22.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Interface

public class KanbanViewController: UIViewController {
    
    private let viewModel: KanbanViewModel
    
    private let statusBarContainer: UIScrollView = UIScrollView()
    private let documentBarContainer: UIScrollView = UIScrollView()
    private let actionPanel: UIView = UIView()
    
    private let disposeBag = DisposeBag()
    
    public init(viewModel: KanbanViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        self.title = TabIndex.kanban.name
        self.tabBarItem.image = TabIndex.kanban.icon
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.viewModel.loadAllStatus()
    }
    
    public override func viewDidLoad() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        self.view.addSubview(self.actionPanel)
        
        self.actionPanel.sideAnchor(for: [.left, .right], to: self.view, edgeInset: 0).sideAnchor(for: .top, to: self.view, edgeInset: 0)
        
        self.actionPanel.addSubview(self.statusBarContainer)
        self.actionPanel.addSubview(self.documentBarContainer)
        
        self.view.interface { (me, theme) in
            me.backgroundColor = theme.color.background1
        }
        
        if !self.viewModel.context.dependency.purchaseManager.isMember.value {
            let cover = UIView()
            cover.interface { (me, theme) in
                me.backgroundColor = theme.color.background1.withAlphaComponent(0.9)
            }
            self.actionPanel.addSubview(cover)
            cover.allSidesAnchors(to: self.actionPanel, edgeInset: 0)
            
            self.viewModel.context.dependency.purchaseManager.isMember.subscribe(onNext: {
                if $0 {
                    cover.removeFromSuperview()
                }
            }).disposed(by: self.disposeBag)
            
            let button = UIButton()
            button.setTitle(L10n.Kanban.Filter.get, for: .normal)
            button.setImage(Asset.Assets.proLabel.image, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -10)
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right:0)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -10)
            button.rx.tap.subscribe(onNext: {
                self.viewModel.context.coordinator?.showMembership()
            }).disposed(by: self.disposeBag)
            
            cover.addSubview(button)
            button.sideAnchor(for: .left, to: cover, edgeInset: Layout.edgeInsets.left)
            button.centerAnchors(position: .centerY, to: cover)
        }
        
        self.statusBarContainer.sideAnchor(for: [.left, .right, .top], to: self.actionPanel, edgeInsets: UIEdgeInsets(top: Layout.edgeInsets.top, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right), considerSafeArea: true)
        self.statusBarContainer.sizeAnchor(height: 30)
        
        self.statusBarContainer.columnAnchor(view: self.documentBarContainer, space: 15)

        self.documentBarContainer.sideAnchor(for: [.left, .right, .bottom], to: self.actionPanel, edgeInsets: UIEdgeInsets(top: Layout.edgeInsets.top, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right), considerSafeArea: true)
        self.documentBarContainer.sizeAnchor(height: 30)
        
        let kanbanGraidViewController = KanbanGridViewController(viewModel: self.viewModel)
        self.addChild(kanbanGraidViewController)
        self.view.addSubview(kanbanGraidViewController.view)
        
        self.actionPanel.columnAnchor(view: kanbanGraidViewController.view, space: 20)
        kanbanGraidViewController.view.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInsets: UIEdgeInsets(top: Layout.edgeInsets.top, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right), considerSafeArea: true)
        
        Observable.combineLatest(self.viewModel.status, self.viewModel.ignoredStatus, self.viewModel.ignoredDocuments).asDriver(onErrorJustReturn: ([:], [], [])).drive(onNext: { [weak self] (statusMap, ignored, _) in
            guard let strongSelf = self else { return }
            let view = strongSelf.createStatusButtonBar(statusMap, ignored: ignored)
            strongSelf.statusBarContainer.subviews.forEach { $0.removeFromSuperview() }
            strongSelf.statusBarContainer.addSubview(view)
            view.allSidesAnchors(to: strongSelf.statusBarContainer, edgeInset: 0)
            
            kanbanGraidViewController.showStatus(statusMap.map { $0.key })
        }).disposed(by: self.disposeBag)
        
        Observable.combineLatest(self.viewModel.documents, self.viewModel.ignoredDocuments).asDriver(onErrorJustReturn: ([], [])).drive(onNext: { [weak self] in
            guard let strongSelf = self else { return }
            let view = strongSelf.createDocumentBar($0.0, ignored: $0.1)
            strongSelf.documentBarContainer.subviews.forEach { $0.removeFromSuperview() }
            strongSelf.documentBarContainer.addSubview(view)
            view.allSidesAnchors(to: strongSelf.documentBarContainer, edgeInset: 0)
        }).disposed(by: self.disposeBag)

        self.viewModel.loadAllStatus()
    }
    
    private func createStatusButtonBar(_ status: [String: Int], ignored: [String]) -> UIView {
        return UIStackView(subviews: status.sorted(by: { (v1, v2) -> Bool in
            switch (self.viewModel.isFinishedStatus(status: v1.key), self.viewModel.isFinishedStatus(status: v2.key)) {
            case (true, true):
                return v1.key < v2.key
            case (false, false):
                return v1.key < v2.key
            case (true, false):
                return false
            case (false, true):
                return true
            }
        }).map({ key, value in
            let button = UIButton(title: "\(key) \(value)", for: .normal)
            
            button.interface { (me, theme) in
                let button = me as! UIButton
                
                let color = self.viewModel.isFinishedStatus(status: key) ? theme.color.finished : theme.color.unfinished
                button.setBackgroundImage(UIImage.create(with: color, size: .singlePoint), for: .normal)
                button.setBackgroundImage(UIImage.create(with: theme.color.background1, size: .singlePoint), for: .selected)
                button.setTitleColor(theme.color.secondaryDescriptive, for: .selected)
                button.setTitleColor(theme.color.spotlitTitle, for: .normal)
                button.border(color: color, width: 1)
                button.titleLabel?.font = theme.font.footnote
            }
            
            button.isSelected = ignored.contains(key)
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            button.sizeAnchor(height: 30)
            button.roundConer(radius: Layout.cornerRadius)
            button.rx.tap.subscribe( onNext: { [button] in
                self.viewModel.updateIgnoredStatus(status: key, add: !button.isSelected)
            }).disposed(by: self.disposeBag)
            return button
        }), distribution: .equalSpacing, spacing: 10)
    }
    
    private func createDocumentBar(_ documents: [String], ignored: [String]) -> UIView {
        return UIStackView(subviews: documents.sorted().map({ document in
            let button = UIButton(title: document, for: .normal)
            button.interface { (me, theme) in
                let button = me as! UIButton
                button.setBackgroundImage(UIImage.create(with: theme.color.background2, size: .singlePoint), for: .normal)
                button.setBackgroundImage(UIImage.create(with: theme.color.background1, size: .singlePoint), for: .selected)
                button.setTitleColor(theme.color.interactive, for: .normal)
                button.setTitleColor(theme.color.secondaryDescriptive, for: .selected)
                button.titleLabel?.font = theme.font.footnote
                button.border(color: theme.color.background2, width: 1)
            }
            
            button.isSelected = ignored.contains(document)
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            button.sizeAnchor(height: 30)
            button.roundConer(radius: Layout.cornerRadius)
            button.rx.tap.subscribe( onNext: { [button] in
                self.viewModel.updateIgnoredDocument(document: document, add: !button.isSelected)
            }).disposed(by: self.disposeBag)
            return button
        }), distribution: .equalSpacing, spacing: 10)
    }
}
