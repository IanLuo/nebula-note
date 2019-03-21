//
//  ConfirmViewController.swift
//  Interface
//
//  Created by ian luo on 2019/3/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class ConfirmViewController: TransitionViewController {
    public var confirmAction: ((ConfirmViewController) -> Void)?
    
    public var cancelAction: ((ConfirmViewController) -> Void)?
    
    public var contentView: UIView = UIView()
    
    public var fromView: UIView?
    
    public var contentText: String = "you haven't set any content"
    
    private let _transitionDelegate: UIViewControllerTransitioningDelegate = FadeBackgroundTransition(animator: MoveToAnimtor())
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        
        self.transitioningDelegate = self._transitionDelegate
        self.modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self._setupUI()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(_cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
    }
    
    private func _setupUI() {
        self.view.addSubview(self.contentView)
        self.contentView.backgroundColor = InterfaceTheme.Color.background2
        self.contentView.centerAnchors(position: [.centerX, .centerY], to: self.view)
        
        let content = UILabel()
        content.text = self.contentText
        content.font = InterfaceTheme.Font.body
        content.textColor = InterfaceTheme.Color.interactive
        content.backgroundColor = InterfaceTheme.Color.background2
        content.textAlignment = .center
        content.numberOfLines = 0
        self.contentView.addSubview(content)
        
        content.sizeAnchor(width: self.view.bounds.width * 2 / 3)
        content.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInsets: .init(top: Layout.innerViewEdgeInsets.top, left: Layout.innerViewEdgeInsets.left, bottom: -Layout.innerViewEdgeInsets.bottom, right: -Layout.innerViewEdgeInsets.right))
        
        let yesButton = UIButton()
        yesButton.tintColor = InterfaceTheme.Color.spotlight
        yesButton.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background3, size: .singlePoint), for: .normal)
        yesButton.setImage(Asset.Assets.checkMark.image.withRenderingMode(.alwaysTemplate), for: .normal)
        yesButton.addTarget(self, action: #selector(_confirm), for: .touchUpInside)
        
        let noButton = UIButton()
        noButton.tintColor = InterfaceTheme.Color.warning
        noButton.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background3, size: .singlePoint), for: .normal)
        noButton.setImage(Asset.Assets.cross.image.withRenderingMode(.alwaysTemplate), for: .normal)
        noButton.addTarget(self, action: #selector(_cancel), for: .touchUpInside)

        self.contentView.addSubview(yesButton)
        self.contentView.addSubview(noButton)
        
        content.columnAnchor(view: yesButton, space: Layout.innerViewEdgeInsets.bottom)
        
        yesButton.sideAnchor(for: [.left, .bottom], to: self.contentView, edgeInset: 0)
        yesButton.rowAnchor(view: noButton, widthRatio: 1)
        yesButton.heightAnchor.constraint(equalTo: noButton.heightAnchor).isActive = true
        noButton.sideAnchor(for: [.right, .bottom], to: self.contentView, edgeInset: 0)
        
        yesButton.sizeAnchor(height: 44)
        yesButton.setBorder(position: [.top, .right], color: InterfaceTheme.Color.background2, width: 0.5)
        noButton.setBorder(position: .top, color: InterfaceTheme.Color.background2, width: 0.5)
    }
    
    @objc private func _confirm() {
        self.confirmAction?(self)
    }
    
    @objc private func _cancel() {
        self.cancelAction?(self)
    }
}

extension ConfirmViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.view
    }
}
