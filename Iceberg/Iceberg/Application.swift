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
import RxSwift
import RxCocoa

public class Application: Coordinator {
    weak var window: UIWindow?
    private let _entranceWindow: CaptureGlobalEntranceWindow
    fileprivate var _didTheUserTurnOffiCloudFromSettings: Bool = false
    private let disposeBag = DisposeBag()
    
    public let isFileReadyToAccess: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    public let uiStackReady: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    public lazy var startComplete: Observable<Bool> =  Observable.combineLatest(isFileReadyToAccess, uiStackReady).map { isFileReady, isUIReady in
        return isFileReady && isUIReady
    }

    public init(window: UIWindow) {
        self.window = window
        
        _entranceWindow = CaptureGlobalEntranceWindow(window: window)
        
        _entranceWindow.makeKeyAndVisible()

        let navigationController = Coordinator.createDefaultNavigationControlller()
        
        let eventObserver = EventObserver()
        let editorContext = EditorContext(eventObserver: eventObserver)
        let syncManager = iCloudDocumentManager(eventObserver: eventObserver)
        
        // if the user turn off iCloud from settings, this sign must be set here
        if syncManager.refreshCurrentiCloudAccountStatus() == .closed {
            if iCloudDocumentManager.status == .on {
                iCloudDocumentManager.status = .off
                self._didTheUserTurnOffiCloudFromSettings = true
            }
        }
        let documentManager = DocumentManager(editorContext: editorContext,
                                              eventObserver: eventObserver,
                                              syncManager: syncManager)
        let attachmentManager = AttachmentManager()
        
        super.init(stack: navigationController,
                   dependency: Dependency(documentManager: documentManager,
                                          documentSearchManager: DocumentSearchManager(eventObserver: eventObserver, editorContext: editorContext),
                                          editorContext: editorContext,
                                          textTrimmer: OutlineTextTrimmer(parser: OutlineParser()),
                                          eventObserver: eventObserver,
                                          settingAccessor: SettingsAccessor.shared,
                                          syncManager: syncManager,
                                          attachmentManager: attachmentManager,
                                          urlHandlerManager: URLHandlerManager(documentManager: documentManager, eventObserver: eventObserver),
                                          shareExtensionHandler: ShareExtensionDataHandler(),
                                          captureService: CaptureService(attachmentManager: attachmentManager),
                                          exportManager: ExportManager(editorContext: editorContext),
                                          globalCaptureEntryWindow: _entranceWindow,
                                          activityHandler: ActivityHandler()))
        
        self.window?.rootViewController = self.stack
        
        _entranceWindow.entryAction = { [weak self] in
            self?.showCaptureEntrance()
        }
        
        self._setupObservers()
    }
    
    private func _setupObservers() {
        self.dependency.eventObserver.registerForEvent(on: self, eventType: ImportFileEvent.self, queue: nil) { [weak self] (event: ImportFileEvent) -> Void in
            self?.topCoordinator?.openDocument(url: event.url, location: 0)
            self?.dependency.eventObserver.emit(AddDocumentEvent(url: event.url))
        }
        
        self.dependency.eventObserver.registerForEvent(on: self, eventType: iCloudEnabledEvent.self, queue: nil) { [weak self] (event: iCloudEnabledEvent) -> Void in
            self?._setupiCloud()
        }
    }
    
