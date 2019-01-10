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

public class AttachmentSketchViewController: AttachmentViewController {
    private lazy var drawingView: DrawsanaView = {
        let drawingView = DrawsanaView()
        drawingView.delegate = self
        drawingView.operationStack.delegate = self
        return drawingView
    }()
    
    private let undoButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    private let redoButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    private let exitButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
    }
    
    private func setupUI() {
        
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
