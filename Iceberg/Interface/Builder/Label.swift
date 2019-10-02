//
//  Label.swift
//  Interface
//
//  Created by ian luo on 2019/9/30.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public enum LabelStyle {
    case title
    case description
    case body
    
    public func create() -> UILabel {
        let label = UILabel()
        
        label.interface { (me, theme) in
            if let label = me as? UILabel {
                switch self {
                case .title:
                    label.font = theme.font.title
                    label.textColor = theme.color.interactive
                case .body:
                    label.font = theme.font.body
                    label.textColor = theme.color.interactive
                case .description:
                    label.font = theme.font.footnote
                    label.textColor = theme.color.descriptive
                }
            }
        }
        
        return label
    }
}
