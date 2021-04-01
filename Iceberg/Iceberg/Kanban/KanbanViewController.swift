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
    
    public override func viewDidLoad() {
        self.view.addSubview(self.statusBarContainer)
        self.view.addSubview(self.documentBarContainer)
        
        self.view.interface { (me, theme) in
            me.backgroundColor = theme.color.background1
        }
        
        self.statusBarContainer.sideAnchor(for: [.left, .right, .top], to: self.view, edgeInsets: UIEdgeInsets(top: Layout.edgeInsets.top, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right), considerSafeArea: true)
        self.statusBarContainer.sizeAnchor(height: 30)

        self.documentBarContainer.sideAnchor(for: [.left, .right], to: self.view, edgeInsets: UIEdgeInsets(top: Layout.edgeInsets.top, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right), considerSafeArea: true)
        self.documentBarContainer.sizeAnchor(height: 30)
        
        self.statusBarContainer.columnAnchor(view: self.documentBarContainer, space: 20)
        
        let kanbanGraidViewController = KanbanGridViewController(viewModel: self.viewModel)
        self.addChild(kanbanGraidViewController)
        self.view.addSubview(kanbanGraidViewController.view)
        
        self.documentBarContainer.columnAnchor(view: kanbanGraidViewController.view, space: 20)
        kanbanGraidViewController.view.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInsets: UIEdgeInsets(top: Layout.edgeInsets.top, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right), considerSafeArea: true)
        
        self.viewModel.status.asDriver(onErrorJustReturn: [:]).drive(onNext: { [weak self] in
            guard let strongSelf = self else { return }
            let view = strongSelf.createStatusButtonBar($0)
            strongSelf.statusBarContainer.subviews.forEach { $0.removeFromSuperview() }
            strongSelf.statusBarContainer.addSubview(view)
            view.allSidesAnchors(to: strongSelf.statusBarContainer, edgeInset: 0)
            
            kanbanGraidViewController.showStatus($0.map { $0.key })
        }).disposed(by: self.disposeBag)
        
        self.viewModel.documents.asDriver(onErrorJustReturn: []).drive(onNext: { [weak self] in
            guard let strongSelf = self else { return }
            let view = strongSelf.createDocumentBar($0)
            strongSelf.documentBarContainer.subviews.forEach { $0.removeFromSuperview() }
            strongSelf.documentBarContainer.addSubview(view)
            view.allSidesAnchors(to: strongSelf.documentBarContainer, edgeInset: 0)
        }).disposed(by: self.disposeBag)

        self.viewModel.loadAllStatus()
    }
    
    private func createStatusButtonBar(_ status: [String: Int]) -> UIView {
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
                button.setTitleColor(theme.color.spotlitTitle, for: .normal)
                button.titleLabel?.font = theme.font.footnote
            }
            
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            button.sizeAnchor(height: 30)
            button.roundConer(radius: Layout.cornerRadius)
            return button
        }), distribution: .equalSpacing, spacing: 10)
    }
    
    private func createDocumentBar(_ documents: [String]) -> UIView {
        return UIStackView(subviews: documents.sorted().map({
            let button = UIButton(title: $0, for: .normal)
            button.interface { (me, theme) in
                let button = me as! UIButton
                button.setBackgroundImage(UIImage.create(with: theme.color.background2, size: .singlePoint), for: .normal)
                button.setTitleColor(theme.color.interactive, for: .normal)
                button.titleLabel?.font = theme.font.footnote
            }
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            button.sizeAnchor(height: 30)
            button.roundConer(radius: Layout.cornerRadius)
            return button
        }), distribution: .equalSpacing, spacing: 10)
    }
}
