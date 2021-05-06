//
//  ShareExtensionItemHandler.swift
//  Business
//
//  Created by ian luo on 2019/8/19.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import RxSwift

public struct ShareExtensionItemHandler {
    enum ShareError: Error {
        case nothingFound
    }
    let handler = ShareExtensionDataHandler()
    
    private let disposeBag = DisposeBag()
    
    public init() {}
    
    public func handleExtensionItem(_ items: [NSItemProvider], userInput: String? = nil) -> Observable<[URL]>  {
        return Observable.zip(
            items
                .map { element in
                    return element.ifDataExisted(identifier: "public.url-name")
                        .flatMap({ isExsited -> Observable<String> in
                            if isExsited {
                                return element.loadDataRepresentation(identifier: "public.url-name").map { data in
                                    if let title = String(data: data, encoding: .utf8) {
                                        return title
                                    } else {
                                        return ""
                                    }
                                }
                            } else {
                                return Observable.just("")
                            }
                        })
                        .flatMap({ [element] name -> Observable<URL> in
                            let name = userInput ?? name
                            if element.hasItemConformingToTypeIdentifier("public.image") {
                                return self.saveImage(attachment: element)
                            } else if element.hasItemConformingToTypeIdentifier("public.movie") {
                                return self.saveVideo(attachment: element)
                            } else if element.hasItemConformingToTypeIdentifier("public.audio") {
                                return self.saveAudio(attachment: element)
                            } else if element.hasItemConformingToTypeIdentifier("public.url") && element.hasItemConformingToTypeIdentifier("public.file-url") == false {
                                return self.saveURL(attachment: element, text: name)
                            } else if let text = userInput, text.count > 0 {
                                return self.saveString(text)
                            } else if element.hasItemConformingToTypeIdentifier("public.text") {
                                return self.saveText(attachment: element, userInput: userInput ?? "")
                            } else {
                                return Observable.empty()
                            }
                        })
                })
    }
    
    private func saveVideo(attachment: NSItemProvider) -> Observable<URL> {
        return attachment.loadItem(identifier: "public.url", options: [:]).flatMap { [attachment] (data) -> Observable<URL> in
            if let videoURL = data as? NSURL {
                return self.saveFile(url: videoURL as URL, kind: Attachment.Kind.video)
            } else {
                return attachment.loadItem(identifier: "public.movie", options: nil).flatMap { (data) -> Observable<URL> in
                    if let videoURL = data as? NSURL {
                        return self.saveFile(url: videoURL as URL, kind: Attachment.Kind.video)
                    } else {
                        return Observable.error(ShareError.nothingFound)
                    }
                }
            }
        }
    }
    
    private func saveAudio(attachment: NSItemProvider) -> Observable<URL> {
        return attachment.loadItem(identifier: "public.url", options: nil).flatMap { [attachment] (data) -> Observable<URL> in
            if let audioURL = data as? NSURL {
                return self.saveFile(url: audioURL as URL, kind: Attachment.Kind.audio)
            } else {
                return attachment.loadItem(identifier: "public.audio", options: nil).flatMap { (data) -> Observable<URL> in
                    if let audioURL = data as? NSURL {
                        return self.saveFile(url: audioURL as URL, kind: Attachment.Kind.audio)
                    } else {
                        return Observable<URL>.error(ShareError.nothingFound)
                    }
                }
            }
        }
    }
    
