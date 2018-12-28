//
//  CaptureListViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/8.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol CaptureListViewModelDelegate: class {
    func didLoadData()
    func didDeleteCapture(index: Int)
    func didFail(error: Error)
    func didRefileAttachment(index: Int)
    func didRefileFile(index: Int)
}

public class CaptureListViewModel {
    public typealias Dependency = CaptureCoordinator
    public weak var delegate: CaptureListViewModelDelegate?
    public weak var dependency: Dependency?
    
    private let service: CaptureServiceProtocol
    
    public var data: [Attachment] = []
    
    private var currentIndex: Int?
    
    public init(service: CaptureServiceProtocol) {
        self.service = service
    }
    
    public var currentCapture: Attachment? {
        switch self.currentIndex {
        case .none: return nil
        case .some(let index):
            return self.data[index]
        }
    }
    
    public func refile(editViewModel: DocumentEditViewModel, heading: OutlineTextStorage.Heading) {
        guard let attachment = self.currentCapture else { return }
        
        let content = OutlineParser.Values.Attachment.serialize(attachment: attachment)
        
        editViewModel.insert(content: content, headingLocation: heading.range.location)
        
        self.currentIndex = nil
        
        self.service.delete(key: attachment.key)
    }
    
    public func completeRefile(error: Error?) {
        if let error = error {
            self.delegate?.didFail(error: error)
        } else {
            self.delegate?.didRefileFile(index: self.currentIndex!)
            self.currentIndex = nil
        }
    }
    
    public func loadAllCapturedData() {
        self.service
            .loadAll(completion: { [weak self] attachments in
                self?.data = data
                self?.delegate?.didLoadData()
            }, failure: { [weak self] error in
                self?.delegate?.didFail(error: error)
            })
    }
    
    public func delete(index: Int) {
        self.service
            .delete(key: self.data[index].key)
    }
    
    public func refile(index: Int) {
        self.currentIndex = index
        self.dependency?.chooseDocumentHeadingForRefiling()
    }
}
