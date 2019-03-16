//
//  DocumentEditToolbar.swift
//  Iceland
//
//  Created by ian luo on 2019/3/5.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface

public class DocumentEditToolbar: UIView {
 
    private let _collectionView: UICollectionView
    
    public init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        self._collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(frame: .zero)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func _setupUI() {
        self.addSubview(self._collectionView)
        self._collectionView.allSidesAnchors(to: self, edgeInset: 0)
    }
}

extension EditAction {
    var icon: UIImage {
        switch self {
        case .toggleFoldStatus(_):
            return Asset.Assets.capture.image
        case .toggleCheckboxStatus(_):
            return Asset.Assets.capture.image
        case .addAttachment(_, _, _):
            return Asset.Assets.capture.image
        case .changeDue(_, _):
            return Asset.Assets.capture.image
        case .removeDue(_):
            return Asset.Assets.capture.image
        case .changeSchedule(_, _):
            return Asset.Assets.capture.image
        case .removeSchedule(_):
            return Asset.Assets.capture.image
        case .addTag(_, _):
            return Asset.Assets.capture.image
        case .removeTag(_, _):
            return Asset.Assets.capture.image
        case .changePlanning(_, _):
            return Asset.Assets.capture.image
        case .removePlanning(_):
            return Asset.Assets.capture.image
        case .insertText(_, _):
            return Asset.Assets.capture.image
        case .replaceHeading(_, _):
            return Asset.Assets.capture.image
        case .archive(_):
            return Asset.Assets.capture.image
        case .unarchive(_):
            return Asset.Assets.capture.image
        }
    }
}
