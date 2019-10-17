//
//  UIViewController+Empty.swift
//  Interface
//
//  Created by ian luo on 2019/10/15.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol EmptyContentPlaceHolderProtocol: class {
    var image: UIImage { get }
    var viewToShowImage: UIView { get }
}

private class EmptyContentView: UIView {
    
}

extension UIViewController {
    public func showEmptyContentImage(_ show: Bool) {
        (self as? EmptyContentPlaceHolderProtocol)?.viewToShowImage.subviews.forEach {
            if $0 is EmptyContentView {
                $0.removeFromSuperview()
            }
        }
        
        if show {
            if let image = (self as? EmptyContentPlaceHolderProtocol)?.image {
                let view = EmptyContentView()
                (self as? EmptyContentPlaceHolderProtocol)?.viewToShowImage.addSubview(view)
                view.allSidesAnchors(to: self.view, edgeInset: 0)
                view.layer.contents = image.cgImage
            }
        }
    }
}
