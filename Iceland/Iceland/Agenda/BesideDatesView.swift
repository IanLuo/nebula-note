//
//  BesideDatesView.swift
//  Iceland
//
//  Created by ian luo on 2018/12/26.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol BesideDatesViewDelegate: class {
    func didSelectDate(date: Date)
}

public class BesideDatesView: UIView {
    public weak var delegate: BesideDatesViewDelegate?
}
