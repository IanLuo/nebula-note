//
//  BrowserCellModel.swift
//  Iceberg
//
//  Created by ian luo on 2019/9/30.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import Interface
import Core
import RxDataSources

public class BrowserCellModel {
    public var url: URL
    public var isFolded: Bool = true
    public var parent: URL?
    public var levelFromRoot: Int
    public var shouldShowActions: Bool = true
    public var shouldShowChooseHeadingIndicator: Bool = false
    public var updateDate: Date
    public var downloadingProcess: Int = 100
    
    public lazy var cover: UIImage? = {
        return UIImage(contentsOfFile: self.url.coverURL.path)?.resize(upto: CGSize(width: 300, height: 300))
    }()
    
    public weak var coordinator: BrowserCoordinator?
    
    public init(url: URL, isDownloading: Bool = false, coordinator: BrowserCoordinator?) {
        self.url = url
        self.parent = url.parentDocumentURL
        self.levelFromRoot = url.documentRelativePath.components(separatedBy: "/").filter { $0.count > 0 }.count
        let attriutes = try? FileManager.default.attributesOfItem(atPath: url.path)
        self.updateDate = (attriutes?[FileAttributeKey.modificationDate] as? Date) ?? Date.distantPast
        self.coordinator = coordinator
        
        if isDownloading {
            downloadingProcess = 0
        }
    }
    
    /// check if there's sub files, any delete empty folder if there is any empty child file folder
    /// `an empty child file folder is remained, if child file move to other place, or deleted`
    public var hasSubDocuments: Bool {
        if url.hasSubDocuments {
            if url.isEmptyFolder {
                return false
            }
            
            return true
        }
        
        return false
    }
    
    func createChildDocument(title: String) -> Observable<URL> {
        return Observable.create { observer -> Disposable in
            self.coordinator?.dependency.documentManager.add(title: title, below: self.url) { url in
                if let url = url {
                    observer.onNext(url)
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    public func rename(to: String) -> Observable<(URL, URL)> {
        return Observable.create { observer -> Disposable in
            let fromURL = self.url
            self.coordinator?
                .dependency
                .documentManager
                .rename(url: fromURL,
                        to: to,
                        below: nil,
                        completion: { toURL in
                            self.url = toURL
                            observer.onNext((fromURL, toURL))
                            observer.onCompleted()
                },
                        failure: { error in
                            log.error(error)
                            observer.onError(error)
                })
            
            return Disposables.create()
        }
    }
    
    public func duplicate() -> Observable<URL> {
        return Observable.create { observer -> Disposable in
            self.coordinator?
                .dependency
                .documentManager
                .duplicate(url: self.url,
                           copyExt: L10n.Browser.Title.copyExt,
                           complete: { url in
                            observer.onNext(url)
                }, failure: { error in
                    log.error(error)
                    observer.onError(error)
                })
            
            return Disposables.create()
        }
    }
    
    func move(to: URL) -> Observable<(URL, URL)> {
        let fileName = url.packageName
        
        return Observable.create { (observer) -> Disposable in
            let url = self.url
            self.coordinator?
                .dependency
                .documentManager
                .rename(url: url,
                        to: fileName,
                        below: to,
                        completion: { newURL in
                            observer.onNext((url, newURL))
                            observer.onCompleted()
                },
                        failure: { error in
                            log.error(error)
                            observer.onError(error)
                })
            
            return Disposables.create()
        }
        
    }
    
    func deleteDocument() -> Observable<URL> {
        let url = self.url
        
        return Observable.create { (observer) -> Disposable in
            self.coordinator?
                .dependency
                .documentManager
                .delete(url: self.url) { error in
                    if let error = error {
                        log.error(error)
                        observer.onError(error)
                    } else {
                        observer.onNext(url)
                        observer.onCompleted()
                    }
            }
            
            return Disposables.create()
        }
    }
    
    public func updateCover(cover: UIImage) -> Observable<URL> {
        self.cover = UIImage(contentsOfFile: self.url.coverURL.path)?.resize(upto: CGSize(width: 120, height: 120))
        
        return Observable.create { (observer) -> Disposable in
            self.coordinator?.dependency.documentManager.setCover(cover, url: self.url) { url in
                observer.onNext(url)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    public func isNameAvailable(newName: String) -> Bool {
        var newURL = self.url
        newURL.deleteLastPathComponent()
        newURL = newURL.appendingPathComponent(newName).appendingPathExtension(Document.fileExtension)
        return !FileManager.default.fileExists(atPath: newURL.path)
    }
    
    // get all files in documents directory
    public func loadAllFiles(completion: @escaping (([URL]) -> Void)) {
        do {
            let files = try self.coordinator?.dependency.documentManager.query(in: URL.documentBaseURL, recursively: true) ?? []
            completion(files)
        } catch {
            log.error(error)
            completion([])
        }
    }
}

extension BrowserCellModel: IdentifiableType, Equatable {
    public typealias Identity = URL
    
    public var identity : Identity { return self.url }
    
    public static func == (lhs: BrowserCellModel, rhs: BrowserCellModel) -> Bool {
        return lhs.url == rhs.url
    }
    
    
}
