//
//  CaptureListViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/8.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Core

public protocol CaptureListViewModelDelegate: class {
    func didLoadData()
    func didDeleteCapture(index: Int)
    func didFail(error: String)
    func didCompleteRefile(index: Int, attachment: Attachment)
    func didStartRefile(at index: Int)
}

public class CaptureListViewModel: ViewModelProtocol {
    public required init() {}
    
    public var context: ViewModelContext<CaptureListCoordinator>!
    
    public typealias CoordinatorType = CaptureListCoordinator
    
    public enum Mode {
        case pick
        case manage
    }
    
    public var mode: Mode = .pick

    public weak var delegate: CaptureListViewModelDelegate?
    
    private var service: CaptureServiceProtocol!
    
    private var data: [Attachment] = []
    
    public var currentFilteredData: [Attachment] = []
    
    public var currentFilterdCellModels: [CaptureTableCellModel] = []
    
    private var currentIndex: Int?
    
    public var currentFilteredAttachmentKind: Attachment.Kind?
    
    public convenience init(service: CaptureServiceProtocol, mode: Mode, coordinator: CaptureListCoordinator) {
        self.init(coordinator: coordinator)
        self.service = service
        self.mode = mode
        
        self.dependency.eventObserver.registerForEvent(on: self, eventType: NewCaptureAddedEvent.self, queue: .main, action: { [weak self] (event: NewCaptureAddedEvent) in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                self?.loadAllCapturedData()
            }
        })
        
        self.dependency.eventObserver.registerForEvent(on: self, eventType: NewCaptureListDownloadedEvent.self, queue: .main, action: { [weak self] (event: NewCaptureListDownloadedEvent) in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                self?.loadAllCapturedData()
            }
        })
    }
    
    deinit {
        self.dependency.eventObserver.unregister(for: self, eventType: nil)
    }

    public var currentCapture: Attachment? {
        return self.currentIndex.map { self.data[$0] }
    }
    
    public func refile(editorService: EditorService,
                       outline: OutlineLocation,
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
            
            service.open { string in
                guard string != nil else {
                    self.delegate?.didFail(error: "Can not open file")
                    return
                }
                
                var content = OutlineParser.Values.Attachment.serialize(attachment: attachment)
                // 添加的内容，新建一行，空一行
                content = OutlineParser.Values.Character.linebreak + OutlineParser.Values.Character.linebreak + content + OutlineParser.Values.Character.linebreak

                var insertLocation: Int!
                switch outline {
                case .heading(let heading):
                    insertLocation = heading.paragraphRange.upperBound
                case .position(let location):
                    insertLocation = location
                }
                
                let insertion = InsertTextCommandComposer(location: insertLocation, textToInsert: content)
                _ = service.toggleContentCommandComposer(composer: insertion).perform()
                
                self.currentIndex = nil // 移除当前选中的
                
                DispatchQueue.runOnMainQueueSafely {
                    self.delegate?.didCompleteRefile(index: index, attachment: attachment)
                }
                
                    service.save { _ in
                        service.close { _ in
                            DispatchQueue.runOnMainQueueSafely {
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
                    
                    DispatchQueue.runOnMainQueueSafely {
                        self?.loadFilterdData(kind: self?.currentFilteredAttachmentKind)
                        self?.delegate?.didLoadData()
                    }
                    }, failure: { [weak self] error in
                        DispatchQueue.runOnMainQueueSafely {
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
    
    public func delete(index: Int, alsoDeleteAttachment: Bool = false) {
        let removedCellModel = self.currentFilterdCellModels.remove(at: index)
        
        for (indexInTotal, dataToRemove) in self.data.enumerated() {
            if dataToRemove.url == removedCellModel.url {
                self.data.remove(at: indexInTotal)
                self.currentFilteredData.remove(at: index)
                self.service.delete(key: dataToRemove.key)
                self.delegate?.didDeleteCapture(index: index)
                
                if alsoDeleteAttachment {
                    self.dependency.attachmentManager.delete(key: dataToRemove.key, completion: { }, failure: { _ in })
                }
                
                if index == self.currentIndex {
                    self.currentIndex = nil
                }

                return
            }
        }
        
    }
    
    public func chooseRefileLocation(index: Int, completion: @escaping () -> Void, canceled: @escaping () -> Void) {
        self.currentIndex = index
        self.context.coordinator?.showDocumentHeadingSelector(completion: { [unowned self] url, outlineLocation in
            guard let service = self.context.coordinator?.dependency.editorContext.request(url: url) else {
                return
            }
            
            self.refile(editorService: service, outline: outlineLocation, completion: completion)
            }, canceled: canceled)
    }
    
    public func selectAttachment(index: Int) {
        if let coordinator = self.context.coordinator {
            self.context.coordinator?.onSelectAction?(self.data[index])
            self.context.coordinator?.delegate?.didSelectAttachment(attachment: self.data[index], coordinator: coordinator)
        }
    }
}
