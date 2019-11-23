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
    var text: String { get }
    var viewToShowImage: UIView { get }
}

private class EmptyContentView: UIView {
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let textLabel: UILabel = {
        let label = LabelStyle.description.create()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.imageView)
        self.addSubview(self.textLabel)
        
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.centerAnchors(position: [.centerX, .centerY], to: self)
        
        self.textLabel.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.columnAnchor(view: self.textLabel, space: 10)
        self.textLabel.sideAnchor(for: [.left, .right], to: self, edgeInset: 100)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIViewController {
    public func showEmptyContentImage(_ show: Bool) {
        (self as? EmptyContentPlaceHolderProtocol)?.viewToShowImage.subviews.forEach {
            if $0 is EmptyContentView {
                $0.removeFromSuperview()
            }
        }
        
        if show {
            if let emptyPlaceHolder = self as? EmptyContentPlaceHolderProtocol {
                let view = EmptyContentView()
                (self as? EmptyContentPlaceHolderProtocol)?.viewToShowImage.addSubview(view)
                view.allSidesAnchors(to: self.view, edgeInset: 0)
                view.imageView.image = emptyPlaceHolder.image
                view.textLabel.text = emptyPlaceHolder.text
            }
        }
    }
}
