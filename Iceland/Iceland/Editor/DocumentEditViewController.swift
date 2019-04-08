//
//  Page.swift
//  Iceland
//
//  Created by ian luo on 2018/11/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public protocol DocumentEditViewControllerDelegate: class {
    func didTapLink(url: URL, title: String, point: CGPoint)
}

public class DocumentEditViewController: UIViewController {
    public let textView: OutlineTextView
    internal let viewModel: DocumentEditViewModel
    
    public weak var delegate: DocumentEditViewControllerDelegate?
    
    public init(viewModel: DocumentEditViewModel) {
        self.viewModel = viewModel
        self.textView = OutlineTextView(frame: .zero,
                                        textContainer: viewModel.container)
        self.textView.contentInset = UIEdgeInsets(top: 160, left: 30, bottom: 80, right: 30)

        super.init(nibName: nil, bundle: nil)
        
        self.textView.outlineDelegate = self
        self.textView.delegate = self
        viewModel.delegate = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private let toolBar: UIView = UIView()
    
    private var closeButton: UIButton!
    private var searchButton: UIButton!
    
    private let _toolbar = InputToolbar(mode: .paragraph)
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.frame = self.view.bounds
        
        self.view.addSubview(self.textView)
        self.view.addSubview(self.toolBar)
        
        let image = self.viewModel.coordinator?.isModal == true ? Asset.Assets.down.image : Asset.Assets.left.image
        self.closeButton = self.createActionButton(icon: image.withRenderingMode(.alwaysTemplate))
        self.searchButton = self.createActionButton(icon: Asset.Assets.zoom.image.withRenderingMode(.alwaysTemplate))
        
        self.closeButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        self.searchButton.addTarget(self, action: #selector(search), for: .touchUpInside)
        
        self.toolBar.addSubview(closeButton)
        self.toolBar.addSubview(searchButton)
        
        self._toolbar.frame = CGRect(origin: .zero, size: .init(width: self.view.bounds.width, height: 44))
        self._toolbar.delegate = self
        self.textView.inputAccessoryView = self._toolbar
        
        self._toolbar.mode = .paragraph
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.toolBar.size(width: self.view.bounds.width, height: 80)
            .align(to: self.view, direction: AlignmentDirection.top, position: AlignmentPosition.middle, inset: 0)

        self.closeButton.size(width: 40, height: 40)
            .alignToSuperview(direction: AlignmentDirection.right, position: AlignmentPosition.middle, inset: 30)
        
        self.searchButton.size(width: 40, height: 40)
            .alignToSuperview(direction: AlignmentDirection.left, position: AlignmentPosition.middle, inset: 30)
    }
    
    @objc private func cancel() {
        self.textView.endEditing(true)
        self.viewModel.save {}
        self.viewModel.coordinator?.stop()
    }
    
    @objc private func search() {
        self.viewModel.coordinator?.search()
    }
    
    private func attachmentPicker() {
        
    }
    
    private func createActionButton(icon: UIImage?) -> UIButton {
        let button = UIButton()
        button.setImage(icon, for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background2, size: .singlePoint), for: .normal)
        button.tintColor = InterfaceTheme.Color.interactive
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        return button
    }
    
