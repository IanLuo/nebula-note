//
//  ActivityHandler.swift
//  Iceberg
//
//  Created by ian luo on 2019/11/4.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Core
import RxSwift
import Interface

public class ActivityHandler {
    private let disposeBag = DisposeBag()
    
    public func handle(by application: Application, activity userActivity: NSUserActivity) -> Bool {
        switch userActivity.activityType {
        case createDocumentActivityType:
            application.dependency.appContext.startComplete.subscribe(onNext: { isComplete in
                guard isComplete else { return }
                for case let homeCoordinator in application.children where homeCoordinator is HomeCoordinator {
                    let homeCoordinator = homeCoordinator as! HomeCoordinator
                    homeCoordinator.selectTab(.browser)
                    homeCoordinator.dependency.documentManager.add(title: L10n.Browser.Title.untitled, below: nil) { [unowned homeCoordinator] url in
                        if let top = homeCoordinator.topCoordinator, let url = url {
                            let editor = EditorCoordinator(stack: Coordinator.createDefaultNavigationControlller(),
                                                           dependency: top.dependency,
                                                           usage: EditorCoordinator.Usage.editor(url, 0))
                            editor.start(from: top)
                        } else if url == nil {
                            application.topCoordinator?.viewController?.showAlert(title: "Faild to create document", message: "")
                        }
                    }
                }
            }).disposed(by: self.disposeBag)
            return true
        case captureTextActivity:
            self.handleCapture(application: application, kind: Attachment.Kind.text)
            return true
        case captureImageActivity:
            self.handleCapture(application: application, kind: Attachment.Kind.image)
            return true
        case captureLocationActivity:
            self.handleCapture(application: application, kind: Attachment.Kind.location)
            return true
        case captureLinkActivity:
            self.handleCapture(application: application, kind: Attachment.Kind.link)
            return true
        case captureAudioActivity:
            self.handleCapture(application: application, kind: Attachment.Kind.audio)
            return true
        case captureVideoActivity:
            self.handleCapture(application: application, kind: Attachment.Kind.video)
            return true
        case captureSketchActivity:
            self.handleCapture(application: application, kind: Attachment.Kind.sketch)
            return true
        default: return false
        }
    }
    
    private func handleCapture(application: Application, kind: Attachment.Kind) {
        application.topCoordinator?.showAttachmentPicker(kind: kind, at: UIApplication.shared.windows.first, location: nil, complete: { [unowned application] attachmentId in
            application.dependency.captureService.save(key: attachmentId) { [application] in
                application.viewController?.toastSuccess()
            }
        }, cancel: {})
    }
}
