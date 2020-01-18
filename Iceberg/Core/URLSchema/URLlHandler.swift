//
//  URLlHandler.swift
//  Business
//
//  Created by ian luo on 2019/5/4.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public enum Action: String {
    case file_org
    case file_markdown
    case file_txt
    case capture_text
    case capture_image
    case capture_link
    case capture_audio
    case capture_video
    case capture_location
}

public protocol URLHandler {
    var sourceApp: String { get }
    var url: URL { get }
    func execute(documentManager: DocumentManager, eventObserver: EventObserver) -> Bool
}

public struct URLSchemeHandler: URLHandler {
    public let sourceApp: String
    public let url: URL
    
    // icenote://import?file=file:///filelocation[.org|.md]
    // icenote://import?url=http://file_url[.org|.md]
    // icenote://capture?text=escaptedstring
    // icenote://capture?image=url_for_image
    // icenote://capture?location={101.234234, 23.343434}
    // icenote://capture?audio=file://audiolocation
    // icenote://capture?video=file://videolocation
    public func execute(documentManager: DocumentManager, eventObserver: EventObserver) -> Bool  {
        guard let scheme = url.scheme else { return false }
        
        log.info("start handle url scheme: \(url)")
        
        let importManager = ImportManager(documentManager: documentManager)
        
        if scheme == "file" {
            importManager.importFile(url: url) { (result) in
                switch result {
                case .success(let url):
                    // send notification
                    eventObserver.emit(ImportFileEvent(url: url))
                default: break
                }
            }
            return true
        }
        
        let action = url.path
        
        switch action {
        case "import":
            var isHandled = false
            self.url.enumerateQuery { (name, value) in
                if name == "file" {
                    let fileLocalURL = URL(fileURLWithPath: value)
                    
                    importManager.importFile(url: fileLocalURL, completion: { result in
                        // TODO:
                    })
                    
                    isHandled = true
                } else if name == "url" {
                    guard let fileURL = URL(string: value) else { return }
                    
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
                        let tempFileURL = URL.file(directory: URL.directory(location: URLLocation.temporary), name: fileURL.deletingPathExtension().lastPathComponent, extension: fileURL.pathExtension)
                        do {
                            try String(contentsOf: fileURL, encoding: .utf8).write(to: tempFileURL, atomically: true, encoding: .utf8)
                            
                            DispatchQueue.runOnMainQueueSafely {
                                importManager.importFile(url: tempFileURL, completion: { result in
                                    // TODO:
                                })
                            }
                        } catch {
                            log.error(error)
                        }
                    }
                    
                    isHandled = true
                }
            }
            
            return isHandled
        default: return false
        }
    }
}

public struct XCallbackURLlHandler: URLHandler {
    public let sourceApp: String
    public let url: URL
    
    public func execute(documentManager: DocumentManager, eventObserver: EventObserver) -> Bool  {
        return false
    }
}

extension URL {
    public func enumerateQuery(closure: (String, String) -> Void) {
        guard let query = self.query else { return }
        
        let parameters = query.components(separatedBy: "&")
        for parameter in parameters {
            let pair = parameter.components(separatedBy: "=")
            guard pair.count == 2 else { continue }
            let name = pair[0]
            let value = pair[1]
            
            closure(name, value)
        }
    }
}
