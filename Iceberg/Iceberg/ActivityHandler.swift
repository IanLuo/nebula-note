//
//  ActivityHandler.swift
//  Iceberg
//
//  Created by ian luo on 2019/11/4.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Business
import RxSwift
import Interface

public class ActivityHandler {
    private let disposeBag = DisposeBag()
    
    public func handle(by application: Application, activity userActivity: NSUserActivity) -> Bool {
        switch userActivity.activityType {
        case createDocumentActivityType:
            application.startComplete.subscribe(onNext: { isComplete in
                guard isComplete else { return }
                for case let homeCoordinator in application.children where homeCoordinator is HomeCoordinator {
                    let homeCoordinator = homeCoordinator as! HomeCoordinator
                    homeCoordinator.selectOnDashboardTab(at: 3)
                    homeCoordinator.dependency.documentManager.add(title: L10n.Browser.Title.untitled, below: nil) { url in
                        if let top = homeCoordinator.topCoordinator, let url = url {
                            let editor = EditorCoordinator(stack: Coordinator.createDefaultNavigationControlller(),
                                                           dependency: top.dependency,
                                                           usage: EditorCoordinator.Usage.editor(url, 0))
                            editor.start(from: top)
                        }
                    }
                }
            }).disposed(by: self.disposeBag)
            return true
        default: return false
        }
    }
}
