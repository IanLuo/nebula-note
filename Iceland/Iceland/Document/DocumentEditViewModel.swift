//
//  PageViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/1.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Storage

public protocol DocumentEditDelegate: class {
    func didClickLink(url: URL)
}

public class DocumentEditViewModel {
    public let editorController: EditorController
    public weak var delegate: DocumentEditDelegate?
    private var document: Document
    
    public init(editorController: EditorController,
                document: Document) {
        self.document = document
        self.editorController = editorController
        self.addStatesObservers()
    }
        
    public func open(completion:((String) -> Void)? = nil) {
        document.open { [weak self] (isOpenSuccessfully: Bool) in
            guard let strongSelf = self else { return }
            
            strongSelf.editorController.string = strongSelf.document.string
            
            completion?(strongSelf.document.string)
        }
    }
    
    public func close(completion:((Bool) -> Void)? = nil) {
        document.close {
            completion?($0)
        }
    }
    
    deinit {
        self.removeObservers()
        self.close()
    }
    
    public func rename(newTitle: String, completion: ((Error?) -> Void)? = nil) {
        let newURL = self.document.fileURL.deletingLastPathComponent().appendingPathComponent(newTitle).appendingPathExtension(Document.fileExtension)
        document.fileURL.rename(url: newURL, completion: completion)
    }
    
    public func save(completion: ((Bool) -> Void)? = nil) {
        document.string = editorController.string
        document.save(to: document.fileURL, for: UIDocument.SaveOperation.forOverwriting) { success in
            completion?(success)
        }
    }
    
    public func delete(completion: ((Bool) -> Void)? = nil) {
        do {
            try FileManager.default.removeItem(at: self.document.fileURL)
            completion?(true)
        } catch {
            log.error("failed to delete document: \(error)")
            completion?(false)
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
            }
        }
    }
}
