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
                                                                    y: UIScreen.main.bounds.height - window.safeArea.bottom - 60 - 30,
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
                
                self.stack.showAlert(title: L10n.Sync.Alert.Account.Changed.title, message: L10n.Sync.Alert.Account.Changed.msg)
            }
        case .closed:
            if SyncManager.status == .on {
                self.stack.showAlert(title: L10n.Sync.Alert.Account.Closed.title, message: L10n.Sync.Alert.Account.Closed.msg)
                
                // mark iCloud off
                SyncManager.status = .off
            }
        case .open:
            if SyncManager.status == .unknown {
                let confirmViewController = ConfirmViewController()
                confirmViewController.contentText = L10n.Sync.Confirm.useiCloud
                
                confirmViewController.confirmAction = { viewController in
                    viewController.dismiss(animated: true, completion: {
                        self.dependency.syncManager.geticloudContainerURL(completion: { [unowned self] url in
                            SyncManager.status = .on
                            // 开始同步 iCloud 文件
                            self.dependency.syncManager.startMonitoringiCloudFileUpdateIfNeeded()
                            self.stack.showAlert(title: L10n.Sync.Alert.Status.On.title, message: L10n.Sync.Alert.Status.On.msg)
                        })
                    })
                }
                
                confirmViewController.cancelAction = { viewController in
                    viewController.dismiss(animated: true, completion: {
                        
                        SyncManager.status = .off

                        self.stack.showAlert(title: L10n.Sync.Alert.Status.Off.title, message: L10n.Sync.Alert.Status.Off.msg)
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
