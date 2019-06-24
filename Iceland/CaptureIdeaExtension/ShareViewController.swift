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

    let handler = ShareExtensionDataHandler()
    
    override func didSelectPost() {
        
        
        if let item = self.extensionContext?.inputItems.first as? NSExtensionItem {
            for attachment in item.attachments ?? [] {
                if attachment.hasItemConformingToTypeIdentifier("public.image") {
                    self._saveImage(attachment: attachment)
                }
            }
        }
        
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
    private func _saveImage(attachment: NSItemProvider) {
        let containerURL = handler.sharedContainterURL

        attachment.loadItem(forTypeIdentifier: "public.image", options: nil) { data, error in
            if let image = data as? UIImage {
                let name = UUID().uuidString
                do {
                    try image.pngData()!.write(to: containerURL.appendingPathComponent(name).appendingPathExtension(Attachment.Kind.image.rawValue).appendingPathExtension("png"))
                    self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                } catch {
                    print("ERROR: \(error)")
                }
            } else if let imageURL = data as? NSURL {
                if let fileName = imageURL.lastPathComponent {
                    var newFileName = containerURL.appendingPathComponent(fileName)
                    let ext = newFileName.pathExtension
                    newFileName = newFileName.deletingPathExtension()
                    newFileName = newFileName.appendingPathExtension(Attachment.Kind.image.rawValue).appendingPathExtension(ext) // add attachment kind in the url, second to the ext
                    newFileName.writeBlock(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background), accessor: { error in
                        if let error = error {
                            print("ERROR: \(error)")
                        }
                        
                        do {
                            try FileManager.default.copyItem(at: imageURL as URL, to: newFileName)
                            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                        } catch {
                            print("ERROR: \(error)")
                        }
                    })
                }
            }
            
            if let error = error {
                print("ERROR: \(error)")
            }
        }

    }

}
