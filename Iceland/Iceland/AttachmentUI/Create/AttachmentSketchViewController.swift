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
import Business
import Storage

public class AttachmentSketchViewController: AttachmentViewController, AttachmentViewModelDelegate {
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
        button.setTitle("↶", for: .normal)
        button.titleLabel?.font = InterfaceTheme.Font.title
        button.setTitleColor(InterfaceTheme.Color.interactive, for: .normal)
        button.addTarget(self, action: #selector(undo), for: .touchUpInside)
        return button
    }()
    
    private let redoButton: UIButton = {
        let button = UIButton()
        button.setTitle("↷", for: .normal)
        button.titleLabel?.font = InterfaceTheme.Font.title
        button.setTitleColor(InterfaceTheme.Color.interactive, for: .normal)
        button.addTarget(self, action: #selector(redo), for: .touchUpInside)
        return button
    }()
    
    private lazy var exitButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        button.setTitle("✕", for: .normal)
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
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.backgroundHighlight, size: CGSize.singlePoint), for: .normal)
        button.setTitle("save".localizable, for: .normal)
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
        self.viewModel.dependency?.stop()
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
            let url = File(File.Folder.temp("sketch"), fileName: UUID().uuidString, createFolderIfNeeded: true).url.appendingPathExtension("png")
            do {
                try image.pngData()?.write(to: url)
                self.viewModel.save(content: url.path, type: Attachment.AttachmentType.sketch, description: "sketch")
            } catch {
                log.error(error)
            }
        }
    }
    
    private let colors: [(String, UIColor)] = [("dard gray", .darkGray), ("black", .black), ("red", .red), ("blue", .blue), ("cyan", .cyan), ("orange", .orange), ("brown", .brown), ("gray", .gray), ("yellow", .yellow)]
    private let brushWidth: [CGFloat] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 30, 40]
    
    private func setupUI() {
        self.view.addSubview(self.exitButton)
        self.exitButton.sideAnchor(for: [.top, .right], to: self.view, edgeInsets: .init(top: 10, left: 0, bottom: 0, right: -30))
        self.exitButton.sizeAnchor(width: 44, height: 44)
        
        self.view.addSubview(self.undoButton)
        self.view.addSubview(self.redoButton)

        self.undoButton.sideAnchor(for: [.left, .top], to: self.view, edgeInsets: .init(top: 10, left: 30, bottom: 0, right: 0))
        self.undoButton.rowAnchor(view: self.redoButton, space: 20)
        self.undoButton.sizeAnchor(width: 44, height: 44)
        self.redoButton.sizeAnchor(width: 44, height: 44)
        self.redoButton.sideAnchor(for: .top, to: self.view, edgeInset: 10)
        
        self.view.addSubview(self.drawingView)
        self.drawingView.sideAnchor(for: [.left, .right], to: self.view, edgeInset: 30)
        self.drawingView.ratioAnchor(1)

        self.exitButton.columnAnchor(view: self.drawingView, space: 10)
        
        self.view.addSubview(self.controlsView)

        self.drawingView.columnAnchor(view: self.controlsView, space: 10)
        self.controlsView.addSubview(self.pickColorButton)
        self.controlsView.addSubview(self.pickBrushButton)
        
        self.controlsView.sideAnchor(for: [.left, .right], to: self.view, edgeInset: 0)
        self.controlsView.sizeAnchor(height: 80)
        
        self.pickColorButton.sideAnchor(for: [.left, .top, .bottom], to: self.controlsView, edgeInsets: .init(top: 0, left: 20, bottom: 0, right: 0))
        self.pickBrushButton.sideAnchor(for: [.right, .top, .bottom], to: self.controlsView, edgeInsets: .init(top: 0, left: 20, bottom: 0, right: 0))
        self.pickColorButton.rowAnchor(view: self.pickBrushButton, widthRatio: 1)

        self.view.addSubview(self.saveButton)
        
        self.saveButton.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 0)
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
        selector.name = "color"
        self.colors.forEach {
            selector.addItem(icon: UIImage.create(with: $0.1, size: CGSize(width:30, height: 30), style: .circle),
                             title: "\($0.0)")
        }
        
        selector.currentTitle = button.title
        selector.show(from: button, on: self)
    }
    
    private func showBrushPicker(button: RoundButton) {
        let selector = SelectorViewController()
        selector.rowHeight = 80
        selector.delegate = self
        selector.name = "brush"
        self.brushWidth.forEach {
            selector.addItem(icon: UIImage.create(with: InterfaceTheme.Color.interactive, size: CGSize(width: $0, height: $0), style: .circle),
                             title: "\($0)")
        }
        
        selector.currentTitle = button.title
        selector.show(from: button, on: self)
    }
    
    public func didSaveAttachment(key: String) {
        self.delegate?.didSaveAttachment(key: key)
        self.viewModel.dependency?.stop()
    }
    
    public func didFailToSave(error: Error, content: String, type: Attachment.AttachmentType, descritpion: String) {
        log.error(error)
    }
}

extension AttachmentSketchViewController: SelectorViewControllerDelegate {
    public func SelectorDidCancel(viewController: SelectorViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    public func SelectorDidSelect(index: Int, viewController: SelectorViewController) {
        viewController.dismiss(animated: true) {
            if viewController.name == "brush" {
                self.setBrush(self.brushWidth[index])
            }
            
            else if viewController.name == "color" {
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
