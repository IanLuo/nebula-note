//
//  AttachmentViewModel.swift
//  Icetea
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
    
    public struct Input {
        
    }
    
    public let output: Output = Output()
    public let input: Input = Input()
    
    public func loadData() {
        let cellModels = self.context.dependency.attachmentManager.allAttachmentsKeys.map {
            AttachmentManagerCellModel(key: $0)
        }
        
        self.output.attachments.accept([AttachmentManagerSection(items: cellModels)])
    }
    
    public func delete(indexs toDelete: [Int]) {
        var keys: [String] = []
        
        guard let cellModels = self.output.attachments.value.first?.items else { return }
        
        for (index, cellModel) in cellModels.enumerated() {
            if toDelete.contains(index) {
                keys.append(cellModel.key)
            }
        }
        
        let dependency = self.context.dependency
        
        if keys.count > 0 {
            dependency.attachmentManager.delete(keys: keys, completion: { [weak self] deletedKeys in
                guard let strongSelf = self else { return }
                
                var newCellModels = cellModels
                let count = newCellModels.count
                let indexCounter: (Int) -> Int = { i in count - i - 1 }
                
                for (index, cellModel) in newCellModels.enumerated() {
                    if deletedKeys.contains(cellModel.key) {
                        newCellModels.remove(at: indexCounter(index))
                    }
                }
                
                strongSelf.output.attachments.accept([AttachmentManagerSection(items: newCellModels)])
                
            }, failure: { error in log.error(error)})
        }
        
    }
}