    deinit {
        self.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    public override func start(from: Coordinator?, animated: Bool) {
        let homeCoord = HomeCoordinator(stack: self.stack,
                                        dependency: self.dependency)
        
        // 设置 iCloud
        self._setupiCloud()
        
        // 导入 extension 收集的 idea
        self.handleSharedIdeas()
        
        // 设置主题, set up the theme when the settings file is ready
        uiStackReady.subscribe(onNext: { [weak self] in
            if $0 {
                self?.viewController?.navigationController?.setupTheme()
            }
        }).disposed(by: self.disposeBag)

        // 通知完成初始化
        self.dependency.eventObserver.emit(AppStartedEvent())
        
        dependency.documentManager.getFileLocationComplete { [weak self] url in
            guard let url = url else { return }
            guard let s = self else { return }
            
            log.info("using \(url) as root")
            
            homeCoord.start(from: self, animated: animated)
            
            // UI complete loading
            s.uiStackReady.accept(true)
            
        }
        
    }
    
    private var _isHandlingSharedIdeas: Bool = false
    public func handleSharedIdeas() {
        // 避免正在处理的过程中，重复处理
        guard _isHandlingSharedIdeas == false else { return }
        _isHandlingSharedIdeas = true
        
        let handler = self.dependency.shareExtensionHandler
        
        handler.harvestSharedItems(attachmentManager: self.dependency.attachmentManager,
                                   urlHandler: self.dependency.urlHandlerManager,
                                   captureService: self.dependency.captureService) { ideasCount in
                                    
                                    if ideasCount > 0 {
                                        self.dependency.eventObserver.emit(NewCaptureAddedEvent(attachmentId: "", kind: ""))
                                    }
                                    
                                    self._isHandlingSharedIdeas = false
        }
    }
    
    private func _setupiCloud() {
        let status = self.dependency.syncManager.refreshCurrentiCloudAccountStatus()
        
        switch status {
        case .changed:
            if iCloudDocumentManager.status == .on {
                self.dependency.syncManager.geticloudContainerURL(completion: { [unowned self] url in
                    // 开始同步 iCloud 文件
                    self.dependency.syncManager.startMonitoringiCloudFileUpdateIfNeeded()
                    
                    self.stack.showAlert(title: L10n.Sync.Alert.Account.Changed.title, message: L10n.Sync.Alert.Account.Changed.msg)
                    
                    self.dependency.eventObserver.emit(iCloudAvailabilityChangedEvent(isEnabled: true))
                    
                    self.isFileReadyToAccess.accept(true)
                })
            }
        case .closed:
            if self._didTheUserTurnOffiCloudFromSettings {
                self.stack.showAlert(title: L10n.Sync.Alert.Account.Closed.title, message: L10n.Sync.Alert.Account.Closed.msg)
            }
            
            // mark iCloud off
            iCloudDocumentManager.status = .off
            
            self.dependency.eventObserver.emit(iCloudAvailabilityChangedEvent(isEnabled: false))
            
            self.isFileReadyToAccess.accept(true)
        case .open:
            if iCloudDocumentManager.status == .unknown {
                let confirmViewController = ConfirmViewController()
                confirmViewController.contentText = L10n.Sync.Confirm.useiCloud
                
                confirmViewController.confirmAction = { viewController in
                    viewController.dismiss(animated: true, completion: {
                        self.dependency.syncManager.geticloudContainerURL(completion: { [unowned self] url in
                            iCloudDocumentManager.status = .on
                            // 开始同步 iCloud 文件
                            self.dependency.syncManager.startMonitoringiCloudFileUpdateIfNeeded()
                            self.stack.showAlert(title: L10n.Sync.Alert.Status.On.title, message: L10n.Sync.Alert.Status.On.msg)
                            
                            self.dependency.eventObserver.emit(iCloudAvailabilityChangedEvent(isEnabled: true))
                            
                            self.isFileReadyToAccess.accept(true)
                        })
                    })
                }
                
                confirmViewController.cancelAction = { viewController in
                    viewController.dismiss(animated: true, completion: {
                        
                        iCloudDocumentManager.status = .off

                        self.stack.showAlert(title: L10n.Sync.Alert.Status.Off.title, message: L10n.Sync.Alert.Status.Off.msg)
                        
                        self.dependency.eventObserver.emit(iCloudAvailabilityChangedEvent(isEnabled: false))
                        
                        self.isFileReadyToAccess.accept(true)
                    })
                }
                
                self.stack.present(confirmViewController, animated: true, completion: nil)
            } else if iCloudDocumentManager.status == .on {
                
                self.dependency.syncManager.geticloudContainerURL(completion: { [unowned self] url in
                    // 开始同步 iCloud 文件
                    self.dependency.syncManager.startMonitoringiCloudFileUpdateIfNeeded()
                    self.dependency.eventObserver.emit(iCloudAvailabilityChangedEvent(isEnabled: true))
                    
                    self.isFileReadyToAccess.accept(true)
                })
            }
        }
    }
}

extension Coordinator {
    public static func createDefaultNavigationControlller(root: UIViewController? = nil) -> UINavigationController {
        let navigationController = UINavigationController()
        
        if let root = root {
            navigationController.pushViewController(root, animated: false)
        }
        
        navigationController.interface { (me, theme) in
            let navigationController = me as! UINavigationController
            navigationController.navigationBar.tintColor = theme.color.interactive
            navigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: theme.color.interactive]
            navigationController.navigationBar.backIndicatorImage = Asset.Assets.left.image.fill(color: theme.color.descriptive)
            navigationController.navigationBar.backIndicatorTransitionMaskImage = Asset.Assets.left.image
        }
        
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        return navigationController
    }
}

extension UINavigationController {
    open override func resignFirstResponder() -> Bool {
        return self.topViewController?.resignFirstResponder() ?? false
    }
}

extension UINavigationController {
    open override var childForStatusBarStyle: UIViewController? {
        topViewController
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return InterfaceTheme.statusBarStyle
    }
}

extension UIViewController {
    public var currentInterfaceStye: SettingsAccessor.InterfaceStyle {
        if SettingsAccessor.shared.interfaceStyle == .auto {
            if #available(iOS 13, *) {
                return .auto // 之后 13 以后才显示 auto
            } else {
                return .light // 默认为 light
            }
        } else {
            return SettingsAccessor.shared.interfaceStyle
        }
    }
    
    public var interfaceTheme: InterfaceThemeProtocol {
        switch currentInterfaceStye {
        case .light:
            return LightInterfaceTheme()
        case .dark:
            return DarkInterfaceTheme()
        case .auto:
            if #available(iOS 12.0, *) {
                switch self.traitCollection.userInterfaceStyle {
                case .dark:
                    return DarkInterfaceTheme()
                case .light:
                    return LightInterfaceTheme()
                case .unspecified:
                    return LightInterfaceTheme() // default to light
                }
            } else {
                return LightInterfaceTheme() // default to light
            }
        }
    }
    
    public var oultineTheme: OutlineThemeConfigProtocol {
        return OutlineThemeStyle(theme: interfaceTheme)
    }
    
    public func setupTheme() {
        let theme = interfaceTheme
        
        let newOutlineTheme: OutlineThemeConfigProtocol = OutlineThemeStyle(theme: theme)
        OutlineThemeSelector.shared.changeTheme(newOutlineTheme)
        
        InterfaceThemeSelector.shared.changeTheme(theme)
        
        self.interface { (viewController, interface) in
            viewController.setNeedsStatusBarAppearanceUpdate()
        }
    }
}
