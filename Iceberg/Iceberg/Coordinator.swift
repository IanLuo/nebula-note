//
//  Coordinator.swift
//  Iceland
//
//  Created by ian luo on 2019/4/22.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import PKHUD
import RxSwift
import RxCocoa

public struct AppContext {
    public let isFileReadyToAccess: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    public let uiStackReady: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    public lazy var startComplete: Observable<Bool> = Observable.combineLatest(isFileReadyToAccess, uiStackReady).map { isFileReady, isUIReady in
        return isFileReady && isUIReady
    }
    public let isReadingMode: BehaviorRelay<Bool> = BehaviorRelay(value: false)
}

public class Dependency {
    lazy var appContext: AppContext = { AppContext() }()
    lazy var documentManager: DocumentManager = { DocumentManager(editorContext: editorContext, eventObserver: eventObserver, syncManager: syncManager) }()
    lazy var documentSearchManager: DocumentSearchManager = { DocumentSearchManager() }()
    lazy var editorContext: EditorContext = { EditorContext(eventObserver: eventObserver) }()
    lazy var textTrimmer: OutlineTextTrimmer = { OutlineTextTrimmer(parser: OutlineParser()) }()
    lazy var eventObserver: EventObserver = { EventObserver() }()
    lazy var settingAccessor: SettingsAccessor = { SettingsAccessor.shared }()
    lazy var syncManager: iCloudDocumentManager = { iCloudDocumentManager(eventObserver: eventObserver) }()
    lazy var attachmentManager: AttachmentManager = { AttachmentManager() }()
    lazy var urlHandlerManager: URLHandlerManager = { URLHandlerManager(documentManager: documentManager, eventObserver: eventObserver) }()
    lazy var shareExtensionHandler: ShareExtensionDataHandler = { ShareExtensionDataHandler() }()
    lazy var captureService: CaptureService = { CaptureService(attachmentManager: attachmentManager) }()
    lazy var exportManager: ExportManager = { ExportManager(editorContext: editorContext) }()
    weak var globalCaptureEntryWindow: CaptureGlobalEntranceWindow?
    lazy var activityHandler: ActivityHandler = { ActivityHandler() }()
    lazy var purchaseManager: PurchaseManager = { PurchaseManager() }()
    lazy var userGuideService: UserGuideService = { UserGuideService() }()
}

public class Coordinator {
    private let id: String = UUID().uuidString
    public var children: [Coordinator] = []
    public let stack: UINavigationController
    
    /// modal level
    public private(set) var level: Int = 0
    
    /// navigation index
    public private(set) var index: Int = 0
    
    private let disposeBag = DisposeBag()
    
    public var viewController: UIViewController? {
        didSet {
            // if the viewController dealocated in other way, like dismissed by other action, remove this coordinator from it's parent
            if let viewController = viewController {
                viewController.rx.methodInvoked(#selector(UIViewController.viewDidDisappear(_:))).map { $0.first as? Bool ?? false }.subscribe(onNext: { [weak self] value in
                    if self?.parent != nil && value && viewController.presentingViewController == nil && self?.isModal == true {
                        self?.removeFromParent()
                    }
                }).disposed(by: self.disposeBag)
            }
        }
    }
    
    public var isModal: Bool = false
    
    public weak var parent: Coordinator?
    
    public var dependency: Dependency
    
    public var onMovingOut: (() -> Void)?
    
    public var isShowing: Bool {
        return self.topViewController?.view.window != nil
    }
    
    public init(stack: UINavigationController,
                dependency: Dependency) {
        self.stack = stack
        self.dependency = dependency
    }
    
    public func addChild(_ coord: Coordinator) {
        self.children.append(coord)
        coord.parent = self
    }
    
    public func remove(_ coord: Coordinator) {
        for (index, child) in self.children.enumerated() {
            if child.id == coord.id {
                self.children.remove(at: index)
            }
        }
    }
    
    open func moveOut(top: UIViewController, animated: Bool, completion: (() -> Void)?) {
        
        self.onMovingOut?()
        
        if self.stack == parent?.stack {
            self.stack.popViewController(animated: animated)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                completion?()
            }
        } else {
            self.stack.presentingViewController?.dismiss(animated: animated,
                                                         completion: completion)
        }
    }
    
    open func moveIn(top: UIViewController?, animated: Bool) {
        if let viewController = self.viewController {
            if self.stack == self.parent?.stack {
                self.stack.pushViewController(viewController,
                                              animated: animated)
                
                self.index = self.parent!.index + 1
            } else { // means it's a modal
                self.isModal = true
                self.stack.pushViewController(viewController,
                                              animated: false)
                
                self.stack.modalPresentationStyle = viewController.modalPresentationStyle
                self.stack.transitioningDelegate = viewController.transitioningDelegate
                
                top?.present(self.stack, animated: animated, completion: nil)
                
                self.level = self.parent!.level + 1
            }
        }
    }
    
    @objc public func stop(animated: Bool = true, completion: (() -> Void)? = nil) {
        if let viewController = self.viewController {
            self.moveOut(top: viewController, animated: animated, completion: {
                self.removeFromParent()
                completion?()
            })
        }
    }
    
    public func removeFromParent() {
        self.parent?.remove(self)
        self.parent = nil
    }
    
    open func start(from: Coordinator?, animated: Bool = true) {
        if let f = from {
            f.addChild(self)
            self.moveIn(top: f.topViewController, animated: animated)
        }
    }
}

