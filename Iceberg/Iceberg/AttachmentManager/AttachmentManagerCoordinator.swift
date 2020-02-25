//
//  AttachmentManagerCoordinator.swift
//  Icetea
//
//  Created by ian luo on 2020/2/6.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import RxSwift

public class AttachmentManagerCoordinator: Coordinator {
    private let disposeBag = DisposeBag()
    
    var onSelectAttachment: ((Attachment?) -> Void)?
    
    public enum Usage {
        case manage, pick
    }
    
    var usage: Usage = .manage
    
    public override init(stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        
        let viewController = AttachmentManagerViewController(viewModel: AttachmentManagerViewModel(coordinator: self))
        
        self.viewController = viewController
    }
    
    public convenience init(stack: UINavigationController, dependency: Dependency, usage: Usage) {
        self.init(stack: stack, dependency: dependency)
        self.usage = usage
        
        (self.viewController as? AttachmentManagerViewController)?.onSelectingAttachment.subscribe(onNext: { [weak self] in
            self?.onSelectAttachment?($0)
        }).disposed(by: self.disposeBag)
    }
}
