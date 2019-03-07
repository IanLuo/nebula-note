//
//  CaptureGlobalEntrance.swift
//  Iceland
//
//  Created by ian luo on 2019/3/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public class CaptureGlobalEntranceWindow: UIWindow {
    public var entryAction: (() -> Void)?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.windowLevel = .alert
        let viewController = _CaptureGlobalEntranceViewController()
        self.rootViewController = viewController
        
        viewController.tapped = {
            self.entryAction?()
        }
    }
    
    public func hide() {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.frame = CGRect(x: UIScreen.main.bounds.width, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height)
        }, completion: nil)
    }
    
    public func show() {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.frame = CGRect(x: UIScreen.main.bounds.width - self.frame.width - 30, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height)
        }, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class _CaptureGlobalEntranceViewController: UIViewController {
    public var tapped: (() -> Void)?
    
    private lazy var _button: UIButton = {
        let button = UIButton(frame: CGRect(origin: .zero, size: self.view.bounds.size))
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.spotLight,
                                                 size: self.view.bounds.size,
                                                 style: UIImageStyle.circle),
                                  for: .normal)
        button.tintColor = InterfaceTheme.Color.interactive
        button.setImage(Asset.add.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(_didTap), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self._setupUI()
    }
    
    private func _setupUI() {
        self.view.addSubview(self._button)
        self._button.allSidesAnchors(to: self.view, edgeInset: 0)
    }
    
    @objc private func _didTap() {
        self.tapped?()
    }

}
