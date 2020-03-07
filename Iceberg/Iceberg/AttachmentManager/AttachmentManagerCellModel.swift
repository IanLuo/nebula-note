//
//  AttachmentManagerCellModel.swift
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

public class AttachmentManagerCellModel: IdentifiableType, Equatable {
    public var identity: String { return self.attachment.key }
    
    public typealias Identity = String
    
    private let disposeBag = DisposeBag()
        
    public static func == (lhs: AttachmentManagerCellModel, rhs: AttachmentManagerCellModel) -> Bool {
        return lhs.attachment.key == rhs.attachment.key
    }
    
    public let attachment: Attachment
    public var image: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)

    public init(attachment: Attachment) {
        self.attachment = attachment
        attachment.thumbnail
            .observeOn(ConcurrentDispatchQueueScheduler(qos: DispatchQoS.background))
            .bind(to: self.image).disposed(by: self.disposeBag)
    }
}
