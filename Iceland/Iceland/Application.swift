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
        
        self._setupiCloud()
    }
    
    private func _setupiCloud() {
        let status = self.dependency.syncManager.updateCurrentiCloudAccountStatus()
        
        switch status {
        case .changed:
            if self.dependency.syncManager.status == .on {
                self.dependency.eventObserver.emit(iCloudOpeningStatusChangedevent(isiCloudEnabled: true))
            }
        case .closed:
            if self.dependency.syncManager.status == .on {
                self.dependency.eventObserver.emit(iCloudOpeningStatusChangedevent(isiCloudEnabled: true))
            }
        case .open:
            if self.dependency.syncManager.status == .off {
                self.dependency.eventObserver.emit(iCloudOpeningStatusChangedevent(isiCloudEnabled: true))
            } else if self.dependency.syncManager.status == .unknown {
                
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