    private func saveText(attachment: NSItemProvider, userInput: String?) -> Observable<URL> {
        let trySaveString: (String) -> Observable<URL> = { string in
            guard userInput?.count ?? 0 <= 0 else {
                return Observable.error(ShareError.nothingFound)
            }// if user typed something, ignore this part of text
            
            let url = URL.file(directory: URL.directory(location: URLLocation.temporary), name: UUID().uuidString, extension: "txt")
            do {
                try string.write(to: url, atomically: true, encoding: .utf8)
                return self.saveFile(url: url, kind: Attachment.Kind.text)
            } catch {
                print("ERROR: \(error)")
                return Observable.error(error)
            }
        }
        
        return attachment.loadItem(identifier: "public.text", options: nil).flatMap { data -> Observable<URL> in
            if let url = data as? URL {
                // if the shared text file is one of that can be imported, so import it
                if ImportType(rawValue: url.pathExtension) != nil {
                    return self.copyFile(url: url)
                } else {
                    return self.saveFile(url: url as URL, kind: Attachment.Kind.text)
                }
            } else if let data = data as? Data, let string = String(data: data, encoding: .utf8) {
                return trySaveString(string)
            } else if let string = data as? String {
                return trySaveString(string)
            } else {
                print(log.info("unhandled text !!!"))
                return Observable.error(ShareError.nothingFound)
            }
        }
    }
    
    private func saveURL(attachment: NSItemProvider, text: String) -> Observable<URL> {
        let createLinkFil: (String, URL) -> Observable<URL> = { name, linkURL in
            let tempURL = URL.file(directory: URL.directory(location: URLLocation.temporary), name: name.count > 0 ? name : UUID().uuidString, extension: "txt")
            do {
                let linkData: [String: Codable] = [
                    OutlineParser.Values.Attachment.Link.keyTitle: text.count > 0 ? text : linkURL.absoluteString,
                    OutlineParser.Values.Attachment.Link.keyURL: linkURL.absoluteString
                ]
                let jsonEncoder = JSONEncoder()
                let data = try jsonEncoder.encode(linkData)
                let string = String(data: data, encoding: .utf8) ?? ""
                try string.write(to: tempURL, atomically: true, encoding: .utf8)
                return self.saveFile(url: tempURL, kind: Attachment.Kind.link)
            } catch {
                print("ERROR: \(error)")
                return Observable<URL>.error(error)
            }
        }
        
        return attachment.loadItem(identifier: "public.url", options: nil).flatMap { data -> Observable<URL> in
            if let url = data as? URL {
                return createLinkFil(text, url)
            } else if let data = data as? Data,
                      let linkString = String(data: data, encoding: .utf8),
                      let url = URL(string: linkString)  {
                return createLinkFil(text, url)
            } else {
                return Observable.error(ShareError.nothingFound)
            }
        }
    }
    
    private func saveImage(attachment: NSItemProvider) -> Observable<URL> {
        return attachment.loadItem(identifier: "public.url", options: nil).flatMap { data -> Observable<URL> in
            if let imageURL = data as? URL {
                return self.saveFile(url: imageURL, kind: Attachment.Kind.image)
            } else if let data = data as? Data, let url = String(data: data, encoding: .utf8) {
                return self.downloadAndSaveImage(url: url)
            } else {
                return Observable.error(ShareError.nothingFound)
            }
        }.catch { error in
            return attachment.loadItem(identifier: "public.image", options: nil).flatMap { data -> Observable<URL> in
                if let image = data as? UIImage {
                    return self.saveImage(image: image)
                } else if let imageURL = data as? NSURL {
                    return self.saveFile(url: imageURL as URL, kind: Attachment.Kind.image)
                } else {
                    return Observable.error(ShareError.nothingFound)
                }
            }
        }
    }
    
    public func saveImage(image: UIImage) -> Observable<URL> {
        let containerURL = handler.sharedContainterURL
        
        let name = UUID().uuidString
        do {
            let url = containerURL.appendingPathComponent(name).appendingPathExtension(Attachment.Kind.image.rawValue).appendingPathExtension("png")
            try image.pngData()!.write(to: url)
            return Observable.just(url)
        } catch {
            print("ERROR: \(error)")
            return Observable.error(error)
        }
    }
    
    private func saveString(_ string: String) -> Observable<URL> {
        let fileName = UUID().uuidString
        let url = URL.file(directory: URL.directory(location: URLLocation.temporary), name: fileName, extension: "txt")
        
        try? string.write(to: url, atomically: false, encoding: String.Encoding.utf8)
        
        return self.saveFile(url: url, kind: Attachment.Kind.text)
    }
    
