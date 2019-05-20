//
//  Application.swift
//  Iceland
//
//  Created by ian luo on 2018/11/10.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public class Application: Coordinator {
    weak var window: UIWindow?
    private let _entranceWindow: CaptureGlobalEntranceWindow

    public init(window: UIWindow) {
        self.window = window
        
        _entranceWindow = CaptureGlobalEntranceWindow(frame: CGRect(x: UIScreen.main.bounds.width - 90,
                                                                    y: UIScreen.main.bounds.height - window.safeArea.bottom - 60 - 80,
                                                                    width: 60,
                                                                    height: 60))
        _entranceWindow.makeKeyAndVisible()

        let navigationController = Coordinator.createDefaultNavigationControlller()
        
        let eventObserver = EventObserver()
        let editorContext = EditorContext(eventObserver: eventObserver)
        let syncManager = SyncManager(eventObserver: eventObserver)
        let documentManager = DocumentManager(editorContext: editorContext,
                                              eventObserver: eventObserver,
                                              syncManager: syncManager)
        
        super.init(stack: navigationController,
                   dependency: Dependency(documentManager: documentManager,
                                          documentSearchManager: DocumentSearchManager(eventObserver: eventObserver,
                                                                                       editorContext: editorContext),
                                          editorContext: editorContext,
                                          textTrimmer: OutlineTextTrimmer(parser: OutlineParser()),
                                          eventObserver: eventObserver,
                                          settingAccessor: SettingsAccessor.shared,
                                          syncManager: syncManager,
                                          attachmentManager: AttachmentManager(),
                                          urlHandlerManager: URLHandlerManager(documentManager: documentManager,
                                                                               eventObserver: eventObserver),
                                          globalCaptureEntryWindow: _entranceWindow))
        
        self.window?.rootViewController = self.stack
        
        _entranceWindow.entryAction = { [weak self] in
            self?.showCaptureEntrance()
        }
        
        self._setupObservers()
    }
    
    private func _setupiCloud() {
        if SyncManager.status == .off {
            // 用户已关闭 iCloud，忽略
            return
        }
        
        let status = self.dependency.syncManager.updateCurrentiCloudAccountStatus()
        
        switch status {
        case .changed:
            if SyncManager.status == .on {
                // 开始同步 iCloud 文件
                self.dependency.syncManager.startMonitoringiCloudFileUpdateIfNeeded()
                
                self.stack.showAlert(title: "iCloud account changed", message: "You have login another iCloud account, your document is now access from that account's storage")
            }
        case .closed:
            if SyncManager.status == .on {
                self.stack.showAlert(title: "iCloud account closed", message: "You have turned off iCloud on this app, your documents are stored on the iCloud stoage safely, if you want to access them, please turn iCloud on")
                
                // mark iCloud off
                SyncManager.status = .off
            }
        case .open:
            if SyncManager.status == .unknown {
                let confirmViewController = ConfirmViewController()
                confirmViewController.contentText = "Do you want use iCloud to store, your documents. If so, you will be able to access the contents from any device with your iCloud account, and they will be kept safe if you remove the app, or even lose your device."
                
                confirmViewController.confirmAction = { viewController in
                    viewController.dismiss(animated: true, completion: {
                        self.dependency.syncManager.geticloudContainerURL(completion: { [unowned self] url in
                            SyncManager.status = .on
                            // 开始同步 iCloud 文件
                            self.dependency.syncManager.startMonitoringiCloudFileUpdateIfNeeded()
                            self.stack.showAlert(title: "Using iCloud storage", message: "Now everything is stored using iCloud, you can access them on all of your devices")
                        })
                    })
                }
                
                confirmViewController.cancelAction = { viewController in
                    viewController.dismiss(animated: true, completion: {
                        
                        SyncManager.status = .off

                        self.stack.showAlert(title: "Using local storage", message: "Now your are storing your document on this device only, if you want to move to iCloud, you can change is in the Settings")
                    })
                }
                
                self.stack.present(confirmViewController, animated: true, completion: nil)
            } else if SyncManager.status == .on {
                // 开始同步 iCloud 文件
                self.dependency.syncManager.startMonitoringiCloudFileUpdateIfNeeded()
            }
        }
    }
    
    private func _setupObservers() {
        self.dependency.eventObserver.registerForEvent(on: self, eventType: ImportFileEvent.self, queue: nil) { [weak self] (event: ImportFileEvent) -> Void in
            self?.topCoordinator?.openDocument(url: event.url, location: 0)
        }
    }
    
    deinit {
        self.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    public override func start(from: Coordinator?, animated: Bool) {
        let homeCoord = HomeCoordinator(stack: self.stack,
                                        dependency: self.dependency)
        homeCoord.start(from: self, animated: animated)
        
        self._setupiCloud()
    }
}

extension Coordinator {
    public static func createDefaultNavigationControlller() -> UINavigationController {
        let navigationController = UINavigationController()
        navigationController.navigationBar.tintColor = InterfaceTheme.Color.interactive
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.interactive]
        return navigationController
    }
}
