//
//  Application.swift
//  Iceland
//
//  Created by ian luo on 2018/11/10.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface
import RxSwift
import RxCocoa

public class Application: Coordinator {
    weak var window: UIWindow?
    private var _entranceWindow: CaptureGlobalEntranceWindow?
    fileprivate var _didTheUserTurnOffiCloudFromSettings: Bool = false
    private let disposeBag = DisposeBag()
    var homeCoordinator: HomeCoordinator?
    
    public init(window: UIWindow) {
        self.window = window
        let dependency = Dependency()
        
        let navigationController = Coordinator.createDefaultNavigationControlller()
        
        if isMacOrPad {
            navigationController.navigationBar.isHidden = true
        }
        
        super.init(stack: navigationController, dependency: dependency)
        
        _entranceWindow = CaptureGlobalEntranceWindow(window: window)
        dependency.globalCaptureEntryWindow = self._entranceWindow
        
        // init entry window for iPhone
        if isPhone {
            _entranceWindow?.makeKeyAndVisible()
            _entranceWindow?.entryAction = { [weak self] in
                self?.showCaptureEntrance()
            }
        }
        
        
        // if the user turn off iCloud from settings, this sign must be set here
        if self.dependency.syncManager.refreshCurrentiCloudAccountStatus() == .closed {
            if iCloudDocumentManager.status == .on {
                iCloudDocumentManager.status = .off
                self._didTheUserTurnOffiCloudFromSettings = true
            }
        }
        
        self.window?.rootViewController = self.stack
        
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
        
        // 通知完成初始化
        self.dependency.appContext.startComplete.subscribe(onNext: { [weak self] isComplete in
            guard let strongSelf = self else { return }
            guard isComplete else { return }
            
            strongSelf.dependency.eventObserver.emit(AppStartedEvent())
            
            // when app start the first time, perform below actions
            if SettingsAccessor.Item.isFirstLaunchApp.get(Bool.self) ?? true {
                strongSelf.dependency
                    .userGuideService
                    .createGuideDocument(documentManager: strongSelf.dependency.documentManager)
                    .subscribe(onNext: { urls in
                        SettingsAccessor.Item.isFirstLaunchApp.set(false, completion: {})
                    })
                    .disposed(by: strongSelf.disposeBag)
            }
            
        }).disposed(by: self.disposeBag)
        
    }
    
    deinit {
        self.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    public override func start(from: Coordinator?, animated: Bool) {
        self.homeCoordinator = HomeCoordinator(stack: self.stack, dependency: self.dependency)
                
        // 导入 extension 收集的 idea
        self.handleSharedIdeas()
        
        // 设置主题, set up the theme when the settings file is ready
        self.dependency.appContext.uiStackReady.subscribe(onNext: { [weak self] in
            if $0 {
                self?.window?.rootViewController?.setupTheme()
            }
        }).disposed(by: self.disposeBag)
        
        dependency.documentManager.getFileLocationComplete { url in
            guard let url = url else { return }
            
            log.info("using \(url) as root")
        }
        
        self.homeCoordinator?.start(from: self, animated: false)
        
        // 设置 iCloud
        self._setupiCloud()
        
        DispatchQueue.main.async {
            self.dependency.appContext.uiStackReady.accept(true)
            self.dependency.eventObserver.emit(UIStackReadyEvent())
        }
    }
    
    private var _isHandlingSharedIdeas: Bool = false
    public func handleSharedIdeas() {
        // 避免正在处理的过程中，重复处理
        guard _isHandlingSharedIdeas == false else { return }
        _isHandlingSharedIdeas = true
        
        self.dependency.shareExtensionHandler.harvestSharedItems(attachmentManager: self.dependency.attachmentManager,
                                                                 urlHandler: self.dependency.urlHandlerManager,
                                                                 captureService: self.dependency.captureService)
            .subscribe(onNext: { ideasCount in
                if ideasCount > 0 {
                    self.dependency.eventObserver.emit(NewCaptureAddedEvent(attachmentId: "", kind: ""))
                }
                
                self._isHandlingSharedIdeas = false
            }).disposed(by: self.disposeBag)
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
                    
                    self.dependency.appContext.isFileReadyToAccess.accept(true)
                })
            }
        case .closed:
            if self._didTheUserTurnOffiCloudFromSettings {
                self.stack.showAlert(title: L10n.Sync.Alert.Account.Closed.title, message: L10n.Sync.Alert.Account.Closed.msg)
            }
            
            // mark iCloud off
            iCloudDocumentManager.status = .off
            
            self.dependency.eventObserver.emit(iCloudAvailabilityChangedEvent(isEnabled: false))
            
            self.dependency.appContext.isFileReadyToAccess.accept(true)
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
                            
                            self.dependency.appContext.isFileReadyToAccess.accept(true)
                        })
                    })
                }
                
                confirmViewController.cancelAction = { viewController in
                    viewController.dismiss(animated: true, completion: {
                        
                        iCloudDocumentManager.status = .off

                        self.stack.showAlert(title: L10n.Sync.Alert.Status.Off.title, message: L10n.Sync.Alert.Status.Off.msg)
                        
                        self.dependency.eventObserver.emit(iCloudAvailabilityChangedEvent(isEnabled: false))
                        
                        self.dependency.appContext.isFileReadyToAccess.accept(true)
                    })
                }
                
                self.dependency.appContext.uiStackReady.subscribe(onNext: {
                    guard $0 else { return }
                    confirmViewController.present(from: self.stack, at: self.stack.view)
                }).disposed(by: self.disposeBag)
            } else if iCloudDocumentManager.status == .on {
                
                self.dependency.syncManager.geticloudContainerURL(completion: { [unowned self] url in
                    // 开始同步 iCloud 文件
                    self.dependency.syncManager.startMonitoringiCloudFileUpdateIfNeeded()
                    self.dependency.eventObserver.emit(iCloudAvailabilityChangedEvent(isEnabled: true))
                    
                    self.dependency.appContext.isFileReadyToAccess.accept(true)
                })
                
                // means off
            } else {
                self.dependency.appContext.isFileReadyToAccess.accept(true)
            }
        }
    }
}

extension Coordinator {
    public static func createDefaultNavigationControlller(root: UIViewController? = nil, transparentBar: Bool = true) -> UINavigationController {
        let navigationController = UINavigationController()
        
        if let root = root {
            navigationController.pushViewController(root, animated: false)
        }
        
        navigationController.interface { (me, theme) in
            let navigationController = me as! UINavigationController
            navigationController.navigationBar.tintColor = theme.color.interactive
            navigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: theme.color.interactive]
            navigationController.navigationBar.backIndicatorImage = Asset.SFSymbols.chevronLeft.image.fill(color: theme.color.descriptive)
            navigationController.navigationBar.backIndicatorTransitionMaskImage = Asset.SFSymbols.chevronLeft.image
            navigationController.navigationBar.barTintColor = theme.color.background1
            
            if InterfaceTheme.isDartMode {
                navigationController.navigationBar.barStyle = .black
                if #available(iOS 13.0, *) {
                    navigationController.overrideUserInterfaceStyle = .dark
                }
            } else {
                navigationController.navigationBar.barStyle = .default
                if #available(iOS 13.0, *) {
                    navigationController.overrideUserInterfaceStyle = .light
                }
            }
        }
        
        if transparentBar {
            navigationController.navigationBar.shadowImage = UIImage()
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        }
        
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
                    return DarkInterfaceTheme() // default to light
                }
            } else {
                return DarkInterfaceTheme() // default to dark
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
