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
import Core

public protocol DocumentEditToolbarDelegate: class {
    func didTriggerAction(_ action: ToolbarActionProtocol, from: UIView)
    func isMember() -> Bool
}

public class InputToolbar: UIView {
    struct ActionGroup {
        let actions: [ToolbarActionProtocol]
        let isEnabled: Bool
        let isHidden: Bool
    }
    
    private static let paragraphActions = [NormalAction.paragraph]
    private static let headingActions = [NormalAction.heading, NormalAction.headingProperty, NormalAction.planning, NormalAction.tag, NormalAction.priority]
    private static let textMark = [NormalAction.bold, NormalAction.italic, NormalAction.underscore, NormalAction.strikethrough, NormalAction.highlight]
    private static let moveCursor: [ToolbarActionProtocol] = [CursorAction.moveUp, CursorAction.moveDown, CursorAction.moveLeft, CursorAction.moveRight]
    private static let moveContent: [ToolbarActionProtocol] = [NormalAction.increaseIndent, NormalAction.decreaseIndent, NormalAction.moveUp, NormalAction.moveDown]
    private static let undoAndRedo: [ToolbarActionProtocol] = [NormalAction.undo, NormalAction.redo]
    private static let insertSpecailContent: [ToolbarActionProtocol] = [NormalAction.seperator, NormalAction.sourcecode, NormalAction.quote, NormalAction.checkbox, NormalAction.dateAndTime, NormalAction.list, NormalAction.orderedList]
    private static let attachment: [ToolbarActionProtocol] = [NormalAction.fileLink, NormalAction.captured, NormalAction.allAttachments, NormalAction.newAttachment]
    private static let file: [ToolbarActionProtocol] = [NormalAction.save]
    
    private static let headless: [ActionGroup] = [ActionGroup(actions: paragraphActions, isEnabled: false, isHidden: true),
                                                  ActionGroup(actions: headingActions, isEnabled: true, isHidden: true),
                                                  ActionGroup(actions: textMark, isEnabled: true, isHidden: true),
                                                  ActionGroup(actions: undoAndRedo, isEnabled: true, isHidden: true),
                                                  ActionGroup(actions: moveCursor, isEnabled: true, isHidden: !isMac),
                                                  ActionGroup(actions: moveContent, isEnabled: true, isHidden: true),
                                                  ActionGroup(actions: insertSpecailContent, isEnabled: true, isHidden: true),
                                                  ActionGroup(actions: attachment, isEnabled: true, isHidden: true),
                                                  ActionGroup(actions: file, isEnabled: true, isHidden: false)]
    
    private static let actionsParagraph: [ActionGroup] = [ActionGroup(actions: paragraphActions, isEnabled: true, isHidden: true),
                                                          ActionGroup(actions: headingActions, isEnabled: true, isHidden: true),
                                                          ActionGroup(actions: textMark, isEnabled: true, isHidden: true),
                                                          ActionGroup(actions: undoAndRedo, isEnabled: true, isHidden: true),
                                                          ActionGroup(actions: moveCursor, isEnabled: true, isHidden: !isMac),
                                                          ActionGroup(actions: moveContent, isEnabled: true, isHidden: true),
                                                          ActionGroup(actions: insertSpecailContent, isEnabled: true, isHidden: true),
                                                          ActionGroup(actions: attachment, isEnabled: true, isHidden: true),
                                                          ActionGroup(actions: file, isEnabled: true, isHidden: false)]
    
    private static let actionsHeading: [ActionGroup] = [ActionGroup(actions: paragraphActions, isEnabled: true, isHidden: true),
                                                        ActionGroup(actions: headingActions, isEnabled: true, isHidden: true),
                                                        ActionGroup(actions: textMark, isEnabled: false, isHidden: true),
                                                        ActionGroup(actions: undoAndRedo, isEnabled: true, isHidden: true),
                                                        ActionGroup(actions: moveCursor, isEnabled: true, isHidden: !isMac),
                                                        ActionGroup(actions: moveContent, isEnabled: true, isHidden: true),
                                                        ActionGroup(actions: insertSpecailContent, isEnabled: false, isHidden: true),
                                                        ActionGroup(actions: attachment, isEnabled: false, isHidden: true),
                                                        ActionGroup(actions: file, isEnabled: true, isHidden: false)]
    
