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

        let navigationController = UINavigationController()
        navigationController.navigationBar.tintColor = InterfaceTheme.Color.interactive
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        
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
