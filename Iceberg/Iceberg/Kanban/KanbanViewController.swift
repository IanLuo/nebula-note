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
        
        self.statusBarContainer.sideAnchor(for: [.left, .right, .top], to: self.view, edgeInsets: UIEdgeInsets(top: Layout.edgeInsets.top, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right))

        self.documentBarContainer.sideAnchor(for: [.left, .right], to: self.view, edgeInsets: UIEdgeInsets(top: Layout.edgeInsets.top, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right))
        
        self.statusBarContainer.columnAnchor(view: self.documentBarContainer, space: 20)
        
        self.viewModel.status.asDriver(onErrorJustReturn: [:]).drive(onNext: { [weak self] in
            guard let strongSelf = self else { return }
            let view = strongSelf.createStatusButtonBar($0)
            strongSelf.statusBarContainer.subviews.forEach { $0.removeFromSuperview() }
            strongSelf.statusBarContainer.addSubview(view)
            view.allSidesAnchors(to: strongSelf.view, edgeInset: 0)
        }).disposed(by: self.disposeBag)
        
        
        self.viewModel.documents.asDriver(onErrorJustReturn: []).drive(onNext: { [weak self] in
            guard let strongSelf = self else { return }
            let view = strongSelf.createDocumentBar($0)
            strongSelf.documentBarContainer.subviews.forEach { $0.removeFromSuperview() }
            strongSelf.documentBarContainer.addSubview(view)
            view.allSidesAnchors(to: strongSelf.view, edgeInset: 0)
        }).disposed(by: self.disposeBag)
        
        
        self.viewModel.loadAllStatus()
    }
    
    private func createStatusButtonBar(_ status: [String: Int]) -> UIView {
        return UIStackView(subviews: status.map({ key, value in
            let button = UIButton(title: "\(key) \(value)", for: .normal)
            
            button.interface { (me, theme) in
                let button = me as! UIButton
                button.setBackgroundImage(UIImage.create(with: theme.color.background2, size: .singlePoint), for: .normal)
            }
            button.roundConer(radius: 10)
            return button
        }))
        
    }
    
    private func createDocumentBar(_ documents: [String]) -> UIView {
        return UIStackView(subviews: documents.map({
            let button = UIButton(title: $0, for: .normal)
            button.interface { (me, theme) in
                let button = me as! UIButton
                button.setBackgroundImage(UIImage.create(with: theme.color.background2, size: .singlePoint), for: .normal)
            }
            button.roundConer(radius: 10)
            return button
        }))
    }
    
    
}
