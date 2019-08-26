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
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    self?.loadAllCapturedData()
                }
            })
            
            coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: NewCaptureListDownloadedEvent.self, queue: .main, action: { [weak self] (event: NewCaptureListDownloadedEvent) in
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    self?.loadAllCapturedData()
                }
            })
        }
    }
    
    private let service: CaptureServiceProtocol
    
    private var data: [Attachment] = []
    
    public var currentFilteredData: [Attachment] = []
    
    public var currentFilterdCellModels: [CaptureTableCellModel] = []
    
    private var currentIndex: Int?
    
    public var currentFilteredAttachmentKind: Attachment.Kind?
    
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
                
                var content = OutlineParser.Values.Attachment.serialize(attachment: attachment)
                // 添加的内容，新建一行，空一行
                content = OutlineParser.Values.Character.linebreak + OutlineParser.Values.Character.linebreak + content + OutlineParser.Values.Character.linebreak

                let insertion = InsertTextCommandComposer(location: heading.paragraphRange.upperBound, textToInsert: content)
                _ = service.toggleContentCommandComposer(composer: insertion).perform()
                
                self.currentIndex = nil // 移除当前选中的
                
                DispatchQueue.main.async {
                    self.delete(index: index)
                    self.delegate?.didCompleteRefile(index: index)
                }
                
                    service.save { _ in
                        service.close { _ in
                            DispatchQueue.main.async {
                                completion()
                            }
                    }
                }
            }
        }
        
    }
    
    public func loadFilterdData(kind: Attachment.Kind?) {
        if let filterKind = kind {
            self.currentFilteredData = self.data.filter { $0.kind == filterKind }
        } else {
            self.currentFilteredData = self.data
        }
        
        self.currentFilterdCellModels = self.currentFilteredData.map { CaptureTableCellModel(attacment: $0) }
        
        self.delegate?.didLoadData()
    }
    
    public func loadAllCapturedData() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            self.service
                .loadAll(completion: { [weak self] attachments in
                    let attachments = attachments.sorted(by: { last, next -> Bool in
                        last.date.timeIntervalSince1970 > next.date.timeIntervalSince1970
                    })
                    
                    self?.data = attachments
                    
                    DispatchQueue.main.async {
                        self?.loadFilterdData(kind: self?.currentFilteredAttachmentKind)
                        self?.delegate?.didLoadData()
                    }
                    }, failure: { [weak self] error in
                        DispatchQueue.main.async {
                            self?.delegate?.didFail(error: "Can not open file")
                        }
                })
        }
    }
    
    public func index(for cellModel: CaptureTableCellModel) -> Int? {
        for (index, cm) in self.currentFilteredData.enumerated() {
            if cellModel.url == cm.url {
                return index
            }
        }
        
        return nil
    }
    
    public func delete(index: Int) {
        let removedCellModel = self.currentFilterdCellModels.remove(at: index)
        
        for (indexInTotal, dataToRemove) in self.data.enumerated() {
            if dataToRemove.url == removedCellModel.url {
                self.data.remove(at: indexInTotal)
                self.currentFilteredData.remove(at: index)
                self.service.delete(key: dataToRemove.key)
                self.delegate?.didDeleteCapture(index: index)
                
                if index == self.currentIndex {
                    self.currentIndex = nil
                }

                return
            }
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
            self.coordinator?.onSelectAction?(self.data[index])
            self.coordinator?.delegate?.didSelectAttachment(attachment: self.data[index], coordinator: coordinator)
        }
    }
}
