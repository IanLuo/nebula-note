//
//  ShareViewController.swift
//  CaptureIdeaExtension
//
//  Created by ian luo on 2019/6/24.
//  Copyright © 2019 wod. All rights reserved.
//

import UIKit
import Social
import Core

class ShareViewController: SLComposeServiceViewController {
    
    private let _extensionItemHandler: ShareExtensionItemHandler = ShareExtensionItemHandler()

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }
    
    override func viewDidLoad() {
//        self.textView.isHidden = true
    }
    
    override func didSelectPost() {
        let group = DispatchGroup()
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            for item in self.extensionContext?.inputItems ?? [] {
                if let item = item as? NSExtensionItem {
                    group.enter()
                    self._extensionItemHandler.handleExtensionItem(item, userInput: self.textView.text) {
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: DispatchQueue.main) {
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        }
        
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
