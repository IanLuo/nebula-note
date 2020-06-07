//
//  AttachmentSketchViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Drawsana
import Core
import Interface

public class AttachmentSketchViewController: UIViewController, AttachmentViewControllerProtocol, AttachmentViewModelDelegate {
    public weak var attachmentDelegate: AttachmentViewControllerDelegate?
    
    public var viewModel: AttachmentViewModel!
    
    public var contentView: UIView = UIView()
    
    public var fromView: UIView?
    
    private lazy var drawingView: DrawsanaView = {
        let drawingView = DrawsanaView()
        drawingView.delegate = self
        drawingView.operationStack.delegate = self
        drawingView.backgroundColor = .white
        drawingView.setBorder(position: [.left, .right, .top, .bottom], color: InterfaceTheme.Color.background3, width: 1)
        return drawingView
    }()
    
    private let undoButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.Assets.undo.image.fill(color: InterfaceTheme.Color.interactive), for: .normal)
        button.titleLabel?.font = InterfaceTheme.Font.title
        button.setTitleColor(InterfaceTheme.Color.interactive, for: .normal)
        button.addTarget(self, action: #selector(undo), for: .touchUpInside)
        return button
    }()
    
    private let redoButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.Assets.redo.image.fill(color: InterfaceTheme.Color.interactive), for: .normal)
        button.titleLabel?.font = InterfaceTheme.Font.title
        button.setTitleColor(InterfaceTheme.Color.interactive, for: .normal)
        button.addTarget(self, action: #selector(redo), for: .touchUpInside)
        return button
    }()
    
    private lazy var exitButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        button.setImage(Asset.Assets.down.image.fill(color: InterfaceTheme.Color.interactive), for: .normal)
        return button
    }()
    
    private let controlsView: UIView = {
        let view = UIView()
         view.setBorder(position: [.top, .bottom, .centerV], color: InterfaceTheme.Color.background3, width: 1)
        return view
    }()
    
    private lazy var pickColorButton: RoundButton = {
        let pickColorButton = RoundButton(style: RoundButton.Style.horizontal)
        pickColorButton.tapped { button in
            self.showColorPicker(button: button)
        }
        return pickColorButton
    }()
    
    private lazy var pickBrushButton: RoundButton = {
        let pickBrushButton = RoundButton(style: RoundButton.Style.horizontal)
        pickBrushButton.setBorder(color: nil)
        pickBrushButton.tapped { button in
            self.showBrushPicker(button: button)
        }
        return pickBrushButton
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.spotlight, size: CGSize.singlePoint), for: .normal)
        button.setTitle(L10n.General.Button.Title.save, for: .normal)
        button.addTarget(self, action: #selector(save), for: .touchUpInside)
        return button
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = InterfaceTheme.Color.background1
        self.setupUI()
        
        self.drawingView.set(tool: PenTool())
        self.setColor(index: 0)
        self.setBrush(self.brushWidth[9])
        
        self.viewModel.delegate = self
    }
    
    @objc private func cancel() {
        self.viewModel.coordinator?.stop()
        self.attachmentDelegate?.didCancelAttachment()
    }
    
    @objc private func undo() {
        if self.drawingView.operationStack.canUndo {
            self.drawingView.operationStack.undo()
        }
    }
    
    @objc private func redo() {
        if self.drawingView.operationStack.canRedo {
            self.drawingView.operationStack.redo()
        }
    }
    
    @objc private func save() {
        if let image = self.drawingView.render(over: UIImage.create(with: self.drawingView.backgroundColor!, size: self.drawingView.bounds.size)) {
            let url = URL.file(directory: URL.sketchCacheURL, name: UUID().uuidString, extension: "png")
            url.deletingLastPathComponent().createDirectoryIfNeeded { error in
                if let error = error {
                    log.error(error)
                } else {
                    do {
                        try image.pngData()?.write(to: url)
                        self.viewModel.save(content: url.path, kind: .sketch, description: "sketch")
                    } catch {
                        log.error(error)
                    }
                }
            }
        }
    }
    
    private let colors: [(String, UIColor)] = [("dard gray", .darkGray), ("black", .black), ("red", .red), ("blue", .blue), ("cyan", .cyan), ("orange", .orange), ("brown", .brown), ("gray", .gray), ("yellow", .yellow)]
    private let brushWidth: [CGFloat] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 30, 40]
    
    private func setupUI() {
        self.view.addSubview(self.contentView)
        self.contentView.allSidesAnchors(to: self.view, edgeInset: 0)
        
        self.contentView.addSubview(self.exitButton)
        self.exitButton.sideAnchor(for: [.top, .right], to: self.contentView, edgeInsets: .init(top: 10, left: 0, bottom: 0, right: -30), considerSafeArea: true)
        self.exitButton.sizeAnchor(width: 44, height: 44)
        
        self.contentView.addSubview(self.undoButton)
        self.contentView.addSubview(self.redoButton)

        self.undoButton.sideAnchor(for: [.left, .top], to: self.contentView, edgeInsets: .init(top: 10, left: 30, bottom: 0, right: 0), considerSafeArea: true)
        self.undoButton.rowAnchor(view: self.redoButton, space: 20)
        self.undoButton.sizeAnchor(width: 44, height: 44)
        self.redoButton.sizeAnchor(width: 44, height: 44)
        self.redoButton.sideAnchor(for: .top, to: self.contentView, edgeInset: 10, considerSafeArea: true)
        
        self.contentView.addSubview(self.drawingView)
        self.drawingView.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: 30)
        self.drawingView.ratioAnchor(1)

        self.exitButton.columnAnchor(view: self.drawingView, space: 10, alignment: .traling)
        
        self.contentView.addSubview(self.controlsView)

        self.drawingView.columnAnchor(view: self.controlsView, space: 10)
        self.controlsView.addSubview(self.pickColorButton)
        self.controlsView.addSubview(self.pickBrushButton)
        
        self.controlsView.sideAnchor(for: [.left, .right], to: self.view, edgeInset: 0)
        self.controlsView.sizeAnchor(height: 80)
        
        self.pickColorButton.sideAnchor(for: [.left, .top, .bottom], to: self.controlsView, edgeInsets: .init(top: 0, left: 20, bottom: 0, right: 0))
        self.pickBrushButton.sideAnchor(for: [.right, .top, .bottom], to: self.controlsView, edgeInsets: .init(top: 0, left: 20, bottom: 0, right: 0))
        self.pickColorButton.rowAnchor(view: self.pickBrushButton, widthRatio: 1)

        self.contentView.addSubview(self.saveButton)
        
        self.saveButton.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInset: 0, considerSafeArea: true)
        self.saveButton.sizeAnchor(height: 60)
    }
    
    private func setColor(index: Int) {
        self.pickColorButton.setBackgroundColor(self.colors[index].1, for: .normal)
        self.pickColorButton.title = self.colors[index].0
        self.drawingView.userSettings.strokeColor = self.colors[index].1
    }
    
    private func setBrush(_ width: CGFloat) {
        self.pickBrushButton.title = "\(width)"
        self.pickBrushButton.setIcon(UIImage.create(with: InterfaceTheme.Color.interactive, size: CGSize(width: width, height: width), style: .circle), for: .normal)
        self.drawingView.userSettings.strokeWidth = width
    }
    
    private func showColorPicker(button: RoundButton) {
        let selector = SelectorViewController()
        selector.delegate = self
        selector.name = L10n.Document.Edit.Sketch.color
        selector.title = L10n.Document.Edit.Sketch.pickColor
        self.colors.forEach {
            selector.addItem(icon: UIImage.create(with: $0.1, size: CGSize(width:30, height: 30), style: .circle),
                             title: "\($0.0)")
        }
        
        selector.currentTitle = button.title
        
        selector.fromView = button
        
        self.present(selector, animated: true, completion: nil)
    }
    
    private func showBrushPicker(button: RoundButton) {
        let selector = SelectorViewController()
        selector.delegate = self
        selector.name = L10n.Document.Edit.Sketch.brush
        selector.title = L10n.Document.Edit.Sketch.pickBrushSize
        self.brushWidth.forEach {
            selector.addItem(icon: UIImage.create(with: InterfaceTheme.Color.interactive, size: CGSize(width: $0, height: $0), style: .circle),
                             title: "\($0)")
        }
        
        selector.currentTitle = button.title
        
        selector.fromView = button
        
        self.present(selector, animated: true, completion: nil)
    }
    
    public func didSaveAttachment(key: String) {
        self.attachmentDelegate?.didSaveAttachment(key: key)
        self.viewModel.coordinator?.stop()
    }
    
    public func didFailToSave(error: Error, content: String, kind: Attachment.Kind, descritpion: String) {
        log.error(error)
    }
}

