//
//  UserGuideViewController.swift
//  Icetea
//
//  Created by ian luo on 2020/1/29.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface

public class UserGuideWindow: UIView {
    public var sourceView: UIView!
    
    public convenience init(frame: CGRect, sourceView: UIView) {
        self.init(frame: frame)
        self.sourceView = sourceView
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    }
    
    @objc func close() {
        self.removeFromSuperview()
    }
    
    public func setGuidText(_ text: String) {
        let guideView = self._creatGuideBubble(text: text)
        
        self._positeGuideView(guideView: guideView, sourceView: self.sourceView)
    }
    
    private func _creatGuideBubble(text: String) -> UIView {
        let view = UIView()
        view.roundConer(radius: 8)
        view.isUserInteractionEnabled = false
        
        view.interface { (me, theme) in
            me.backgroundColor = theme.color.spotlight
        }

        let label = UILabel()
        label.numberOfLines = 0
        label.text = text
        
        label.interface { (me, theme) in
            let label = me as! UILabel
            label.textColor = theme.color.spotlitTitle
            label.font = theme.font.title
        }
        
        view.addSubview(label)
        
        label.allSidesAnchors(to: view, edgeInset: 10)
        
        return view
    }
    
    private func _positeGuideView(guideView: UIView, sourceView: UIView) {
        self.addSubview(guideView)
        
        let rect = sourceView.convert(sourceView.frame, to: self)
        
        guideView.translatesAutoresizingMaskIntoConstraints = false
        guideView.leftAnchor.constraint(greaterThanOrEqualTo: self.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        guideView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        guideView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -(self.bounds.height - rect.origin.y) - 20).isActive = true
        
        self._addMask(sourceView: sourceView, rect: rect)
    }
    
    private func _addMask(sourceView: UIView, rect: CGRect) {
        if let image = sourceView.snapshot {
            let imageView = UIImageView(image: image)
            imageView.isUserInteractionEnabled = false
            imageView.frame = rect
            self.addSubview(imageView)
        }
    }
}

extension UserGuideWindow {
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        self.close()
        if self.sourceView.convert(self.sourceView.frame, to: self).contains(point) {
            return false
        } else {
            return true
        }
    }
}