    private static let quoteBlock: [ActionGroup] = [ActionGroup(actions: paragraphActions, isEnabled: true, isHidden: true),
                                                    ActionGroup(actions: headingActions, isEnabled: true, isHidden: true),
                                                    ActionGroup(actions: textMark, isEnabled: false, isHidden: true),
                                                    ActionGroup(actions: undoAndRedo, isEnabled: true, isHidden: true),
                                                    ActionGroup(actions: moveCursor, isEnabled: true, isHidden: !isMac),
                                                    ActionGroup(actions: moveContent, isEnabled: true, isHidden: true),
                                                    ActionGroup(actions: insertSpecailContent, isEnabled: false, isHidden: true),
                                                    ActionGroup(actions: attachment, isEnabled: false, isHidden: true),
                                                    ActionGroup(actions: file, isEnabled: true, isHidden: false)]
    
    private static let codeBlock: [ActionGroup] = [ActionGroup(actions: paragraphActions, isEnabled: true, isHidden: true),
                                                   ActionGroup(actions: headingActions, isEnabled: true, isHidden: true),
                                                   ActionGroup(actions: textMark, isEnabled: false, isHidden: true),
                                                   ActionGroup(actions: undoAndRedo, isEnabled: true, isHidden: true),
                                                   ActionGroup(actions: moveCursor, isEnabled: true, isHidden: !isMac),
                                                   ActionGroup(actions: moveContent, isEnabled: true, isHidden: true),
                                                   ActionGroup(actions: insertSpecailContent, isEnabled: false, isHidden: true),
                                                   ActionGroup(actions: attachment, isEnabled: false, isHidden: true),
                                                   ActionGroup(actions: file, isEnabled: true, isHidden: false)]
    
    public enum Mode {
        case  headless
        case heading
        case paragraph
        case quote
        case code
        
        fileprivate func _createActions(mode: Mode) -> [ActionGroup] {
            switch mode {
            case .headless:
                return InputToolbar.headless
            case.paragraph:
                return InputToolbar.actionsParagraph
            case .heading:
                return InputToolbar.actionsHeading
            case .quote:
                return InputToolbar.quoteBlock
            case .code:
                return InputToolbar.codeBlock
            }
        }
    }
    
    public weak var delegate: DocumentEditToolbarDelegate?
 
    private let _collectionView: UICollectionView
    
    private var _actions: [ActionGroup] = []
    
    public var mode: Mode {
        didSet {
            if mode != oldValue {
                log.info("enter \(mode) mode")
                self._actions = mode._createActions(mode: mode)
                self._collectionView.reloadData()
            }
        }
    }
    
    public func isActionAvailable(commandTitle: String) -> Bool {
        for actionGroup in self._actions {
            for ac in actionGroup.actions {
                if commandTitle == (ac as? DocumentActon)?.title && actionGroup.isEnabled {
                    return true
                }
            }
        }
        
        return false
    }
    
    public init(mode: Mode) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 44, height: 44)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        self.mode = mode
        self._actions = mode._createActions(mode: mode)
        self._collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(frame: .zero)
        
        self.interface { (me, interface) in
            let toolBar = me as! InputToolbar
            if isMacOrPad {
                toolBar._collectionView.backgroundColor = InterfaceTheme.Color.background1
            } else {
                toolBar._collectionView.backgroundColor = InterfaceTheme.Color.background2
            }
        }
        
        self._collectionView.delegate = self
        self._collectionView.dataSource = self
        self._collectionView.register(ActionButtonCell.self, forCellWithReuseIdentifier: ActionButtonCell.reuseIdentifier)
        self._collectionView.register(GroupSeparator.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GroupSeparator.reuseIdentifier)
        self._collectionView.decelerationRate = .fast
        
        if isPhone {
            self._collectionView.showsHorizontalScrollIndicator = false
        }
                
        self._setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func button(at row: Int, section: Int) -> UIView? {
        return self._collectionView.cellForItem(at: IndexPath(row: row, section: section))
    }
    
    private func _setupUI() {
        self.addSubview(self._collectionView)
        if isMac {
            self._collectionView.allSidesAnchors(to: self, edgeInsets: .init(top: 0, left: 0, bottom: -10, right: 0))
        } else {
            self._collectionView.allSidesAnchors(to: self, edgeInset: 0)
        }
    }
}

