//
//  ActionRequestHandler.swift
//  CaptureActionExtension
//
//  Created by ian luo on 2019/8/18.
//  Copyright © 2019 wod. All rights reserved.
//

import UIKit
import MobileCoreServices
import Core
import RxSwift

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    var extensionContext: NSExtensionContext?
    
    let shareExtensionItemHandler: ShareExtensionItemHandler = ShareExtensionItemHandler()
    
    private let disposeBag = DisposeBag()
    
    func beginRequest(with context: NSExtensionContext) {
        // Do not call super in an Action extension with no user interface
        self.extensionContext = context
        
        print("did tap capture action: \(context.inputItems)")

        if let items = context.inputItems as? [NSExtensionItem] {
            Observable.zip(items.map { item in
                shareExtensionItemHandler.handleExtensionItem(item.attachments ?? [])
            }).subscribe().disposed(by: self.disposeBag)
        }
    }
}
