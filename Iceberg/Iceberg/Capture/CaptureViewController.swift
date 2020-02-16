//
//  CaptureViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/3/6.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface

public protocol CaptureViewControllerDelegate: class {
    func didSelect(attachmentKind: Attachment.Kind)
    func didCancel()
}

public class CaptureViewController: UIViewController, TransitionProtocol {
    
    public weak var delegate: CaptureViewControllerDelegate?
    
    private let _transition: UIViewControllerTransitioningDelegate = {
        let animator = MoveInAnimtor()
        animator.from = .right
        let transition = FadeBackgroundTransition(animator: animator)
        return transition
    }()
    
    public weak var coordinator: Coordinator?

    public init() {
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .overCurrentContext
        self.transitioningDelegate = self._transition
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public let contentView: UIView = UIView()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(CaptureCell.self, forCellReuseIdentifier: CaptureCell.reuseIdentifier)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Layout.edgeInsets.bottom + 60, right: 0)
        
        tableView.interface({ (me, theme) in
            let me = me as! UITableView
            me.backgroundColor = theme.color.background1
            me.setBorder(position: .left, color: theme.color.background2, width: 0.5)
        })
        return tableView
    }()
    
    private lazy var cancelButton: RoundButton = {
        let button = RoundButton()
        
        button.interface({ (me, theme) in
            let me = me as! RoundButton
            me.setIcon(Asset.Assets.cross.image.fill(color: theme.color.interactive), for: .normal)
            me.setBackgroundColor(theme.color.background2, for: .normal)
        })
        button.setBorder(color: nil)
        button.tapped({ _ in
            self.cancel()
        })
        return button
    }()
    
    public var fromView: UIView?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.contentView)
        
        self.contentView.backgroundColor = InterfaceTheme.Color.background1
        
        self.contentView.addSubview(self.tableView)
        self.contentView.addSubview(self.cancelButton)
        
        self.contentView.sideAnchor(for: [.bottom, .top, .right], to: self.view, edgeInset: 0)
        self.contentView.sizeAnchor(width: 200)
        
        self.tableView.allSidesAnchors(to: self.contentView, edgeInset: 0, considerSafeArea: true)
        
        self.cancelButton.sideAnchor(for: [.right, .bottom], to: self.contentView, edgeInset: 30, considerSafeArea: true)
        self.cancelButton.sizeAnchor(width: 60)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func cancel() {
        self.coordinator?.stop()
        self.delegate?.didCancel()
    }
    
    fileprivate func addActivity(for kind: Attachment.Kind) {
        // add activity
        let activity = Document.createCaptureActivity(kind: kind)
        self.userActivity = activity
        activity.becomeCurrent()
    }
}

extension CaptureViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.view
    }
}

extension CaptureViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let kind = Attachment.Kind.allCases[indexPath.row]
        self.delegate?.didSelect(attachmentKind: kind)
        self.addActivity(for: kind)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Attachment.Kind.allCases.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CaptureCell.reuseIdentifier, for: indexPath) as! CaptureCell
        
        let attachmentKind = Attachment.Kind.allCases[indexPath.row]
        cell.iconView.image = attachmentKind.icon
        cell.titleLabel.text = attachmentKind.name
        
        if let coordinator = self.coordinator {
            cell.memberFunctionIconView.isHidden = coordinator.dependency.purchaseManager.isMember.value || !attachmentKind.isMemberFunction
        }
        
        return cell
    }
}

extension Attachment.Kind {
    var icon: UIImage {
        switch self {
        case .audio: return Asset.Assets.audio.image.fill(color: InterfaceTheme.Color.descriptive)
        case .video: return Asset.Assets.video.image.fill(color: InterfaceTheme.Color.descriptive)
        case .link: return Asset.Assets.link.image.fill(color: InterfaceTheme.Color.descriptive)
        case .location: return Asset.Assets.location.image.fill(color: InterfaceTheme.Color.descriptive)
        case .sketch: return Asset.Assets.sketch.image.fill(color: InterfaceTheme.Color.descriptive)
        case .text: return Asset.Assets.text.image.fill(color: InterfaceTheme.Color.descriptive)
        case .image: return Asset.Assets.imageLibrary.image.fill(color: InterfaceTheme.Color.descriptive)
        }
    }
    
    var name: String {
        switch self {
        case .audio: return L10n.Attachment.Kind.audio
        case .video: return L10n.Attachment.Kind.video
        case .link: return L10n.Attachment.Kind.link
        case .location: return L10n.Attachment.Kind.location
        case .sketch: return L10n.Attachment.Kind.sketch
        case .text: return L10n.Attachment.Kind.text
        case .image: return L10n.Attachment.Kind.image
        }
    }
}

private class CaptureCell: UITableViewCell {
    internal static let reuseIdentifier = "CaptureCell"
    
    internal let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    
    internal let titleLabel: UILabel = {
        let label = UILabel()
        label.interface({ (me, theme) in
            let me = me as! UILabel
            me.font = theme.font.title
            me.textColor = theme.color.interactive
        })
        return label
    }()
    
    internal let memberFunctionIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.interface { (me, theme) in
            me.backgroundColor = InterfaceTheme.Color.background1
        }
        
        self.contentView.addSubview(self.iconView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.memberFunctionIconView)
        
        self.iconView.sideAnchor(for: .left, to: self.contentView, edgeInset:  Layout.innerViewEdgeInsets.left)
        self.iconView.sizeAnchor(width: 18, height: 18)
        self.iconView.centerAnchors(position: .centerY, to: self.contentView)
        self.iconView.rowAnchor(view: self.titleLabel, space: 20)
        self.titleLabel.sideAnchor(for: .top, to: self.contentView, edgeInset: 20)
        self.titleLabel.centerAnchors(position: .centerY, to: self.contentView)

        self.memberFunctionIconView.sideAnchor(for: .right, to: self.contentView, edgeInset: 10)
        self.memberFunctionIconView.centerAnchors(position: .centerY, to: self.contentView)
        
        self.memberFunctionIconView.image = Asset.Assets.proLabel.image
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.backgroundColor = InterfaceTheme.Color.background2
        } else {
            self.backgroundColor = InterfaceTheme.Color.background1
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            self.backgroundColor = InterfaceTheme.Color.background2
        } else {
            self.backgroundColor = InterfaceTheme.Color.background1
        }
    }
}
