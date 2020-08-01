//
//  ShareExtensionItemHandler.swift
//  Business
//
//  Created by ian luo on 2019/8/19.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public struct ShareExtensionItemHandler {
    let handler = ShareExtensionDataHandler()
    
    public init() {}
    
    @discardableResult public func handleExtensionItem(_ item: NSExtensionItem,
                                                       userInput: String? = nil,
                                      completion: @escaping () -> Void) -> Bool {
        
        var isHandled: Bool = false
        let group = DispatchGroup()
        
        var shouldHandleUserInput: Bool = true
        
        for attachment in item.attachments ?? [] {
            let text = item.attributedContentText?.string ?? ""
            if attachment.hasItemConformingToTypeIdentifier("public.image") {
                isHandled = true
                group.enter()
                self._saveImage(attachment: attachment) {
                    group.leave()
                }
            }
            
            if attachment.hasItemConformingToTypeIdentifier("public.movie") {
                isHandled = true
                group.enter()
                self._saveVideo(attachment: attachment) {
                    group.leave()
                }
            }
            
            // ignore local file url
            if attachment.hasItemConformingToTypeIdentifier("public.url") && !attachment.hasItemConformingToTypeIdentifier("public.file-url") {
                isHandled = true
                
                var linkTitle = text
                if let userInput = userInput, userInput.count > 0 {
                    linkTitle = userInput
                }
                
                shouldHandleUserInput = false // if there is link, don't save the user input as text, but as url title
                group.enter()
                self._saveURL(attachment: attachment, text: linkTitle) {
                    group.leave()
                }
            }
            
            if attachment.hasItemConformingToTypeIdentifier("public.text") {
                isHandled = true
                group.enter()
                self._saveText(attachment: attachment, userInput: userInput) {
                    group.leave()
                }
            }
            
            if attachment.hasItemConformingToTypeIdentifier("public.audio") {
                isHandled = true
                group.enter()
                self._saveAudio(attachment: attachment) {
                    group.leave()
                }
            }
        }
        
        // save user input text if there is any, and should
        if let userInput = userInput,
            userInput.count > 0,
            shouldHandleUserInput {
            group.enter()
            
            self._saveString(userInput) {
                group.leave()
            }
        }
        

        group.notify(queue: DispatchQueue.main) {
            completion()
        }
        
        return isHandled
    }
    
    private func _saveVideo(attachment: NSItemProvider, completion: @escaping () -> Void) {
        attachment.loadItem(forTypeIdentifier: "public.url", options: [:]) { (data, error) in
            if let videoURL = data as? NSURL {
                self._saveFile(url: videoURL as URL, kind: Attachment.Kind.video, completion: completion)
            } else {
                attachment.loadItem(forTypeIdentifier: "public.movie", options: nil) { (data, error) in
                    if let videoURL = data as? NSURL {
                        self._saveFile(url: videoURL as URL, kind: Attachment.Kind.video, completion: completion)
                    }
                    
                    if let error = error {
                        print("ERROR: \(error)")
                        completion()
                    }
                }
            }
            
            if let error = error {
                print("ERROR: \(error)")
                completion()
            }
        }
    }
    
    private func _saveAudio(attachment: NSItemProvider, completion: @escaping () -> Void) {
        attachment.loadItem(forTypeIdentifier: "public.url", options: nil) { (data, error) in
            if let audioURL = data as? NSURL {
                self._saveFile(url: audioURL as URL, kind: Attachment.Kind.audio, completion: completion)
            } else {
                attachment.loadItem(forTypeIdentifier: "public.audio", options: nil) { (data, error) in
                    if let audioURL = data as? NSURL {
                        self._saveFile(url: audioURL as URL, kind: Attachment.Kind.audio, completion: completion)
                    } else {
                        completion()
                    }
                    
                    if let error = error {
                        print("ERROR: \(error)")
                        completion()
                    }
                }
            }
            
            if let error = error {
                print("ERROR: \(error)")
                completion()
            }
        }
    }
    
    private func _saveText(attachment: NSItemProvider, userInput: String?, completion: @escaping () -> Void) {
        let trySaveString: (String) -> Void = { string in
            guard userInput?.count ?? 0 <= 0 else {
                completion()
                return
            }// if user typed something, ignore this part of text
            
            let url = URL.file(directory: URL.directory(location: URLLocation.temporary), name: UUID().uuidString, extension: "txt")
            do {
                try string.write(to: url, atomically: true, encoding: .utf8)
                self._saveFile(url: url, kind: Attachment.Kind.text, completion: completion)
            } catch {
                print("ERROR: \(error)")
                completion()
            }
        }
        
        attachment.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
            if let url = data as? URL {
                // if the shared text file is one of that can be imported, so import it
                if ImportType(rawValue: url.pathExtension) != nil {
                    self._copyFile(url: url, completion: completion)
                } else {
                    self._saveFile(url: url as URL, kind: Attachment.Kind.text, completion: completion)
                }
            } else if let data = data as? Data, let string = String(data: data, encoding: .utf8) {
                trySaveString(string)
            } else if let string = data as? String {
                trySaveString(string)
            } else {
                print(log.info("unhandled text !!!"))
                completion()
            }
        }
    }
    
    private func _saveURL(attachment: NSItemProvider, text: String, completion: @escaping () -> Void) {
        attachment.loadItem(forTypeIdentifier: "public.url", options: nil) { (data, error) in
            if let url = data as? URL {
                let tempURL = URL.file(directory: URL.directory(location: URLLocation.temporary), name: UUID().uuidString, extension: "txt")
                do {
                    let linkData: [String: Codable] = [
                        OutlineParser.Values.Attachment.Link.keyTitle: text.count > 0 ? text : url.absoluteString,
                        OutlineParser.Values.Attachment.Link.keyURL: url.absoluteString
                    ]
                    let jsonEncoder = JSONEncoder()
                    let data = try jsonEncoder.encode(linkData)
                    let string = String(data: data, encoding: .utf8) ?? ""
                    try string.write(to: tempURL, atomically: true, encoding: .utf8)
                    self._saveFile(url: tempURL, kind: Attachment.Kind.link, completion: completion)
                } catch {
                    print("ERROR: \(error)")
                    completion()
                }
            } else {
                completion()
            }
        }
    }
    
    private func _saveImage(attachment: NSItemProvider, completion: @escaping () -> Void) {
        let containerURL = handler.sharedContainterURL
        
        attachment.loadItem(forTypeIdentifier: "public.url", options: nil) { data, error in
            if let imageURL = data as? NSURL {
                self._saveFile(url: imageURL as URL, kind: Attachment.Kind.image, completion: completion)
            } else {
                
                attachment.loadItem(forTypeIdentifier: "public.image", options: nil) { data, error in
                    if let image = data as? UIImage {
                        let name = UUID().uuidString
                        do {
                            try image.pngData()!.write(to: containerURL.appendingPathComponent(name).appendingPathExtension(Attachment.Kind.image.rawValue).appendingPathExtension("png"))
                            completion()
                        } catch {
                            print("ERROR: \(error)")
                            completion()
                        }
                    } else if let imageURL = data as? NSURL {
                        self._saveFile(url: imageURL as URL, kind: Attachment.Kind.image, completion: completion)
                    } else {
                        completion()
                    }
                    
                    if let error = error {
                        print("ERROR: \(error)")
                        completion()
                    }
                }
            }
            
            if let error = error {
                print("ERROR: \(error)")
            }
        }

    }
    
    private func _saveString(_ string: String, completion: @escaping () -> Void) {
        let fileName = UUID().uuidString
        let url = URL.file(directory: URL.directory(location: URLLocation.temporary), name: fileName, extension: "txt")
        
        try? string.write(to: url, atomically: false, encoding: String.Encoding.utf8)
        
        self._saveFile(url: url, kind: Attachment.Kind.text, completion: completion)
    }
    
    private func _saveFile(url: URL, kind: Attachment.Kind, completion: @escaping () -> Void) {
        let containerURL = handler.sharedContainterURL
        
        let fileName = UUID().uuidString + "-" + url.lastPathComponent
        var newFileName = containerURL.appendingPathComponent(fileName)
        let ext = newFileName.pathExtension
        newFileName = newFileName.deletingPathExtension()
        newFileName = newFileName.appendingPathExtension(kind.rawValue).appendingPathExtension(ext) // add attachment kind in the url, second to the ext
        newFileName.writeBlock(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.utility), accessor: { error in
            if let error = error {
                print("ERROR: \(error)")
                completion()
            }
            
            do {
                try FileManager.default.copyItem(at: url as URL, to: newFileName)
            } catch {
                print("ERROR: \(error)")
            }
            
            completion()
        })
    }
    
    private func _copyFile(url: URL, completion: @escaping () -> Void) {
        let containerURL = handler.sharedContainterURL
        
        let fileName = url.lastPathComponent
        let newFileName = containerURL.appendingPathComponent(fileName)
        newFileName.writeBlock(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background), accessor: { error in
            if let error = error {
                print("ERROR: \(error)")
                completion()
            }
            
            do {
                try FileManager.default.copyItem(at: url as URL, to: newFileName)
            } catch {
                print("ERROR: \(error)")
            }
            
            completion()
        })
    }
}
