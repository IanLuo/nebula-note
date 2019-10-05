//
//  PreviewController.swift
//  Business
//
//  Created by ian luo on 2019/10/5.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import QuickLook

class PreviewDataSource: NSObject, QLPreviewControllerDataSource {
    let url: URL
    init(url: URL) {  self.url = url }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.url as QLPreviewItem
    }
}

class PreviewDelegate: NSObject, QLPreviewControllerDelegate {
    var keeper: Any?
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        keeper = nil
    }
}

public class PreviewManager {
    let dataSource: PreviewDataSource
    let delegate: PreviewDelegate
    
    public init(url: URL) {
        self.dataSource = PreviewDataSource(url: url)
        self.delegate = PreviewDelegate()
    }
    
    public func preview(from: UIViewController) {
        from.present(createPreviewController(), animated: true)
    }
    
    public func createPreviewController() -> QLPreviewController {
        let previewController = QLPreviewController()
        previewController.dataSource = self.dataSource
        previewController.delegate = self.delegate
        self.delegate.keeper = self
        
        return previewController
    }
    
}