    private func _showAttachmentSelections() {
        let performAddAttachmentAction: (Int, String, String) -> Void = {
            self.viewModel.performAction(EditAction.addAttachment($0, $1, $2),
                                         undoManager: self.textView.undoManager!)
        }
        
        let actionViewController = ActionsViewController()
        actionViewController.addAction(icon: Asset.Assets.imageLibrary.image, title: "images".localizable) { controller in
            controller.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showAttachmentPicker(kind: Attachment.Kind.image, complete: { [unowned self] attachmentId in
                    performAddAttachmentAction(self.textView.selectedRange.location, attachmentId, Attachment.Kind.image.rawValue)
                    }, cancel: {
                        
                })
            })
        }
        
        actionViewController.addAction(icon: Asset.Assets.add.image, title: "location".localizable) { controller in
            controller.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showAttachmentPicker(kind: .location, complete: { [unowned self] attachmentId in
                    performAddAttachmentAction(self.textView.selectedRange.location, attachmentId, Attachment.Kind.location.rawValue)
                }, cancel: {
                        
                })
            })
        }
        
        actionViewController.addAction(icon: Asset.Assets.add.image, title: "audio".localizable) { controller in
            controller.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showAttachmentPicker(kind: .audio, complete: { [unowned self] attachmentId in
                    performAddAttachmentAction(self.textView.selectedRange.location, attachmentId, Attachment.Kind.audio.rawValue)
                }, cancel: {
                        
                })
            })
        }
        
        actionViewController.addAction(icon: Asset.Assets.add.image, title: "video".localizable) { controller in
            controller.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showAttachmentPicker(kind: .video, complete: { [unowned self] attachmentId in
                    performAddAttachmentAction(self.textView.selectedRange.location, attachmentId, Attachment.Kind.video.rawValue)
                }, cancel: {
                        
                })
            })
        }
        
        actionViewController.addAction(icon: Asset.Assets.add.image, title: "sketch".localizable) { controller in
            controller.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showAttachmentPicker(kind: .sketch, complete: { [unowned self] attachmentId in
                    performAddAttachmentAction(self.textView.selectedRange.location, attachmentId, Attachment.Kind.sketch.rawValue)
                }, cancel: {
                        
                })
            })
        }
        
        actionViewController.addAction(icon: Asset.Assets.add.image, title: "link".localizable) { controller in
            controller.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showAttachmentPicker(kind: .link, complete: { [unowned self] attachmentId in
                    performAddAttachmentAction(self.textView.selectedRange.location, attachmentId, Attachment.Kind.link.rawValue)
                }, cancel: {
                        
                })
            })
        }
        
        actionViewController.addAction(icon: Asset.Assets.add.image, title: "captured".localizable) { controller in
            controller.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showCapturedList()
            })
        }
    }
}

extension DocumentEditViewController: OutlineTextViewDelegate {
    public func didTapOnLink(textView: UITextView, characterIndex: Int, linkStructure: [String : NSRange], point: CGPoint) {

    }
    
    public func didTapOnLevel(textView: UITextView, chracterIndex: Int, heading: [String : NSRange], point: CGPoint) {
        self.viewModel.performAction(.toggleFoldStatus(chracterIndex),
                                     undoManager: self.textView.undoManager!)
    }
    
    public func didTapOnCheckbox(textView: UITextView, characterIndex: Int, checkbox: [String : NSRange], point: CGPoint) {
        self.viewModel.performAction(.toggleCheckboxStatus(checkbox["status"]!),
                                     undoManager: self.textView.undoManager!)
    }
}

extension DocumentEditViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        self.viewModel.didUpdate()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        self.viewModel.cursorLocationChanged(textView.selectedRange.location)
    }
}

extension DocumentEditViewController: DocumentEditViewModelDelegate {
    public func didEnterTokens(_ tokens: [Token]) {
        for token in tokens {
            if token is HeadingToken {
                if self._toolbar.mode != .heading {
                    self._toolbar.mode = .heading
                }
                return
            } else {
                if self._toolbar.mode != .paragraph {
                    self._toolbar.mode = .paragraph
                }
                return
            }
        }
        
        if self._toolbar.mode != .paragraph {
            self._toolbar.mode = .paragraph
        }
    }
    
    public func didReadyToEdit() {
        self.viewModel.save {}
        self.textView.selectedRange = NSRange(location: self.viewModel.onLoadingLocation,
                                              length: 0)
        self.textView.scrollRangeToVisible(self.textView.selectedRange)
    }
    
    public func documentStatesChange(state: UIDocument.State) {
        
    }
    
    public func showLink(url: URL) {
        
    }
    
    public func updateHeadingInfo(heading: HeadingToken?) {
        
    }
}
