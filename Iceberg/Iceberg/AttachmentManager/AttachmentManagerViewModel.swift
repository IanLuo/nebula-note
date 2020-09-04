//
//  AttachmentViewModel.swift
//  x3
//
//  Created by ian luo on 2020/2/6.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import Core
import RxSwift
import RxCocoa
import RxDataSources

public struct AttachmentManagerSection: SectionModelType, AnimatableSectionModelType {
    public typealias Identity = String
    public var items: [AttachmentManagerCellModel]
    public var identity: String = UUID().uuidString
}

extension AttachmentManagerSection {
    public typealias Item = AttachmentManagerCellModel
    public init(original: AttachmentManagerSection, items: [AttachmentManagerCellModel]) {
        self = original
        self.items = items
    }
}

public class AttachmentManagerViewModel: ViewModelProtocol {
    public var context: ViewModelContext<AttachmentManagerCoordinator>!
    
    public typealias CoordinatorType = AttachmentManagerCoordinator
    
    public required init() {}
    
    public struct Output {
        public let attachments: BehaviorRelay<[AttachmentManagerSection]> = BehaviorRelay<[AttachmentManagerSection]>(value: [])
    }
    
    public let output: Output = Output()
    
    public func loadData() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
            let captureKeys = self.dependency.captureService.loadAllAttachmentNames()
            let cellModels = self.context.dependency.attachmentManager.allAttachmentsKeys.filter {
                return !captureKeys.contains($0)
            }.compactMap { (key) -> AttachmentManagerCellModel? in
                if let attachment = self.dependency.attachmentManager.attachment(with: key) {
                    return AttachmentManagerCellModel(attachment: attachment)
                } else {
                    return nil
                }
            }.sorted { lhs, rhs in
                lhs.attachment.date.timeIntervalSince1970 > rhs.attachment.date.timeIntervalSince1970
            }
            
            DispatchQueue.main.async {
                self.output.attachments.accept([AttachmentManagerSection(items: cellModels)])
            }
        }
    }
    
    public func attachment(at index: Int) -> Attachment? {
        return self.output.attachments.value.first?.items[index].attachment
    }
    
    public func delete(indexs toDelete: [Int]) {
        var keys: [String] = []
        
        guard let cellModels = self.output.attachments.value.first?.items else { return }
        
        for (index, cellModel) in cellModels.enumerated() {
            if toDelete.contains(index) {
                keys.append(cellModel.attachment.key)
            }
        }
        
        let dependency = self.context.dependency
        
        if keys.count > 0 {
            dependency.attachmentManager.delete(keys: keys, completion: { [weak self] deletedKeys in
                guard let strongSelf = self else { return }
                
                var newCellModels = cellModels
                let count = newCellModels.count
                let indexCounter: (Int) -> Int = { i in count - i - 1 }
                
                for (index, cellModel) in newCellModels.reversed().enumerated() {
                    if deletedKeys.contains(cellModel.attachment.key) {
                        newCellModels.remove(at: indexCounter(index))
                    }
                }
                
                strongSelf.output.attachments.accept([AttachmentManagerSection(items: newCellModels)])
                
            }, failure: { error in log.error(error)})
        }
        
    }
}

