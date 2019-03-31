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
import Business

public protocol DocumentEditToolbarDelegate: class {
    func didTriggerAction(_ action: ToolbarActionProtocol)
}

public class InputToolbar: UIView {
    
    public enum Mode {
        case heading
        case paragraph
        case quote
        case code
        
        fileprivate func _createActions() -> [ToolbarActionProtocol] {
            switch self {
            case.paragraph:
                return [TextMarkActions(), Attachments(), CursorActions(), IndentActions(), UndoActions()]
            default: return [TextMarkActions(), Attachments(), CursorActions(), IndentActions(), UndoActions()]
            }
        }
    }
    
    public weak var delegate: DocumentEditToolbarDelegate?
 
    private let _collectionView: UICollectionView
    
    private var _actions: [ToolbarActionProtocol] = []
    
    public var mode: Mode {
        didSet {
            log.info("enter \(mode) mode")
            self._actions = mode._createActions()
            self._collectionView.reloadData()
        }
    }
    
    public init(mode: Mode) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 44, height: 44)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        
        self.mode = mode
        self._collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(frame: .zero)
        
        self._collectionView.delegate = self
        self._collectionView.dataSource = self
        self._collectionView.register(ActionButtonCell.self, forCellWithReuseIdentifier: ActionButtonCell.reuseIdentifier)
        self._collectionView.register(GroupSeparator.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GroupSeparator.reuseIdentifier)
        
        self._setupUI()
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func _setupUI() {
        self.addSubview(self._collectionView)
        self._collectionView.allSidesAnchors(to: self, edgeInset: 0)
    }
}

extension InputToolbar: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let group = self._actions[section] as? ToolbarActionGroupProtocol {
            return group.actions.count
        } else {
            return 1
        }
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self._actions.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActionButtonCell.reuseIdentifier, for: indexPath) as! ActionButtonCell
        
        if let group = self._actions[indexPath.section] as? ToolbarActionGroupProtocol {
            cell.iconView.image = group.actions[indexPath.row].icon.withRenderingMode(.alwaysTemplate)
        } else {
            cell.iconView.image = self._actions[indexPath.section].icon.withRenderingMode(.alwaysTemplate)
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: GroupSeparator.reuseIdentifier, for: indexPath)
        
        return view
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: 0, height: collectionView.bounds.height)
        } else {
            return CGSize(width: 1, height: collectionView.bounds.height)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let group = self._actions[indexPath.section] as? ToolbarActionGroupProtocol {
            let action = group.actions[indexPath.row]
            self.delegate?.didTriggerAction(action)
        } else {
            let action = self._actions[indexPath.section]
            self.delegate?.didTriggerAction(action)
        }
    }
}

private class GroupSeparator: UICollectionReusableView {
    public static let reuseIdentifier: String = "GroupSeparator"
    
    private let _subView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self._subView)
        self._subView.allSidesAnchors(to: self, edgeInsets: .init(top: 13, left: 0, bottom: -13, right: 0))
        self.backgroundColor = InterfaceTheme.Color.background2
        self._subView.backgroundColor = InterfaceTheme.Color.descriptive
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class ActionButtonCell: UICollectionViewCell {
    public static let reuseIdentifier: String = "ActionButtonCell"
    
    public let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = InterfaceTheme.Color.interactive
        return imageView
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.iconView)
        self.iconView.centerAnchors(position: [.centerX, .centerY], to: self.contentView)
        self.iconView.sizeAnchor(width: 18, height: 18)
        
        self.contentView.backgroundColor = InterfaceTheme.Color.background2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
