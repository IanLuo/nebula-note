//
//  CaptureViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface

public protocol AttachmentViewControllerDelegate: class {
    func didSaveAttachment(key: String)
    func didCancelAttachment()
}

public protocol AttachmentViewControllerProtocol: TransitionViewController, AttachmentViewModelDelegate {
    var attachmentDelegate: AttachmentViewControllerDelegate? { get set }
    var viewModel: AttachmentViewModel! { get set }
}

//open class AttachmentViewController: TransitionViewController {
//    open var container: UIView = UIView()
//
//    public var contentView: UIView {
//        return self.container
//    }
//
//    public var fromView: UIView? {
//        didSet {
//            if isMacOrPad {
//                self.popoverPresentationController?.sourceView = fromView
//
//                if let fromView = fromView {
//                    self.popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: fromView.frame.midX, y: fromView.frame.midY), size: .zero)
//                }
//            }
//        }
//    }
//
//    private let transitionDelegate = FadeBackgroundTransition(animator: MoveToAnimtor())
//
//    public let viewModel: AttachmentViewModel
//    public weak var delegate: AttachmentViewControllerDelegate?
//
//    private let _transition: UIViewControllerTransitioningDelegate
//
//    public init(viewModel: AttachmentViewModel) {
//        self.viewModel = viewModel
//        self._transition = FadeBackgroundTransition(animator: MoveInAnimtor())
//
//        super.init(nibName: nil, bundle: nil)
//
//        self.view.addSubview(self.container)
//
//        self.container.allSidesAnchors(to: self.view, edgeInset: 0)
//
//        if isMacOrPad {
//            self.modalPresentationStyle = UIModalPresentationStyle.popover
//        } else {
//            self.modalPresentationStyle = .custom
//            self.transitioningDelegate = self.transitionDelegate
//        }
//    }
//
//    open override func viewDidLoad() {
//        if isMacOrPad {
//            if self.fromView == nil {
//                self.popoverPresentationController?.sourceView = self.view
//                self.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2, width: 0, height: 0)
//            }
//        }
//    }
//
//    required public init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