extension Coordinator {
    public func openDocument(url: URL, location: Int) {
        let navigationController = Coordinator.createDefaultNavigationControlller(transparentBar: false)
        
        let documentCoordinator = EditorCoordinator(stack: navigationController, dependency: self.dependency,
                                                    usage: EditorCoordinator.Usage.editor(url, location))
        
        documentCoordinator.start(from: self)
        self.dependency.globalCaptureEntryWindow?.isForcedToHide = true
    }
    
    public func showAttachmentPicker(kind: Attachment.Kind, complete: @escaping (String) -> Void, cancel: @escaping () -> Void) {
        
        switch kind {
        case .video:
            guard UIImagePickerController.isCameraDeviceAvailable(UIImagePickerController.CameraDevice.rear) || UIImagePickerController.isCameraDeviceAvailable(UIImagePickerController.CameraDevice.front) else {
                let alert = UIAlertController(title: "Camera is not available", message: nil, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.topCoordinator?.viewController?.present(alert, animated: true, completion: nil)
                cancel()
                return
            }
        default: break
        }
        
        
        let navigationController = Coordinator.createDefaultNavigationControlller()
        
        let attachmentCoordinator = AttachmentCoordinator(stack: navigationController,
                                                          dependency: self.dependency,
                                                          kind: kind)
        attachmentCoordinator.onSaveAttachment = complete
        attachmentCoordinator.onCancel = cancel
        
        if let topCoordinator = self.topCoordinator {
            attachmentCoordinator.start(from: topCoordinator)
        } else {
            log.error("can't find a coordinator to start")
        }
    }
    
    public func showCaptureEntrance() {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        
        let captureCoordinator = CaptureCoordinator(stack: navigationController, dependency: self.dependency)
        captureCoordinator.delegate = self
        
        if let topCoordinator = self.topCoordinator {
            captureCoordinator.start(from: topCoordinator)
            self.dependency.globalCaptureEntryWindow?.hide()
            log.info("showing capture entry on top of: \(topCoordinator)")
        } else {
            log.error("can't find a coordinator to start \n\(self.debugDescription)")
        }
    }
    
    public func showDateSelector(title: String,
                                 current: DateAndTimeType?,
                                 add: @escaping (DateAndTimeType) -> Void,
                                 delete: @escaping () -> Void,
                                 cancel: @escaping () -> Void) {
        
        self.dependency.globalCaptureEntryWindow?.hide()
        
        let dateAndTimeSelectViewController = DateAndTimeSelectViewController(nibName: "DateAndTimeSelectViewController", bundle: nil)
        dateAndTimeSelectViewController.title = title
        dateAndTimeSelectViewController.passInDateAndTime = current
        dateAndTimeSelectViewController.didSelectAction = { [unowned dateAndTimeSelectViewController] dateAndTime in
            dateAndTimeSelectViewController.dismiss(animated: true, completion: {
                self.dependency.globalCaptureEntryWindow?.show()
            })
            
            add(dateAndTime)
        }
        
        dateAndTimeSelectViewController.didDeleteAction = { [unowned dateAndTimeSelectViewController] in
            dateAndTimeSelectViewController.dismiss(animated: true, completion: {
                self.dependency.globalCaptureEntryWindow?.show()
            })
            
            delete()
        }
        
        dateAndTimeSelectViewController.didCancelAction = { [unowned dateAndTimeSelectViewController] in
            dateAndTimeSelectViewController.dismiss(animated: true, completion: {
                self.dependency.globalCaptureEntryWindow?.show()
            })
            
            cancel()
        }
        
        self.viewController?.present(dateAndTimeSelectViewController, animated: true, completion: nil)
    }
    
    public func showMembership() {
        let nav = Coordinator.createDefaultNavigationControlller()
        let membershipCoordinator = MembershipCoordinator(stack: nav, dependency: self.dependency)
        membershipCoordinator.start(from: self)
    }
    
    public func showAttachmentManager() {
        let attachmentManagerCoordinator = AttachmentManagerCoordinator(stack: self.stack, dependency: self.dependency)
        attachmentManagerCoordinator.start(from: self)
    }
}

extension Coordinator {
    public var rootCoordinator: Coordinator {
        var root: Coordinator = self
        
        while root.parent != nil {
            root = root.parent!
        }
        
        return root
    }
    
