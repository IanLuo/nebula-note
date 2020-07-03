
//
//  W.swift
//  x3Note
//
//  Created by ian luo on 2020/7/3.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit

@available(iOS 13, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var application: Application!
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        self.application = Application(window: window!)
        self.application?.start(from: nil, animated: false)
        self.application.dependency.purchaseManager.initialize()
        
        self.window?.makeKeyAndVisible()
        
        #if targetEnvironment(macCatalyst)
        if let titlebar = windowScene.titlebar {
            titlebar.titleVisibility = .hidden
            titlebar.toolbar = nil
            
            self.window?.interface({ [weak self] (me, theme) in
                self?.window?.backgroundColor = theme.color.background1
            })
        }
        #endif
    }
    
}
