//
//  AppDelegate.swift
//  Iceland
//
//  Created by ian luo on 2018/8/13.
//  Copyright © 2018 wod. All rights reserved.
//

import UIKit
import SwiftyBeaver
import RxSwift
import Interface

//#if os(iOS)
//import Firebase
//#endif
#if DEBUG
//import ShowTime
#endif

internal let log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let console = ConsoleDestination()
    var application: Application!
    let disposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
//        if !isMac {
            //FirebaseApp.configure()
//        }
        #if DEBUG
//        ShowTime.enabled = .never
        console.minLevel = .info
        #else
        console.minLevel = .error
        #endif
        
        console.format = "$DHH:mm:ss$d $L $M"
        
        log.addDestination(console)
        
        if #available(iOS 13, *) {} else {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            self.application = Application(window: window!)
            self.application.dependency.purchaseManager.initialize()
            self.application?.start(from: nil, animated: false)
            
            self.window?.makeKeyAndVisible()
        }
        
        return true
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
        
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let sourceApp = (options[.sourceApplication] as? String) ?? ""
        return self.application.dependency.urlHandlerManager.handle(url: url, sourceApp: sourceApp)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return self.application.dependency.activityHandler.handle(by: self.application, activity: userActivity)
    }
}

