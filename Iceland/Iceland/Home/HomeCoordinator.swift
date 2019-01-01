//
//  HomeCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public class HomeCoordinator: Coordinator {
    public override func start(from: Coordinator?) {
        let coord = BrowserCoordinator(stack: self.stack, documentManager: DocumentManager(), usage: BrowserCoordinator.Usage.chooseDocument)
        coord.start(from: from)
    }
}
