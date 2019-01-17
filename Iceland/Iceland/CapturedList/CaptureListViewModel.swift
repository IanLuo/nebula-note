//
//  CaptureListViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/8.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Business

public protocol CaptureListViewModelDelegate: class {
    func didLoadData()
    func didDeleteCapture(index: Int)
    func didFail(error: Error)
    func didCompleteRefile(index: Int)
    func didStartRefile(at index: Int)
}

public class CaptureListViewModel {
    public weak var delegate: CaptureListViewModelDelegate?
    public weak var dependency: CaptureListCoordinator?
    
    private let service: CaptureServiceProtocol
    
    public var data: [Attachment] = []
    
    public var cellModels: [CaptureTableCellModel] = []
    
    private var currentIndex: Int?
    
    public init(service: CaptureServiceProtocol) {
        self.service = service
    }

    public var currentCapture: Attachment? {
        return self.currentIndex.map { self.data[$0] }
    }
    
    public func refile(editorService: EditorService,
                       heading: OutlineTextStorage.Heading) {
        
        guard let attachment = self.currentCapture else { return }
        
        var i: Int? = nil
        
        for (ii, a) in self.data.enumerated() {
            if a.url == attachment.url {
                i = ii
                break
            }
        }
        
        guard let index = i else { return }
        
        self.delegate?.didStartRefile(at: index)
        
        editorService.start { isOpen, service in
            guard isOpen else { return }
            
            let content = OutlineParser.Values.Attachment.serialize(attachment: attachment)
            service.insert(content: content, headingLocation: heading.range.location) // 添加字符串到对应的 heading 中
            self.currentIndex = nil // 移除当前选中的
            self.service.delete(key: attachment.key) // 删除 capture 中的 attachment 记录

            self.delegate?.didCompleteRefile(index: index)
            self.delegate?.didDeleteCapture(index: index)
        }
    }
    
    public func loadAllCapturedData() {
        self.service
            .loadAll(completion: { [weak self] attachments in
                let attachments = attachments.sorted(by: { last, next -> Bool in
                    last.date > next.date
                })
                self?.data = attachments
                self?.cellModels = attachments.map { CaptureTableCellModel(attacment: $0) }
                self?.delegate?.didLoadData()
            }, failure: { [weak self] error in
                self?.delegate?.didFail(error: error)
            })
    }
    
    public func delete(index: Int) {
        self.service.delete(key: self.data[index].key)
        self.data.remove(at: index)
        self.cellModels.remove(at: index)
        self.delegate?.didDeleteCapture(index: index)
        
        if index == self.currentIndex {
            self.currentIndex = nil
        }
    }
    
    public func chooseRefileLocation(index: Int) {
        self.currentIndex = index
        self.dependency?.showDocumentHeadingSelector()
    }
}
