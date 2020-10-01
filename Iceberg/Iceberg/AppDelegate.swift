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

//import Firebase
#if DEBUG
//import ShowTime
#endif
//import Firebase

internal let log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let console = ConsoleDestination()
    var application: Application!
    let disposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
//        FirebaseApp.configure()
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
            self.application?.start(from: nil, animated: false)
            self.application.dependency.purchaseManager.initialize()
            
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
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        self.application?.handleSharedIdeas()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

