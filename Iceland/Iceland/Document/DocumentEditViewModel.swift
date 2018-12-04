//
//  PageViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/1.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Storage

public enum DocumentEditError: Error {
    case failToOpenFile(URL)
    case failToChagneFileTitle(String)
    case failToSaveFile(String)
}

public protocol DocumentEditDelegate: class {
    func didOpenDocument(text: String)
    func didFailedToOpenDocument(with error: Error)
    func didSaveDocument()
    func didFailedToSaveDocument(with error: Error)
    func didChangeFileTitle()
    func didFailToChangeFileTitle(with error: Error)
    func didDeleteDocument(url: URL)
    func didFailedToDeleteDocument(error: Error)
    func didCloseDocument()
    func didFailedToCloseDocument()
}

public class DocumentEditViewModel {
    private struct Constants {
        static let folder = File.Folder.document("files")
    }
    
    public let editorController: EditorController
    public weak var delegate: DocumentEditDelegate?
    public var title: String
    private var document: Document
    
    /// 创建新文档
    public init(editorController: EditorController,
                url: URL) {
        self.editorController = editorController
        self.title = url.lastPathComponent
        self.document = .init(fileURL: url)
        self.addStatesObservers()
    }
    
    /// 编辑旧文档
    public init(editorController: EditorController,
                title: String) {
        self.editorController = editorController
        self.title = title
        
        Constants.folder.createFolderIfNeeded()
        self.document = .init(fileURL: URL(fileURLWithPath: File(Constants.folder, fileName: title).filePath))
        self.addStatesObservers()
    }
    
    public func loadDocument(completion:((String) -> Void)? = nil) {
        document.open { [weak self] (isOpenSuccessfully: Bool) in
            
            guard let strongSelf = self else { return }
            
            strongSelf.editorController.string = strongSelf.document.string
            
            completion?(strongSelf.document.string)
            
            if isOpenSuccessfully {
                strongSelf.delegate?.didOpenDocument(text: strongSelf.editorController.string)
            } else {
                strongSelf.delegate?.didFailedToOpenDocument(with: DocumentEditError.failToOpenFile(strongSelf.document.fileURL))
            }
        }
    }
    
    public func close(completion:((Bool) -> Void)? = nil) {
        document.close {
            completion?($0)
            
            if $0 {
                self.delegate?.didCloseDocument()
            } else {
                self.delegate?.didFailedToCloseDocument()
            }
        }
    }
    
    deinit {
        self.removeObservers()
        self.document.close(completionHandler: nil)
    }
    
    public func changeFileTitle(newTitle: String, completion: ((Bool) -> Void)? = nil) {
        let newURL = URL(fileURLWithPath: File(File.Folder.document("files"), fileName: newTitle).filePath)
        let oldURL = self.document.fileURL
        var error: NSError?
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            let fileCoordinator = NSFileCoordinator(filePresenter: nil)
            fileCoordinator.coordinate(writingItemAt: oldURL,
                                       options: NSFileCoordinator.WritingOptions.forMoving,
                                       writingItemAt: newURL,
                                       options: NSFileCoordinator.WritingOptions.forReplacing,
                                       error: &error,
                                       byAccessor: { (newURL1, newURL2) in
                                        do {
                                            let fileManager = FileManager.default
                                            fileCoordinator.item(at: oldURL, willMoveTo: newURL)
                                            try fileManager.moveItem(at: newURL1, to: newURL2)
                                            fileCoordinator.item(at: oldURL, didMoveTo: newURL)
                                            completion?(true)
                                            self.delegate?.didChangeFileTitle()
                                        } catch {
                                            completion?(false)
                                            self.delegate?.didFailToChangeFileTitle(with: DocumentEditError.failToChagneFileTitle("\(error)"))
                                        }
                                        
            })
        }
    }
    
    public func save(completion: ((Bool) -> Void)? = nil) {
        document.string = editorController.string
        document.save(to: document.fileURL, for: UIDocument.SaveOperation.forOverwriting) { [weak self] success in
            completion?(success)
            
            guard let strongSelf = self else { return }
            if success {
                self?.delegate?.didSaveDocument()
            } else {
                log.error( "fail to save file at: \(strongSelf.document.fileURL)")
                self?.delegate?.didFailedToSaveDocument(with: DocumentEditError.failToSaveFile("fail to save file at: \(strongSelf.document.fileURL)"))
            }
        }
    }
    
    public func delete(completion: ((Bool) -> Void)? = nil) {
        do {
            let url = self.document.fileURL
            try FileManager.default.removeItem(at: self.document.fileURL)
            completion?(true)
            self.delegate?.didDeleteDocument(url: url)
        } catch {
            log.error("failed to delete document: \(error)")
            completion?(false)
            self.delegate?.didFailedToDeleteDocument(error: error)
        }
    }
}

extension DocumentEditViewModel {
    fileprivate func addStatesObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleStatesChanges),
                                               name: UIDocument.stateChangedNotification,
                                               object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleStatesChanges(notification: Notification) {
        if let state = notification.object as? UIDocument.State {
            if state.contains(.savingError) {
                self.delegate?.didFailedToSaveDocument(with: DocumentEditError.failToSaveFile("\(self.document.fileURL)"))
            }
        }
    }
}
