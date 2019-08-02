//
//  AppDelegate.swift
//  Iceland
//
//  Created by ian luo on 2018/8/13.
//  Copyright © 2018 wod. All rights reserved.
//

import UIKit
import SwiftyBeaver
import Business
import Interface

internal let log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let console = ConsoleDestination()
    var application: Application?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        console.format = "$DHH:mm:ss$d $L $M"
        console.minLevel = .info
        
        log.addDestination(console)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        self.application = Application(window: window!)
        
        window?.makeKeyAndVisible()
        
        self.application?.start(from: nil, animated: false)
                        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let sourceApp = (options[.sourceApplication] as? String) ?? ""
        return self.application?.dependency.urlHandlerManager.handle(url: url, sourceApp: sourceApp) ?? false
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
