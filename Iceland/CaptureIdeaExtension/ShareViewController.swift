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
        self.textView.isEditable = false
        if let item = self.extensionContext?.inputItems.first as? NSExtensionItem {
            for attachment in item.attachments ?? [] {
                let text = item.attributedContentText?.string ?? ""
                if attachment.hasItemConformingToTypeIdentifier("public.image") {
                    self._saveImage(attachment: attachment)
                } else if attachment.hasItemConformingToTypeIdentifier("public.movie") {
                    self._saveVideo(attachment: attachment)
                } else if attachment.hasItemConformingToTypeIdentifier("public.url") {
                    self._saveURL(attachment: attachment, text: text)
                } else if attachment.hasItemConformingToTypeIdentifier("public.text") {
                    self._saveText(attachment: attachment)
                } else {
                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
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
    
    private func _saveVideo(attachment: NSItemProvider) {
        attachment.loadItem(forTypeIdentifier: "public.movie", options: nil) { (data, error) in
            if let audioURL = data as? NSURL {
                self._saveFile(url: audioURL as URL, kind: Attachment.Kind.video)
            }
            
            if let error = error {
                print("ERROR: \(error)")
            }
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    private func _saveText(attachment: NSItemProvider) {
        attachment.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
            if let url = data as? NSURL {
                self._saveFile(url: url as URL, kind: Attachment.Kind.text)
            } else if let string = data as? String {
                let url = URL.file(directory: URL.directory(location: URLLocation.temporary), name: UUID().uuidString, extension: "txt")
                do {
                    try string.write(to: url, atomically: true, encoding: .utf8)
                    self._saveFile(url: url, kind: Attachment.Kind.text)
                } catch {
                    print("ERROR: \(error)")
                }
            }
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    private func _saveURL(attachment: NSItemProvider, text: String) {
        attachment.loadItem(forTypeIdentifier: "public.url", options: nil) { (data, error) in
            if let url = data as? URL {
                let tempURL = URL.file(directory: URL.directory(location: URLLocation.temporary), name: UUID().uuidString, extension: "txt")
                do {
                    let linkData: [String: Codable] = [
                        OutlineParser.Values.Attachment.Link.keyTitle: text,
                        OutlineParser.Values.Attachment.Link.keyURL: url.absoluteString
                    ]
                    let jsonEncoder = JSONEncoder()
                    let data = try jsonEncoder.encode(linkData)
                    let string = String(data: data, encoding: .utf8) ?? ""
                    try string.write(to: tempURL, atomically: true, encoding: .utf8)
                    self._saveFile(url: tempURL, kind: Attachment.Kind.link)
                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                } catch {
                    print("ERROR: \(error)")
                }
            }
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    private func _saveImage(attachment: NSItemProvider) {
        let containerURL = handler.sharedContainterURL

        attachment.loadItem(forTypeIdentifier: "public.image", options: nil) { data, error in
            if let image = data as? UIImage {
                let name = UUID().uuidString
                do {
                    try image.pngData()!.write(to: containerURL.appendingPathComponent(name).appendingPathExtension(Attachment.Kind.image.rawValue).appendingPathExtension("png"))
                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                } catch {
                    print("ERROR: \(error)")
                }
            } else if let imageURL = data as? NSURL {
                self._saveFile(url: imageURL as URL, kind: Attachment.Kind.image)
            }
            
            if let error = error {
                print("ERROR: \(error)")
            }
        }

    }
    
    private func _saveFile(url: URL, kind: Attachment.Kind) {
        let containerURL = handler.sharedContainterURL
        
        let fileName = url.lastPathComponent
        var newFileName = containerURL.appendingPathComponent(fileName)
        let ext = newFileName.pathExtension
        newFileName = newFileName.deletingPathExtension()
        newFileName = newFileName.appendingPathExtension(kind.rawValue).appendingPathExtension(ext) // add attachment kind in the url, second to the ext
        newFileName.writeBlock(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background), accessor: { error in
            if let error = error {
                print("ERROR: \(error)")
            }
            
            do {
                try FileManager.default.copyItem(at: url as URL, to: newFileName)
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            } catch {
                print("ERROR: \(error)")
            }
        })
    }

}