extension AttachmentSketchViewController: SelectorViewControllerDelegate {
    public func SelectorDidCancel(viewController: SelectorViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    public func SelectorDidSelect(index: Int, viewController: SelectorViewController) {
        viewController.dismiss(animated: true) {
            if viewController.name == L10n.Document.Edit.Sketch.brush {
                self.setBrush(self.brushWidth[index])
            }
            
            else if viewController.name == L10n.Document.Edit.Sketch.color {
                self.setColor(index: index)
            }
        }
    }
}

extension AttachmentSketchViewController: DrawsanaViewDelegate {
    public func drawsanaView(_ drawsanaView: DrawsanaView, didSwitchTo tool: DrawingTool) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didStartDragWith tool: DrawingTool) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didEndDragWith tool: DrawingTool) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didChangeStrokeColor strokeColor: UIColor?) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFillColor fillColor: UIColor?) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didChangeStrokeWidth strokeWidth: CGFloat) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFontName fontName: String) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFontSize fontSize: CGFloat) {
        
    }
}

extension AttachmentSketchViewController: DrawingOperationStackDelegate {
    public func drawingOperationStackDidUndo(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
        
    }
    
    public func drawingOperationStackDidRedo(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
        
    }
    
    public func drawingOperationStackDidApply(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
        
    }
}
