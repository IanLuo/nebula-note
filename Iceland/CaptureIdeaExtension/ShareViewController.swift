//
//  ShareViewController.swift
//  CaptureIdeaExtension
//
//  Created by ian luo on 2019/6/24.
//  Copyright © 2019 wod. All rights reserved.
//

import UIKit
import Social
import Business

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        let handler = ShareExtensionDataHandler()
        
        let containerURL = handler.sharedContainterURL
        
        if let item = self.extensionContext?.inputItems.first as? NSExtensionItem {
            if let attachment = item.attachments?.first {
                if attachment.hasItemConformingToTypeIdentifier("public.image") {
                    attachment.loadItem(forTypeIdentifier: "public.image", options: nil) { data, error in
                        if let data = data {
                            
                        }
                        
                        if let error = error {
                            print("ERROR: \(error)")
                        }
                    }
                }
            }
        }
        
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
