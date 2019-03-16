//
//  TimeSelectViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/3/16.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol TimeSelectViewControllerDelegate: class {
    func didSelectTime(hour: Int, minute: Int, second: Int)
    func didEnableSelectTime(_ enabled: Bool)
}

public class TimeSelectViewController: UIViewController {
    
    public weak var delegate: TimeSelectViewController?

    public var hour: Int = 0
    public var minute: Int = 0
    public var second: Int = 0
}
