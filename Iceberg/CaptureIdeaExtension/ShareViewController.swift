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
import RxSwift

@objc(ShareViewController) class ShareViewController: SLComposeServiceViewController {
    
    private let _extensionItemHandler: ShareExtensionItemHandler = ShareExtensionItemHandler()

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
//        self.textView.isHidden = true
    }
    
    override func didSelectPost() {
        if let items = self.extensionContext?.inputItems as? [NSExtensionItem] {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                Observable.zip(items.map { item in
                    self._extensionItemHandler.handleExtensionItem(item.attachments ?? [], userInput: self.textView.text)
                })
                .subscribe(onCompleted: {
                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                })
                .disposed(by: self.disposeBag)
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
