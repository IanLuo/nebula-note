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
    func didFail(error: String)
    func didCompleteRefile(index: Int)
    func didStartRefile(at index: Int)
}

public class CaptureListViewModel {
    public enum Mode {
        case pick
        case manage
    }
    
    public let mode: Mode

    public weak var delegate: CaptureListViewModelDelegate?
    public weak var coordinator: CaptureListCoordinator? {
        didSet {
            coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: NewCaptureAddedEvent.self, queue: .main, action: { [weak self] (event: NewCaptureAddedEvent) in
                self?.loadAllCapturedData()
            })
            
            coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: NewCaptureListDownloadedEvent.self, queue: .main, action: { [weak self] (event: NewCaptureListDownloadedEvent) in
                self?.loadAllCapturedData()
            })
        }
    }
    
    private let service: CaptureServiceProtocol
    
    public var data: [Attachment] = []
    
    public var cellModels: [CaptureTableCellModel] = []
    
    private var currentIndex: Int?
    
    public init(service: CaptureServiceProtocol, mode: Mode) {
        self.service = service
        self.mode = mode
    }
    
    deinit {
        coordinator?.dependency.eventObserver.unregister(for: self, eventType: nil)
    }

    public var currentCapture: Attachment? {
        return self.currentIndex.map { self.data[$0] }
    }
    
    public func refile(editorService: EditorService,
                       heading: DocumentHeading,
                       completion: @escaping() -> Void) {
        
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
        
        editorService.onReadyToUse = { service in
            
            service.start { isOpen, service in
                guard isOpen else {
                    self.delegate?.didFail(error: "Can not open file")
                    return
                }
                
                let content = OutlineParser.Values.Attachment.serialize(attachment: attachment)
                service.insert(content: content, headingLocation: heading.location) // 添加字符串到对应的 heading 中
                self.currentIndex = nil // 移除当前选中的
                self.service.delete(key: attachment.key) // 删除 capture 中的 attachment 记录
                self.data.remove(at: index)
                self.cellModels.remove(at: index)
                
                DispatchQueue.main.async {
                    self.delegate?.didCompleteRefile(index: index)
                    self.delegate?.didDeleteCapture(index: index)
                    completion()
                }
            }
        }
        
    }
    
    public func loadAllCapturedData() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            self.service
                .loadAll(completion: { [weak self] attachments in
                    let attachments = attachments.sorted(by: { last, next -> Bool in
                        last.date.timeIntervalSince1970 > next.date.timeIntervalSince1970
                    })
                    self?.data = attachments
                    self?.cellModels = attachments.map { CaptureTableCellModel(attacment: $0) }
                    
                    DispatchQueue.main.async {
                        self?.delegate?.didLoadData()
                    }
                    }, failure: { [weak self] error in
                        DispatchQueue.main.async {
                            self?.delegate?.didFail(error: "Can not open file")
                        }
                })
        }
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
    
    public func chooseRefileLocation(index: Int, completion: @escaping () -> Void, canceled: @escaping () -> Void) {
        self.currentIndex = index
        self.coordinator?.showDocumentHeadingSelector(completion: { [unowned self] url, heading in
            guard let service = self.coordinator?.dependency.editorContext.request(url: url) else {
                return
            }
            
            self.refile(editorService: service, heading: heading, completion: completion)
            }, canceled: canceled)
    }
    
    public func selectAttachment(index: Int) {
        if let coordinator = self.coordinator {
            self.coordinator?.delegate?.didSelectAttachment(attachment: self.data[index], coordinator: coordinator)
        }
    }
}
