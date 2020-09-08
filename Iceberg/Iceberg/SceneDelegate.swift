
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
        
        #if targetEnvironment(macCatalyst)
        if let titlebar = windowScene.titlebar {
            titlebar.titleVisibility = .hidden
            titlebar.toolbar = nil
            
            self.window?.interface({ [weak self] (me, theme) in
                self?.window?.backgroundColor = theme.color.background1
            })
        }
        #endif
        
        self.window?.makeKeyAndVisible()
        
        self.application = Application(window: window!)
        self.application.dependency.purchaseManager.initialize()
        self.application?.start(from: nil, animated: false)
        
        self.window?.addValidateHandler({ [weak self] (command) -> Bool in
            return self?.application.homeCoordinator?.isCommandAvailable(command: command) ?? false
        })

    }
    
    @available(iOS 13.0, *)
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        builder.remove(menu: UIMenu.Identifier.file)
        builder.remove(menu: UIMenu.Identifier.edit)
        builder.remove(menu: UIMenu.Identifier.view)
        builder.remove(menu: UIMenu.Identifier.window)
        builder.remove(menu: UIMenu.Identifier.format)
        builder.remove(menu: UIMenu.Identifier.help)
        
        let binding = KeyBinding()
        binding.constructMenu(builder: builder)
    }
    
    override func validate(_ command: UICommand) {
        if application.homeCoordinator?.isCommandAvailable(command: command) ?? false {
            command.state = .on
        } else {
            command.state = .off
        }
        
        super.validate(command)
    }
}
