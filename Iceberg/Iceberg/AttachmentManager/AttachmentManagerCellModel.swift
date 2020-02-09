//
//  AttachmentManagerCellModel.swift
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

public class AttachmentManagerCellModel: IdentifiableType, Equatable {
    public var identity: String { return self.key }
    
    public typealias Identity = String
        
    public static func == (lhs: AttachmentManagerCellModel, rhs: AttachmentManagerCellModel) -> Bool {
        return lhs.key == rhs.key
    }
    
    public let key: String
    public let attachment: BehaviorRelay<Attachment?> = BehaviorRelay(value: nil)
    public let image: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)

    public init(key: String) {
        self.key = key
    }
    
    public func loadFromFile(attachmentManager: AttachmentManager) {
        attachmentManager.attachment(with: self.key, completion: { [weak self] in
            self?.attachment.accept($0)
            }, failure: { error in
                log.error(error)
        })
    }
}
