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
import RxSwift
import RxCocoa
import Interface

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
    lazy var editorContext: EditorContext = { EditorContext(eventObserver: eventObserver, settingsAccessor: settingAccessor) }()
    lazy var textTrimmer: OutlineTextTrimmer = { OutlineTextTrimmer(parser: OutlineParser()) }()
    lazy var eventObserver: EventObserver = { EventObserver() }()
    lazy var settingAccessor: SettingsAccessor = { SettingsAccessor.shared }()
    lazy var syncManager: iCloudDocumentManager = { iCloudDocumentManager(eventObserver: eventObserver) }()
    lazy var attachmentManager: AttachmentManager = { AttachmentManager() }()
    lazy var urlHandlerManager: URLHandlerManager = { URLHandlerManager(documentManager: documentManager, eventObserver: eventObserver) }()
    lazy var shareExtensionHandler: ShareExtensionDataHandler = { ShareExtensionDataHandler() }()
    lazy var sharedDataHandler: ShareExtensionDataHandler = { ShareExtensionDataHandler() }()
    lazy var captureService: CaptureService = { CaptureService(attachmentManager: attachmentManager) }()
    lazy var exportManager: ExportManager = { ExportManager(editorContext: editorContext) }()
    weak var globalCaptureEntryWindow: CaptureGlobalEntranceWindow?
    lazy var activityHandler: ActivityHandler = { ActivityHandler() }()
    lazy var purchaseManager: PurchaseManager = { PurchaseManager() }()
    lazy var userGuideService: UserGuideService = { UserGuideService() }()
    lazy var publishFactory: PublishFactory = PublishFactory()
    lazy var storeContainer: StoreContainer = StoreContainer.shared
}

public class Coordinator {
    private let id: String = UUID().uuidString
    public var children: [Coordinator] = []
    public let stack: UINavigationController
    
    open func didMoveIn() {}
    
    open func didMoveOut() {}
    
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
    
    public var fromView: UIView?
    
    public var fromLocation: CGPoint?
    
    public var dependency: Dependency
    
    public var onMovingOut: (() -> Void)?
    
    public var isShowing: Bool {
        return self.topViewController?.view.window != nil
    }
    
    var accessoryData: [String: Any]?
    
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
        
        if let transitionViewController = top as? TransitionViewController {
            transitionViewController.dismiss(animated: true) {
                completion?()
                self.didMoveOut()
            }
        } else if self.stack == parent?.stack {
            self.stack.popViewController(animated: animated)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                completion?()
                self.didMoveOut()
            }
        } else {
            self.stack.presentingViewController?.dismiss(animated: animated,
                                                         completion: {
                                                            completion?()
                                                            self.didMoveOut()
            })
        }
    }
    
    open func moveIn(top: UIViewController?, animated: Bool) {
        if let viewController = self.viewController {
            if self.stack == self.parent?.stack {
                self.stack.pushViewController(viewController,
                                              animated: animated)
                
                self.index = self.parent!.index + 1
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                    self.didMoveIn()
                }
            } else { // means it's a modal
                self.isModal = true
                
                if let transitionViewController = viewController as? TransitionViewController, let top = top {
                    let fromView: UIView = self.fromView ?? transitionViewController.view
                    transitionViewController.present(from: top, at: fromView, location: self.fromLocation ?? CGPoint(x: fromView.bounds.midX, y: fromView.bounds.midY))
                } else {
                    self.stack.pushViewController(viewController,animated: false)
                    self.stack.modalPresentationStyle = viewController.modalPresentationStyle
                    self.stack.transitioningDelegate = viewController.transitioningDelegate
                    self.stack.preferredContentSize = viewController.preferredContentSize
                    
                    if let sourceRect = viewController.popoverPresentationController?.sourceRect {
                        self.stack.popoverPresentationController?.sourceRect = sourceRect
                    }
                    self.stack.popoverPresentationController?.sourceView = viewController.popoverPresentationController?.sourceView
                    top?.present(self.stack, animated: animated, completion: {
                        self.didMoveIn()
                    })
                }
                
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
            
            if #available(iOS 13, *) {
                self.viewController?.addKeyCommand(KeyBinding().create(for: KeyAction.cancel))
            }
            
            self.moveIn(top: f.topViewController, animated: animated)
        }
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
    
    public var allCoordinatorsInBranch: [Coordinator] {
        var allCoordinatorsInBranch: [Coordinator] = [self]
        
        for c in self.children {
            allCoordinatorsInBranch.append(contentsOf: c.allCoordinatorsInBranch)
        }
        
        return allCoordinatorsInBranch
    }
    
    public var topMostCoordinator: Coordinator {
        let sorted = self.rootCoordinator.allCoordinatorsInBranch.sorted { (c1: Coordinator, c2: Coordinator) -> Bool in
            c1.level > c2.level
        }
        
        return sorted.first ?? self
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
        
    }
    
    public func didSelect(attachmentKind: Attachment.Kind, coordinator: CaptureCoordinator) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            coordinator.stop {
                
                if isMacOrPad {
                    self.fromView = coordinator.fromView
                    self.fromLocation = coordinator.fromLocation
                }
                
                if attachmentKind.isMemberFunction && !self.dependency.purchaseManager.isMember.value {
                    self.topCoordinator?.showMembership()
                    return
                }
                
                self.showAttachmentPicker(kind: attachmentKind, at: self.fromView, location: self.fromLocation, complete: { [weak self] attachmentId in
                    coordinator.addAttachment(attachmentId: attachmentId) {
                        DispatchQueue.runOnMainQueueSafely {
                            self?.topCoordinator?.viewController?.toastSuccess()
                            self?.dependency.eventObserver.emit(NewCaptureAddedEvent(attachmentId: attachmentId, kind: attachmentKind.rawValue))
                        }
                    }
                }, cancel: {})
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