    public func searchFirstCoordinator<T: Coordinator>(type: T.Type) -> T? {
        for c in self.children {
            if c is T {
                return (c as! T)
            } else {
                return c.searchFirstCoordinator(type: type)
            }
        }
        
        return nil
    }
    
    public var topCoordinator: Coordinator? {
        if self.isShowing {
            return self
        } else {
            for child in self.children.reversed() {
                if let top = child.topCoordinator {
                    return top
                }
            }
        }
        
        return nil
    }
    
    // find the top view controller in this coordinator
    public var topViewController: UIViewController? {
        if let presented = self.viewController?.presentedViewController {
            return presented // FIXME: only go 2 levels
        } else {
            return self.viewController
        }
    }
}

extension Coordinator: CaptureCoordinatorDelegate {
    public func didCancel(coordinator: CaptureCoordinator) {
        
        if !(self is EditorCoordinator) {
            self.dependency.globalCaptureEntryWindow?.show()
        }
    }
    
    public func didSelect(attachmentKind: Attachment.Kind, coordinator: CaptureCoordinator) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            coordinator.stop {
                
                if attachmentKind.isMemberFunction && !self.dependency.purchaseManager.isMember.value {
                    self.topCoordinator?.showMembership()
                    self.dependency.globalCaptureEntryWindow?.show()
                    return
                }
                
                self.showAttachmentPicker(kind: attachmentKind, complete: { [weak self] attachmentId in
                    self?.dependency.globalCaptureEntryWindow?.show()
                    coordinator.addAttachment(attachmentId: attachmentId) {
                        DispatchQueue.runOnMainQueueSafely {
                            HUD.flash(HUDContentType.success, delay: 1)
                            self?.dependency.eventObserver.emit(NewCaptureAddedEvent(attachmentId: attachmentId, kind: attachmentKind.rawValue))
                        }
                    }
                    }, cancel: { [weak self] in
                        self?.dependency.globalCaptureEntryWindow?.show()
                })
            }
        }
    }
}

extension Coordinator: CustomDebugStringConvertible {
    public var debugDescription: String {
        var string = "\n\(type(of:self)) \(level) \(index)\n\(vcs)"
        for child in self.children {
            string.append("\n | \(child.debugDescription)")
        }
        
        return "\(string)"
    }
    
    private var vcs: String {
        var string = "   ↳ "
        if let vc = self.viewController {
            string.append("\(vc))")
        }
        return string
    }
}
