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
    public var identity: String { return self.key }
    
    public typealias Identity = String
    
    private let disposeBag = DisposeBag()
        
    public static func == (lhs: AttachmentManagerCellModel, rhs: AttachmentManagerCellModel) -> Bool {
        return lhs.key == rhs.key
    }
    
    public let key: String
    public let attachment: BehaviorRelay<Attachment?> = BehaviorRelay(value: nil)
    public let image: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)

    public init(key: String) {
        self.key = key
        
        self.attachment
            .skipWhile { $0 == nil }
            .flatMap { $0!.thumbnail }
            .bind(to: self.image)
            .disposed(by: self.disposeBag)
    }
    
    public func loadFromFile(attachmentManager: AttachmentManager) {
        if self.attachment.value == nil {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
                if let attachment = attachmentManager.attachment(with: self.key) {
                    DispatchQueue.main.async {
                        self.attachment.accept(attachment)
                    }
                }
            }
        }
    }
}