extension InputToolbar: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var actionGroups: [ActionGroup] {
        return self._actions.filter{ $0.isHidden }
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.actionGroups[section].actions.count
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.actionGroups.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActionButtonCell.reuseIdentifier, for: indexPath) as! ActionButtonCell
        
        let actionGroup = self.actionGroups[indexPath.section]
        let action = actionGroup.actions[indexPath.row]
        
        self.interface { (me, interface) in
            let color = actionGroup.isEnabled ? interface.color.interactive : UIColor.lightGray.withAlphaComponent(0.2)
            cell.iconView.image = action.icon.withRenderingMode(.alwaysTemplate).fill(color: color)
        }
        
        cell.memberFunctionImageView.isHidden = (self.delegate?.isMember() ?? false ) || !action.isMemberFunction

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
        let actionGroup = self.actionGroups[indexPath.section]
        let action = actionGroup.actions[indexPath.row]
        
        if actionGroup.isEnabled, let cell = collectionView.cellForItem(at: indexPath) {
            self.delegate?.didTriggerAction(action, from: cell)
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
        
        self.interface { [weak self] (me, theme) in
            self?._subView.backgroundColor = InterfaceTheme.Color.background3
            me.backgroundColor = .clear
        }
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
        
        imageView.interface({ (me, theme) in
            me.tintColor = InterfaceTheme.Color.interactive
        })
        return imageView
    }()
    
    public let memberFunctionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.iconView)
        self.iconView.centerAnchors(position: [.centerX, .centerY], to: self.contentView)
        self.iconView.sizeAnchor(width: 18, height: 18)
        
        self.contentView.addSubview(self.memberFunctionImageView)
        self.memberFunctionImageView.sideAnchor(for: [.left, .bottom, .right], to: self.contentView, edgeInset: 5)
        self.memberFunctionImageView.image = Asset.Assets.proLabel.image
        
        self.interface { (me, theme) in
            let me = me as! UICollectionViewCell
            if isMacOrPad {
                me.contentView.backgroundColor = InterfaceTheme.Color.background1
            } else {
                me.contentView.backgroundColor = InterfaceTheme.Color.background2
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public enum CursorAction: String, ToolbarActionProtocol, TextViewAction {
    case moveUp
    case moveDown
    case moveLeft
    case moveRight
    
    public var title: String { return self.rawValue }
    
    public var icon: UIImage {
        switch self {
        case .moveUp: return Asset.Assets.up.image
        case .moveDown: return Asset.Assets.down.image
        case .moveLeft: return Asset.Assets.left.image
        case .moveRight: return Asset.Assets.right.image
        }
    }
    
    public func toggle(textView: UITextView, location: Int) {
        switch self {
        case .moveUp: MoveCursorCommand(locaton: location, direction: MoveCursorCommand.Direction.up).toggle(textView: textView)
        case .moveDown: MoveCursorCommand(locaton: location, direction: MoveCursorCommand.Direction.down).toggle(textView: textView)
        case .moveLeft: MoveCursorCommand(locaton: location, direction: MoveCursorCommand.Direction.left).toggle(textView: textView)
        case .moveRight: MoveCursorCommand(locaton: location, direction: MoveCursorCommand.Direction.right).toggle(textView: textView)
        }
    }
}
