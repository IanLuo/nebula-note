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
    
    public func refile(editorService: EditorService,
                       heading: OutlineTextStorage.Heading) {
        
        guard let attachment = self.currentCapture else { return }
        
        editorService.start { isOpen, service in
            guard isOpen else { return }
            
            let content = OutlineParser.Values.Attachment.serialize(attachment: attachment)
            service.insert(content: content, headingLocation: heading.range.location) // 添加字符串到对应的 heading 中
            self.currentIndex = nil // 移除当前选中的
            self.service.delete(key: attachment.key) // 删除 capture 中的 attachment 记录
            for (index, attachment) in self.data.enumerated() {
                if attachment.url == editorService.fileURL {
                    self.delegate?.didRefileAttachment(index: index)
                    self.delegate?.didDeleteCapture(index: index)
                }
            }
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
        self.service.delete(key: self.data[index].key)
        self.delegate?.didDeleteCapture(index: index)
        
        if index == self.currentIndex {
            self.currentIndex = nil
        }
    }
    
    public func prepareForRefile(index: Int) {
        self.currentIndex = index
        self.dependency?.chooseDocumentHeadingForRefiling()
    }
}
