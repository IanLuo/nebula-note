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
        let animator = MoveToAnimtor()
        let transition = FadeBackgroundTransition(animator: animator)
        return transition
    }()
    
    public weak var coordinator: Coordinator?

    public init() {
        super.init(nibName: nil, bundle: nil)
        
        if isMacOrPad {
            self.modalPresentationStyle = UIModalPresentationStyle.popover
        } else {
            self.modalPresentationStyle = .custom
            self.transitioningDelegate = self._transition
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public let contentView: UIView = UIView()
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CaptureItemCell.self, forCellWithReuseIdentifier: CaptureItemCell.reuseIdentifier)
        
        collectionView.interface({ (me, theme) in
            let me = me as! UICollectionView
            me.backgroundColor = theme.color.background2
        })
        return collectionView
    }()
    
    private lazy var cancelButton: RoundButton = {
        let button = RoundButton()
        
        button.interface({ (me, theme) in
            let me = me as! RoundButton
            me.setIcon(Asset.SFSymbols.xmark.image.fill(color: theme.color.interactive), for: .normal)
            me.setBackgroundColor(theme.color.background2, for: .normal)
        })
        button.setBorder(color: nil)
        button.tapped({ _ in
            self.cancel()
        })
        return button
    }()
    
    public var fromView: UIView? {
        didSet {
            if isMacOrPad {
                self.popoverPresentationController?.sourceView = fromView
                
                if let fromView = fromView {
                    self.popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: fromView.frame.midX, y: fromView.frame.midY), size: .zero)
                }
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.contentView)
        
        self.view.backgroundColor = InterfaceTheme.Color.background2
        self.contentView.centerAnchors(position: [.centerX, .centerY], to: self.view)
        self.collectionView.sizeAnchor(width: 300, height: 400)
        
        self.contentView.roundConer(radius: Layout.cornerRadius)
        
        self.contentView.addSubview(self.collectionView)
        self.contentView.addSubview(self.cancelButton)
        
        self.collectionView.sideAnchor(for: [.top, .left, .right], to: self.contentView, edgeInset: 0)
        self.collectionView.columnAnchor(view: self.cancelButton, space: 10, alignment: .centerX)
        self.cancelButton.sideAnchor(for: .bottom, to: self.contentView, edgeInset: 10, considerSafeArea: true)
        self.cancelButton.centerAnchors(position: .centerX, to: self.contentView)
        self.cancelButton.sizeAnchor(width: 44)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        if isMacOrPad {
            self.cancelButton.isHidden = true
            if self.fromView == nil {
                self.popoverPresentationController?.sourceView = self.view
                self.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2, width: 0, height: 0)
            }
            let size = self.view.systemLayoutSizeFitting(CGSize(width: self.view.bounds.width, height: 0))
            self.preferredContentSize = CGSize(width: 350, height: size.height)
        }
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

extension CaptureViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let kind = Attachment.Kind.allCases[indexPath.row]
        self.delegate?.didSelect(attachmentKind: kind)
        self.addActivity(for: kind)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Attachment.Kind.allCases.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CaptureItemCell.reuseIdentifier, for: indexPath) as! CaptureItemCell
        
        let attachmentKind = Attachment.Kind.allCases[indexPath.row]
        cell.iconView.image = attachmentKind.icon
        cell.titleLabel.text = attachmentKind.name
        
        if let coordinator = self.coordinator {
            cell.memberFunctionIconView.isHidden = coordinator.dependency.purchaseManager.isMember.value || !attachmentKind.isMemberFunction
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 3
        return CGSize(width: width, height: width * 1.2)
    }
}

extension Attachment.Kind {
    var icon: UIImage {
        switch self {
        case .audio: return Asset.SFSymbols.mic.image.fill(color: InterfaceTheme.Color.descriptive)
        case .video: return Asset.SFSymbols.video.image.fill(color: InterfaceTheme.Color.descriptive)
        case .link: return Asset.SFSymbols.link.image.fill(color: InterfaceTheme.Color.descriptive)
        case .location: return Asset.SFSymbols.location.image.fill(color: InterfaceTheme.Color.descriptive)
        case .sketch: return Asset.SFSymbols.scribble.image.fill(color: InterfaceTheme.Color.descriptive)
        case .text: return Asset.SFSymbols.docPlaintext.image.fill(color: InterfaceTheme.Color.descriptive)
        case .image: return Asset.SFSymbols.photoOnRectangle.image.fill(color: InterfaceTheme.Color.descriptive)
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

private class CaptureItemCell: UICollectionViewCell {
    internal static let reuseIdentifier = "CaptureItemCell"
    
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.enableHover(on: self.contentView, hoverColor: InterfaceTheme.Color.background3)
        
        self.interface { (me, theme) in
            me.backgroundColor = InterfaceTheme.Color.background2
        }
        
        self.contentView.addSubview(self.iconView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.memberFunctionIconView)
        
        self.iconView.sideAnchor(for: .top, to: self.contentView, edgeInset:  Layout.innerViewEdgeInsets.top)
        self.iconView.sizeAnchor(width: 30, height: 30)
        self.iconView.centerAnchors(position: .centerX, to: self.contentView)
        self.iconView.columnAnchor(view: self.titleLabel, space: 10, alignment: .centerX)
        self.titleLabel.sideAnchor(for: .bottom, to: self.contentView, edgeInset: 20)
        self.titleLabel.centerAnchors(position: .centerX, to: self.contentView)

        self.memberFunctionIconView.sideAnchor(for: .right, to: self.contentView, edgeInset: 10)
        self.memberFunctionIconView.centerAnchors(position: .centerY, to: self.contentView)
        
        self.memberFunctionIconView.image = Asset.Assets.proLabel.image
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.backgroundColor = InterfaceTheme.Color.background2
            } else {
                self.backgroundColor = InterfaceTheme.Color.background1
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.backgroundColor = InterfaceTheme.Color.background2
            } else {
                self.backgroundColor = InterfaceTheme.Color.background1
            }
        }
    }
    
}
