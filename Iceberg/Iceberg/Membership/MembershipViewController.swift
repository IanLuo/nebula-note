//
//  MembershipViewController.swift
//  Icetea
//
//  Created by ian luo on 2019/12/17.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

public class MembershipViewController: UIViewController {
    private var viewModel: MembershipViewModel!
    
    public convenience init(viewModel: MembershipViewModel) {
        self.init()
        self.viewModel = viewModel
    }
}
