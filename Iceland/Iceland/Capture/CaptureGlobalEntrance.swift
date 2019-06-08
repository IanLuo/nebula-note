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
import Interface

public class CaptureGlobalEntranceWindow: UIWindow {
    public var entryAction: (() -> Void)?
    
    public var isOffScreen: Bool = false
    
    private weak var _fromWindow: UIWindow?
    
    private static func windowFrame(from window: UIWindow) -> CGRect {
        return CGRect(x: UIScreen.main.bounds.width - window.safeArea.right - 90,
                      y: UIScreen.main.bounds.height - window.safeArea.bottom - 60 - 30,
                      width: 60,
                      height: 60)
    }
    
    public init(window: UIWindow) {
        super.init(frame: CaptureGlobalEntranceWindow.windowFrame(from: window))
        self._fromWindow = window
        self.windowLevel = .alert
        let viewController = _CaptureGlobalEntranceViewController()
        self.rootViewController = viewController
        
        viewController.tapped = {
            self.entryAction?()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(_orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc private func _orientationChanged(notification: Notification) {
        
        guard !self.isOffScreen else { return }
        
        UIView.animate(withDuration: 0.2) {
            if let window = self._fromWindow {
                self.frame = CaptureGlobalEntranceWindow.windowFrame(from: window)
            }
        }
    }
    
    public func hide() {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.frame = CGRect(x: UIScreen.main.bounds.width, y: UIScreen.main.bounds.height - self._fromWindow!.safeArea.bottom - 60 - 30, width: self.frame.size.width, height: self.frame.size.height)
        }, completion: { _ in
            self.isOffScreen = true
            self.alpha = 0 // 防止旋转的时候在屏幕上出现
        })
    }
    
    public func show() {
        self.alpha = 1
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.frame = CGRect(x: UIScreen.main.bounds.width - self.frame.width - 30, y: UIScreen.main.bounds.height - self._fromWindow!.safeArea.bottom - 60 - 30, width: self.frame.size.width, height: self.frame.size.height)
        }, completion: { _ in
            self.isOffScreen = false
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class _CaptureGlobalEntranceViewController: UIViewController {
    public var tapped: (() -> Void)?
    
    private lazy var _button: UIButton = {
        let button = UIButton(frame: CGRect(origin: .zero, size: self.view.bounds.size))
        
        button.interface({ (me, theme) in
            let me = me as! UIButton
            me.setBackgroundImage(UIImage.create(with: theme.color.spotlight,
                                                     size: self.view.bounds.size,
                                                     style: UIImageStyle.circle),
                                      for: .normal)
            me.setImage(Asset.Assets.inspiration.image.fill(color: InterfaceTheme.Color.spotlitTitle), for: .normal)
        })
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
