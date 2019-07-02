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
        
        _entranceWindow = CaptureGlobalEntranceWindow(window: window)
        
        _entranceWindow.makeKeyAndVisible()

        let navigationController = Coordinator.createDefaultNavigationControlller()
        
        let eventObserver = EventObserver()
        let editorContext = EditorContext(eventObserver: eventObserver)
        let syncManager = SyncManager(eventObserver: eventObserver)
        let documentManager = DocumentManager(editorContext: editorContext,
                                              eventObserver: eventObserver,
                                              syncManager: syncManager)
        let attachmentManager = AttachmentManager()
        
        super.init(stack: navigationController,
                   dependency: Dependency(documentManager: documentManager,
                                          documentSearchManager: DocumentSearchManager(eventObserver: eventObserver,
                                                                                       editorContext: editorContext),
                                          editorContext: editorContext,
                                          textTrimmer: OutlineTextTrimmer(parser: OutlineParser()),
                                          eventObserver: eventObserver,
                                          settingAccessor: SettingsAccessor.shared,
                                          syncManager: syncManager,
                                          attachmentManager: attachmentManager,
                                          urlHandlerManager: URLHandlerManager(documentManager: documentManager,
                                                                               eventObserver: eventObserver),
                                          shareExtensionHandler: ShareExtensionDataHandler(),
                                          captureService: CaptureService(attachmentManager: attachmentManager),
                                          exportManager: ExportManager(editorContext: editorContext),
                                          globalCaptureEntryWindow: _entranceWindow))
        
        self.window?.rootViewController = self.stack
        
        _entranceWindow.entryAction = { [weak self] in
            self?.showCaptureEntrance()
        }
        
        self._setupObservers()
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
        
        self.dependency.documentManager.getFileLocationComplete { _ in
            InterfaceThemeSelector.shared.changeTheme(
                SettingsAccessor.shared.isDarkInterfaceOn
                    ? DarkInterfaceTheme()
                    : LightInterfaceTheme()
            )
        }
        
        self._setupiCloud()
        
        self.handleSharedIdeas()
        
        self.dependency.eventObserver.emit(AppStartedEvent())
    }
    
    var isHandlingSharedIdeas: Bool = false
    public func handleSharedIdeas() {
        guard isHandlingSharedIdeas == false else { return }
        isHandlingSharedIdeas = true
        
        let handler = self.dependency.shareExtensionHandler
        let group = DispatchGroup()
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            let ideas = handler.loadAllUnHandledShareIdeas()
            let ideasCount = ideas.count
            for url in ideas {
                let attachmentKindString = url.deletingPathExtension().pathExtension // kind 已经在保存的时候，添加成为了 url 的前一个 ext
                if let kind = Attachment.Kind(rawValue: attachmentKindString) {
                    var content = url.path
                    switch kind {
                    case .text: fallthrough
                    case .link: fallthrough
                    case .location: 
                    content = try! String(contentsOf: url)
                    default: break
                    }
                    
                    group.enter()
                    self.dependency.attachmentManager.insert(content: content, kind: kind, description: "shared idea", complete: { [weak self] key in
                        self?.dependency.captureService.save(key: key, completion: {
                            group.leave()
                        })
                    }) { error in
                        group.leave()
                        log.error(error)
                    }
                }
            }
            
            group.notify(queue: DispatchQueue.main) {
                handler.clearAllSharedIdeas()
                if ideasCount > 0 {
                    self.dependency.eventObserver.emit(NewCaptureAddedEvent(attachmentId: "", kind: ""))
                }
                self.isHandlingSharedIdeas = false
            }
        }
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
}

extension Coordinator {
    public static func createDefaultNavigationControlller() -> UINavigationController {
        let navigationController = UINavigationController()
        
        navigationController.interface { (me, theme) in
            let navigationController = me as! UINavigationController
            navigationController.navigationBar.tintColor = theme.color.interactive
            navigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: theme.color.interactive]
            navigationController.navigationBar.backIndicatorImage = Asset.Assets.left.image.fill(color: theme.color.descriptive)
            navigationController.navigationBar.backIndicatorTransitionMaskImage = Asset.Assets.left.image
        }
        
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: -500, vertical: 0), for: UIBarMetrics.default)
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        return navigationController
    }
}

extension UINavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return InterfaceTheme.statusBarStyle
    }
}
