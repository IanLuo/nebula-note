//
//  CalendarView.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol CalendarViewDelegate: class {
    func didSelect(date: Date)
}

public class CalendarView: UIView {
    public weak var delegate: CalendarViewDelegate?
}
