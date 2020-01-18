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

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    var extensionContext: NSExtensionContext?
    
    let shareExtensionItemHandler: ShareExtensionItemHandler = ShareExtensionItemHandler()
    
    func beginRequest(with context: NSExtensionContext) {
        // Do not call super in an Action extension with no user interface
        self.extensionContext = context
        
        print("did tap capture action: \(context.inputItems)")
        let group = DispatchGroup()
                
        for item in context.inputItems as! [NSExtensionItem] {
            group.enter()
             shareExtensionItemHandler.handleExtensionItem(item) {
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}