    private func saveFile(url: URL, kind: Attachment.Kind) -> Observable<URL> {
        return Observable.create { observer in
            let containerURL = handler.sharedContainterURL
            
            let fileName = UUID().uuidString + "-" + url.lastPathComponent
            var newFileName = containerURL.appendingPathComponent(fileName)
            let ext = newFileName.pathExtension
            newFileName = newFileName.deletingPathExtension()
            newFileName = newFileName.appendingPathExtension(kind.rawValue).appendingPathExtension(ext) // add attachment kind in the url, second to the ext
            newFileName.writeBlock(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.utility), accessor: { [newFileName] error in
                if let error = error {
                    print("ERROR: \(error)")
                    observer.onError(ShareError.nothingFound)
                    observer.onCompleted()
                }
                
                do {
                    try FileManager.default.copyItem(at: url as URL, to: newFileName)
                } catch {
                    print("ERROR: \(error)")
                }
                
                observer.onNext(newFileName)
                observer.onCompleted()
            })
            
            return Disposables.create()
        }
    }
    
    private func downloadAndSaveImage(url: String) -> Observable<URL> {
        if let url = URL(string: url) {
            return UIImage.download(url: url).flatMap { image -> Observable<UIImage> in
                if let image = image {
                    return Observable.just(image)
                } else {
                    return Observable.error(ShareError.nothingFound)
                }
            }.flatMap { image in
                self.saveImage(image: image)
            }
        } else {
            return Observable.error(ShareError.nothingFound)
        }
    }
    
    private func copyFile(url: URL) -> Observable<URL> {
        let containerURL = handler.sharedContainterURL
        
        let fileName = url.lastPathComponent
        let newFileName = containerURL.appendingPathComponent(fileName)
        
        return Observable.create { observer in
            newFileName.writeBlock(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background), accessor: { error in
                if let error = error {
                    print("ERROR: \(error)")
                    observer.onError(error)
                    observer.onCompleted()
                } else {
                    do {
                        try FileManager.default.copyItem(at: url as URL, to: newFileName)
                    } catch {
                        print("ERROR: \(error)")
                        observer.onError(error)
                        observer.onCompleted()
                    }
                    
                    observer.onNext(newFileName)
                    observer.onCompleted()
                }
                
            })
            
            return Disposables.create()
        }
    }
}

extension NSItemProvider {
    public func loadItem(identifier: String, options: [AnyHashable: Any]?) -> Observable<NSSecureCoding?> {
        return Observable.create { observer in
            if self.hasItemConformingToTypeIdentifier(identifier) {
                self.loadItem(forTypeIdentifier: identifier, options: options) { data, error in
                    if let error = error {
                        observer.onError(error)
                        observer.onCompleted()
                    } else {
                        observer.onNext(data)
                        observer.onCompleted()
                    }
                }
            } else {
                observer.onError(ShareExtensionItemHandler.ShareError.nothingFound)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    public func ifDataExisted(identifier: String) -> Observable<Bool> {
        return Observable.just(self.hasItemConformingToTypeIdentifier(identifier))
    }
    
    public func loadDataRepresentation(identifier: String) -> Observable<Data> {
        return Observable.create { observer in
            self.loadDataRepresentation(forTypeIdentifier: identifier) { data, error in
                if let error = error {
                    observer.onError(error)
                    observer.onCompleted()
                } else if let data = data {
                    observer.onNext(data)
                    observer.onCompleted()
                } else {
                    observer.onError(ShareExtensionItemHandler.ShareError.nothingFound)
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
}

extension Observable {
    public func doNextIf(_ condition: Observable<Bool>, next: @escaping (Element) -> Void) -> Observable<Element> {
        return condition.flatMap { c -> Observable<Element> in
            if c {
                return self.do(onNext: {
                    next($0)
                })
            } else {
                return self
            }
        }
    }
}

extension UIImage {
    static func download(url: URL) -> Observable<UIImage?> {
        return Observable.create { observer in
            
            DispatchQueue.global(qos: .background).async {
                do {
                    let image = try UIImage(data: Data(contentsOf: url))
                    observer.onNext(image)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
}
